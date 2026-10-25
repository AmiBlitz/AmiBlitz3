#!/usr/bin/env python3
"""Analyse how assembler code is used in AmiBlitz3 sources.

Usage: asm_usage.py <tokens.txt> [--list] <file-or-dir> ...

Every source is tokenized with the algorithm from 03-tokenizer.md, split into
statements and each assembler statement is assigned to a context:

  basic    inline assembler between Basic statements (main program)
  proc     inside a Statement/Function
  macro    inside a Macro definition
  plugin   inside an !asm ... !basic (or !initasm ... !basic) region

Additionally reported (heuristics, for manual review):

  clobber  a run of consecutive assembler statements in context basic/proc
           writes a4, a5 or a6 and does not restore it in the same run
  basic-in-asm  a Basic statement inside an !asm ... !basic region
"""
import os
import re
import sys
from collections import Counter, defaultdict

# --- tokenizer (03-tokenizer.md) -------------------------------------------
IS, EOL, NEW, STOP, QUOT, COMMENT, COPY, FIRST, TAB = 1, 2, 4, 8, 0x10, 0x20, 0x40, 0x80, 0x100
FLAGS = [STOP | NEW] * 256
FLAGS[0] |= EOL
FLAGS[9] |= TAB
FLAGS[10] |= EOL
FLAGS[32] = STOP | NEW | COPY
for _c in '!%&()*+,-/:<=>?[]^`{|}~':
    FLAGS[ord(_c)] = STOP | NEW | COPY
FLAGS[34] = STOP | NEW | COPY | QUOT
FLAGS[ord('#')] = FLAGS[ord('$')] = STOP | IS | COPY
for _c in "'.@\\":
    FLAGS[ord(_c)] = STOP | COPY
for _c in range(48, 58):
    FLAGS[_c] = IS | COPY
FLAGS[ord(';')] = STOP | NEW | COMMENT | COPY
for _c in list(range(65, 91)) + list(range(97, 123)):
    FLAGS[_c] = FIRST | IS | COPY
FLAGS[ord('_')] = IS | COPY
FLAGS[127] = STOP | NEW


def tokenize(src, table):
    """Return a list of lines; a line is a list of ints (<256 char, >=0x8000 token)."""
    out, start, length, accept, i, n = [], 0, 0, True, 0, len(src)
    while i < n:
        c = src[i]
        if c >= 0x80:
            c = 0x3F
        f = FLAGS[c]
        if length and f & STOP:
            name = bytes(out[start:start + length])
            if c == 0x24 and name + b"$" in table:
                out[start:] = [table[name + b"$"]]
                length, accept, f = 0, False, 0
            elif name in table:
                out[start:] = [table[name]]
                length, accept = 0, False
        if length:
            length = length + 1 if f & IS else 0
        elif f & FIRST and accept:
            length, start = 1, len(out)
        if f & QUOT:
            while True:
                out.append(c)
                i += 1
                c = src[i] if i < n else 0
                if c == 9:
                    c = 32
                f = FLAGS[c]
                if f & (QUOT | EOL) or i >= n:
                    break
        if f & COMMENT:
            while True:
                out.append(c)
                i += 1
                c = src[i] if i < n else 0
                if c == 9:
                    c = 32
                f = FLAGS[c]
                if f & EOL or i >= n:
                    break
        if f & TAB:
            out.append(32)
        if f & EOL:
            out.append(-1)
        if f & NEW:
            accept, length = True, 0
        else:
            accept = False
        if f & COPY:
            out.append(c)
        i += 1
    lines, cur = [], []
    for x in out:
        if x == -1:
            lines.append(cur)
            cur = []
        else:
            cur.append(x)
    lines.append(cur)
    return lines


def skip_header(data):
    """Return (data without XTRA header, number of header lines)."""
    m = re.search(rb"^[ \t]*;[ \t]*/xtra[^\n]*\n", data, re.I | re.M)
    if m and data[:m.start()].count(b"\n") < 200:
        return data[m.end():], data[:m.end()].count(b"\n")
    return data, 0


