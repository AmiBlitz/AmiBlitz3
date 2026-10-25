#!/usr/bin/env python3
"""Find assembler code that keeps register values across Basic statements.

Usage: asm_crossreg.py <tokens.txt> [--list] <file-or-dir> ...

Walks the statements of every source (tokenizer from asm_usage.py) and
reports each place where

    assembler writes register R
    ... at least one Basic statement (or macro call) follows ...
    assembler reads R before writing it again

i.e. code that relies on R surviving compiled Basic code. a5 and a7 are
ignored everywhere, a4 inside procedures (base of the local variables).

The analysis is linear and approximate: the state is reset at procedure and
macro boundaries, global labels and unconditional exits (RTS/RTE/JMP/BRA);
subroutine calls (JSR/BSR) are not followed. GetReg/PutReg count as
assembler (they are register transparent in the old compiler).
"""
import importlib.util
import os
import re
import sys
from collections import Counter, defaultdict

_here = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("asm_usage", os.path.join(_here, "asm_usage.py"))
au = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(au)

REG = re.compile(r"(?<![\w@])([da][0-7]|sp)(?![\w@])", re.I)
RMW = {"ADD", "ADDI", "ADDQ", "ADDA", "ADDX", "SUB", "SUBI", "SUBQ", "SUBA", "SUBX", "AND", "ANDI",
       "OR", "ORI", "EOR", "EORI", "LSL", "LSR", "ASL", "ASR", "ROL", "ROR", "ROXL", "ROXR",
       "MULS", "MULU", "DIVS", "DIVU", "BSET", "BCLR", "BCHG", "ABCD", "SBCD", "NEG", "NEGX",
       "NOT", "EXT", "SWAP", "NBCD"}
READ_ONLY = {"CMP", "CMPI", "CMPA", "CMPM", "TST", "BTST", "PEA", "JSR", "JMP", "CHK", "PUTREG"}
WRITE_ONLY = {"MOVE", "MOVEA", "MOVEQ", "LEA", "CLR", "GETREG", "ST", "SF", "SEQ", "SNE", "SCC", "SCS",
              "SGE", "SGT", "SHI", "SLE", "SLS", "SLT", "SMI", "SPL", "SVC", "SVS"}
EXITS = {"RTS", "RTE", "RTR", "JMP", "BRA"}


def regs_in(text):
    out = set()
    for r in REG.findall(text):
        r = r.lower()
        out.add("a7" if r == "sp" else r)
    return out


def reglist(text):
    out = set()
    for part in text.split("/"):
        m = re.fullmatch(r"\s*([da])([0-7])\s*(?:-\s*([da])([0-7]))?\s*", part, re.I)
        if not m:
            return None
        if m.group(3):
            lo = (m.group(1).lower() == "a") * 8 + int(m.group(2))
            hi = (m.group(3).lower() == "a") * 8 + int(m.group(4))
            for i in range(lo, hi + 1):
                out.add(("d%d" if i < 8 else "a%d") % (i % 8))
        else:
            out.add(m.group(1).lower() + m.group(2))
    return out


def split_ops(ops):
    return [o.strip() for o in re.split(r",(?![^(]*\))", ops) if o.strip()]


def access(mn, ops):
    """(read, written) register sets of one instruction (heuristic)."""
    mn = mn.upper()
    parts = split_ops(ops)
    read, written = set(), set()
    if mn == "MOVEM" and len(parts) == 2:
        if reglist(parts[0]) is not None:
            read |= reglist(parts[0])
            read |= regs_in(parts[1])
        elif reglist(parts[1]) is not None:
            written |= reglist(parts[1])
            read |= regs_in(parts[0])
        return read, written
    if mn == "EXG":
        r = regs_in(ops)
        return r, r
    if mn.startswith("DB") and parts:
        r = regs_in(parts[0])
        return r, r
    if not parts:
        return read, written
    src, dst = (parts[:-1], parts[-1]) if len(parts) > 1 else ([], parts[0])
    for s in src:
        read |= regs_in(s)
    direct = re.fullmatch(r"([da][0-7]|sp)", dst, re.I)
    if direct:
        r = regs_in(dst)
        if mn in READ_ONLY:
            read |= r
        elif mn in WRITE_ONLY:
            written |= r
        elif mn in RMW or len(parts) > 1:
            read |= r
            written |= r
        else:
            read |= r
    else:
        read |= regs_in(dst)                         # address registers in memory operands
        if re.search(r"\)\+|-\(", dst):
            written |= regs_in(dst)
    return read, written