# --- statements ---------------------------------------------------------------
def statements(line):
    """Split a tokenized line at ':' outside strings; drop comments."""
    stmts, cur, in_str = [], [], False
    for x in line:
        if x == 34:
            in_str = not in_str
        elif not in_str and x == 59:            # ';'
            break
        elif not in_str and x == 58:            # ':'
            stmts.append(cur)
            cur = []
            continue
        cur.append(x)
    stmts.append(cur)
    return stmts


def strip(stmt):
    while stmt and stmt[0] == 32:
        stmt = stmt[1:]
    while stmt and stmt[-1] == 32:
        stmt = stmt[:-1]
    return stmt


def text(stmt, names):
    return "".join(names.get(x, "?") if x >= 0x8000 else chr(x) for x in stmt).strip()


# --- analysis -----------------------------------------------------------------
WRITE_RE = re.compile(r"^(MOVE|MOVEA|LEA|ADDQ|SUBQ|ADDA|SUBA|EXG|MOVEQ|CLR|AND|OR|EOR)\b", re.I)


def written_regs(mnemonic, operands):
    """Address registers a4-a6 written by the instruction (heuristic)."""
    ops = [o.strip().lower() for o in re.split(r",(?![^(]*\))", operands)]
    regs = set()
    if mnemonic.upper() == "MOVEM":
        if len(ops) == 2 and "(" in ops[0]:         # memory -> register list
            for part in ops[1].split("/"):
                m = re.match(r"a(\d)(?:-a(\d))?$", part)
                if m:
                    lo, hi = int(m.group(1)), int(m.group(2) or m.group(1))
                    regs |= {f"a{r}" for r in range(lo, hi + 1)}
    elif mnemonic.upper() == "EXG":
        regs |= {o for o in ops if o in ("a4", "a5", "a6")}
    elif WRITE_RE.match(mnemonic) and ops:
        if ops[-1] in ("a4", "a5", "a6"):
            regs.add(ops[-1])
    return regs & {"a4", "a5", "a6"}


def saved_regs(mnemonic, operands):
    ops = [o.strip().lower() for o in re.split(r",(?![^(]*\))", operands)]
    regs = set()
    if mnemonic.upper() in ("MOVEM", "MOVE") and len(ops) == 2 and ops[1] == "-(a7)":
        for part in ops[0].split("/"):
            m = re.match(r"a(\d)(?:-a(\d))?$", part)
            if m:
                lo, hi = int(m.group(1)), int(m.group(2) or m.group(1))
                regs |= {f"a{r}" for r in range(lo, hi + 1)}
    return regs