def analyse(path, table, names, kw, asm_words, bridge_words, directive_words, ignore_libs):
    data = open(path, "rb").read()
    body, offset = au.skip_header(data)
    lines = au.tokenize(body, table)
    findings = []
    in_macro = 0
    in_proc = False
    written = {}          # reg -> line written
    crossed = {}          # reg -> (line written, kind, line of crossing statement, text)

    def reset():
        written.clear()
        crossed.clear()

    for ln, line in enumerate(lines, 1 + offset):
        for st in au.statements(line):
            st = au.strip(st)
            if not st:
                continue
            first = st[0]
            txt = au.text(st, names)
            if first == kw["Macro"]:
                in_macro += 1
                reset()
                continue
            if first == kw["End"]:
                rest = au.strip(st[1:])
                if rest and rest[0] == kw["Macro"]:
                    in_macro = max(0, in_macro - 1)
                    reset()
                    continue
                if rest and rest[0] in (kw["Statement"], kw["Function"]):
                    in_proc = False
                    reset()
                    continue
            if first in (kw["Statement"], kw["Function"]):
                rest = au.strip(st[1:])
                if not (rest and rest[0] == kw["Return"]):
                    in_proc = True
                    reset()
                    continue
            # labels in front of an instruction
            body_ = st
            k = 1 if body_[0] in (39, 46) else 0
            while k < len(body_) and body_[k] < 0x8000 and body_[k] != 32:
                k += 1
            rest = au.strip(body_[k:])
            if body_[0] < 0x8000 and rest and rest[0] in asm_words:
                if body_[0] != 39:
                    reset()                          # global label
                body_ = rest
            elif all(x < 0x8000 for x in body_) and re.fullmatch(r"[.]?[A-Za-z_][\w.]*:?", txt):
                reset()                              # global label alone
                continue
            elif body_[0] == 39 and k == len(body_):
                continue                             # local label alone
            head = body_[0]
            btxt = au.text(body_, names)
            if btxt.startswith("!") or head in directive_words or btxt.startswith("#"):
                kind = "macro" if btxt.startswith("!") else None
                if kind:
                    for r, w in written.items():
                        crossed.setdefault(r, (w, "macro", ln, btxt[:50]))
                continue
            if head in asm_words or head in bridge_words:
                mn = names[head]
                ops = au.text(body_[1:], names)
                ops = re.sub(r"^\.[bwlsdq]\b", "", ops).strip()
                if mn in ("GetReg", "GetD0", "GetRegD0"):
                    reg = (regs_in(ops.split(",")[0]) if mn == "GetReg" else {"d0"})
                    rd, wr = set(), reg
                elif mn in ("PutReg", "PutD0", "PutRegD0"):
                    reg = (regs_in(ops.split(",")[0]) if mn == "PutReg" else {"d0"})
                    rd, wr = reg, set()
                else:
                    rd, wr = access(mn, ops)
                ignore = {"a5", "a7"} | ({"a4"} if in_proc else set())
                for r in sorted(rd - ignore):
                    if r in crossed:
                        w, kind, cl, ctext = crossed.pop(r)
                        findings.append((r, kind, w, cl, ln, ctext, "%s %s" % (mn, ops)))
                for r in wr - ignore:
                    written[r] = ln
                    crossed.pop(r, None)
                if mn.upper() in EXITS:
                    reset()
                continue
            # Basic statement
            for r, w in written.items():
                crossed.setdefault(r, (w, "basic", ln, btxt[:50]))
    return findings


def main(argv):
    listing = "--list" in argv
    argv = [a for a in argv if a != "--list"]
    table, names = {}, {}
    for line in open(argv[0], encoding="latin-1"):
        m = re.match(r"TOKEN (\d+)/(\d+) (\S+)", line)
        if m:
            word = 0x8000 | int(m.group(1)) << 7 | int(m.group(2))
            key = m.group(3).encode("latin-1")
            if key not in table:
                table[key] = word
                names[word] = m.group(3)
    kw = {k: table[k.encode()] for k in ("Macro", "End", "Statement", "Function", "Return")}
    asm_words = {w for w in names if 0x803C <= w < 0x80B3 or (w >> 7) & 0xFF in (217, 218)}
    asm_words |= {table[k] for k in (b"Dc", b"Ds", b"Dcb", b"Even", b"Even4", b"AsmExit")}
    bridge_words = {table[k] for k in (b"GetReg", b"PutReg", b"GetD0", b"PutD0", b"GetRegD0", b"PutRegD0")}
    directive_words = {table[k] for k in (b"CNIF", b"CSIF", b"CELSE", b"CEND", b"CERR", b"INCLUDE",
                                          b"XINCLUDE", b"SYNTAX", b"OPTIMIZE")}
    files = []
    for p in argv[1:]:
        if os.path.isdir(p):
            for root, _, fs in os.walk(p):
                files += [os.path.join(root, f) for f in fs if f.lower().endswith((".ab3", ".ab2"))]
        else:
            files.append(p)
    by_reg, by_kind, by_file = Counter(), Counter(), Counter()
    allf = []
    for f in sorted(files):
        for item in analyse(f, table, names, kw, asm_words, bridge_words, directive_words, False):
            by_reg[item[0]] += 1
            by_kind[item[1]] += 1
            by_file[f] += 1
            allf.append((f,) + item)
    print("findings: %d in %d files" % (len(allf), len(by_file)))
    print("by register:", dict(sorted(by_reg.items())))
    print("by crossed statement:", dict(by_kind))
    if listing:
        for f, r, kind, w, cl, ln, ctext, instr in allf:
            print("%s: %s written l.%d, %s l.%d [%s], read l.%d [%s]" % (f, r, w, kind, cl, ctext, ln, instr))


if __name__ == "__main__":
    main(sys.argv[1:])