def analyse(path, table, names, asm_words, bridge_words, kw, directive_words=frozenset()):
    data = open(path, "rb").read()
    body, offset = skip_header(data)
    lines = tokenize(body, table)
    res = Counter()
    findings = []
    in_macro = 0
    in_proc = False
    asm_mode = False
    exit_check, prev_mode = False, False
    run, run_ctx, run_start = [], None, 0

    def flush():
        nonlocal run
        if run and run_ctx in ("basic", "proc"):
            written, saved = set(), set()
            restored = set()
            for mn, ops in run:
                saved |= saved_regs(mn, ops)
                w = written_regs(mn, ops)
                if mn.upper() == "MOVEM" and "(a7)+" in ops.lower():
                    restored |= w
                written |= w
            bad = written - saved - restored
            if bad:
                res["clobber"] += 1
                findings.append(("clobber", run_start, "regs " + ",".join(sorted(bad))))
        run = []

    for ln, line in enumerate(lines, 1 + offset):
        for st in statements(line):
            st = strip(st)
            if not st:
                continue
            first = st[0]
            # macro definitions
            if first == kw["Macro"]:
                in_macro += 1
                continue
            if first == kw["End"]:
                rest = strip(st[1:])
                if rest and rest[0] == kw["Macro"]:
                    in_macro = max(0, in_macro - 1)
                    continue
                if rest and rest[0] in (kw["Statement"], kw["Function"]):
                    in_proc = False
            if first in (kw["Statement"], kw["Function"]) and not in_macro:
                rest = strip(st[1:])
                if not (rest and rest[0] == kw["Return"]):
                    in_proc = True
            # !asm / !basic / !initasm
            m = re.match(r"!\s*(asm|basic|initasm|exitasm)\b", text(st, names))
            if m and not in_macro:
                flush()
                word = m.group(1)
                res["marker " + word] += 1
                exit_check = asm_mode is False and word == "asm"
                prev_mode = asm_mode
                asm_mode = word in ("asm", "initasm")
                if word == "asm" and in_proc:
                    res["marker asm in proc"] += 1
                continue
            # labels in front of an instruction ("'loop MOVE ...", ".lab MOVE ...")
            body = st
            if body and body[0] < 0x8000 and len(body) > 1:
                k = 1 if body[0] in (39, 46) else 0
                while k < len(body) and body[k] < 0x8000 and body[k] != 32:
                    k += 1
                if k < len(body) and body[k] == 32 and strip(body[k:]) and strip(body[k:])[0] in asm_words:
                    body = strip(body[k:])                   # "label  INSTRUCTION ..."
                elif body[0] in (39, 46) and k == len(body):
                    continue                                 # ".label" / "'label" alone
            head = body[0] if body else None
            ctx = "macro" if in_macro else "plugin" if asm_mode else "proc" if in_proc else "basic"
            # neutral statements: labels, macro calls, compiler directives
            txt = text(body, names)
            is_label = all(x < 0x8000 for x in body) and re.fullmatch(r"[A-Za-z_][\w.]*", txt)
            if (is_label or txt.startswith("!")
                    or txt.startswith("#") or head in directive_words):
                res["neutral " + ctx] += 1
                continue
            if exit_check:
                # "!asm : ... : RTS" inside a Basic If = early exit path; Basic continues
                # after it. Ends at the first unconditional exit or non-asm statement.
                if head in asm_words and names[head] in ("RTS", "JMP", "BRA"):
                    asm_mode = prev_mode
                    exit_check = False
                elif head not in asm_words:
                    exit_check = False
            if head in asm_words:
                res["asm " + ctx] += 1
                ops_text = text(body[1:], names)
                ops_text = re.sub(r"^\.[bwlsdq]\b", "", ops_text).strip()
                if ctx != run_ctx:
                    flush()
                if not run:
                    run_start = ln
                run_ctx = ctx
                run.append((names[head], ops_text))
            elif head in bridge_words:
                res["bridge " + ctx] += 1
                flush()
            else:
                flush()
                res["basic " + ctx] += 1
                if ctx == "plugin":
                    findings.append(("basic-in-asm", ln, text(st, names)[:60]))
    flush()
    return res, findings


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

    total = Counter()
    per_file = {}
    all_findings = defaultdict(list)
    for f in sorted(files):
        res, findings = analyse(f, table, names, asm_words, bridge_words, kw, directive_words)
        per_file[f] = res
        total += res
        for kind, ln, info in findings:
            all_findings[kind].append((f, ln, info))
    files_with_asm = sum(1 for r in per_file.values() if any(k.startswith("asm") for k in r))
    print("files: %d, files with assembler: %d" % (len(files), files_with_asm))
    for k in sorted(total):
        print("  %-24s %8d" % (k, total[k]))
    for kind, items in sorted(all_findings.items()):
        print("%s: %d" % (kind, len(items)))
        if listing:
            for f, ln, info in items:
                print("    %s:%d %s" % (f, ln, info))


if __name__ == "__main__":
    main(sys.argv[1:])
