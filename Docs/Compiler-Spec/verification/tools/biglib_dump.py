#!/usr/bin/env python3
"""Dump the contents of AmiBlitz3 BigLib files (baseLibs, utilLibs, ...).

Usage: biglib_dump.py [--tokens] [--detail] <biglib> [<biglib> ...]

  --tokens   print "TOKEN lib/idx name help" lines in the same format as
             "AmiBlitz3 -dump token" (user libraries only)
  --detail   print header fields and all forms (args, libs, subs) per token

The format is described in Docs/Compiler-Spec/09-blitzlibs.md.
"""
import struct
import sys

HUNK_HEADER, HUNK_CODE, HUNK_RELOC32, HUNK_END = 0x3F3, 0x3E9, 0x3EC, 0x3F2
HUNK_SYMBOL, HUNK_DEBUG = 0x3F0, 0x3F1

TYPES = {1: "byte", 2: "word", 3: "long", 4: "quick", 5: "float", 7: "string", 8: "double/unknown"}
KINDS = {1: "statement", 2: "function", 3: "command"}


def w(d, o):
    return struct.unpack(">H", d[o:o + 2])[0]


def sw(d, o):
    return struct.unpack(">h", d[o:o + 2])[0]


def l(d, o):
    return struct.unpack(">I", d[o:o + 4])[0]


def cstr(d, o):
    e = d.index(b"\0", o)
    return d[o:e].decode("latin-1"), e + 1


def even(o):
    return (o + 1) & ~1


def split_biglib(data):
    """Yield (code, relocs) for every library in a BigLib file."""
    pos = 0
    while pos + 4 <= len(data):
        size = l(data, pos)
        if size == 0:
            break
        exe = data[pos + 4:pos + 4 + size]
        pos += 4 + size
        if l(exe, 0) != HUNK_HEADER or l(exe, 4) != 0 or l(exe, 8) != 1:
            raise ValueError("unexpected hunk header")
        if l(exe, 24) & 0x3FFFFFFF != HUNK_CODE:
            raise ValueError("first hunk is not HUNK_CODE")
        nlongs = l(exe, 28)
        code = exe[32:32 + 4 * nlongs]
        p = 32 + 4 * nlongs
        relocs = []
        while p < len(exe):
            hid = l(exe, p) & 0x3FFFFFFF
            p += 4
            if hid == HUNK_RELOC32:
                while True:
                    n = l(exe, p)
                    p += 4
                    if n == 0:
                        break
                    p += 4                                  # target hunk (always 0)
                    relocs += [l(exe, p + 4 * i) for i in range(n)]
                    p += 4 * n
            elif hid == HUNK_SYMBOL:                        # ignored by the compiler
                while True:
                    n = l(exe, p)
                    p += 4
                    if n == 0:
                        break
                    p += 4 * n + 4                          # name + value
            elif hid == HUNK_DEBUG:                         # ignored by the compiler
                p += 4 + 4 * l(exe, p)
            elif hid == HUNK_END:
                break
            else:
                raise ValueError("unexpected hunk type %x" % hid)
        yield code, relocs


def skip_libregs(d, o, out=None):
    while True:
        lib = w(d, o)
        o += 2
        if lib == 0:
            return o
        reg = w(d, o)
        o += 2
        if out is not None:
            out.append((lib, reg))


def parse_lib(code):
    """Parse header and token records like process_libraries in the compiler."""
    lib = {
        "libnum": w(code, 4),
        "flags": w(code, 0x0C),
        "first": w(code, 0x0E),
        "last": w(code, 0x10),
        "init": l(code, 0x16),
        "return": sw(code, 0x1A),
        "finit": l(code, 0x1C),
        "error": l(code, 0x2C),
        "tokens": [],
    }
    syslib = lib["libnum"] & 0x8000
    # user libs: tokens libnum*128+1 ...; system libs: fixed range from the header
    num = lib["first"] if syslib else (lib["libnum"] << 7) + 1
    o = 0x30
    while True:
        kind = w(code, o)
        if kind & 0x8000:                                   # !libfin: Dc -1
            break
        rec = {"kind": kind, "forms": [], "number": num}
        o += 6
        if kind == 8:                                       # !dumtoke
            pass
        elif kind & 0xF == 0:                               # !nullsub
            regs = []
            o = skip_libregs(code, o, regs)
            rec["forms"].append({"libs": regs, "subs": struct.unpack(">III", code[o:o + 12])})
            o += 12
            rec["name"] = None
            lib["tokens"].append(rec)
            num += 1
            continue
        elif kind & 4:                                      # legacy form, not produced by libmacs
            o += 4
            while not code[o] & 0x80:
                o += 1
            o = even(o + 1)
        else:                                               # statement/function/command
            while True:
                hdr = w(code, o)
                o += 2
                if hdr & 0x8000:                            # !name: Dc -1
                    break
                nargs = hdr & 0xFF
                args = list(code[o:o + nargs])
                o = even(o + nargs)
                regs = []
                o = skip_libregs(code, o, regs)
                subs = struct.unpack(">III", code[o:o + 12])
                o += 12
                rec["forms"].append({"hdr": hdr, "args": args, "libs": regs, "subs": subs})
        # name block: next.l, number.w, name\0, help\0, even
        o += 6
        rec["name"], o = cstr(code, o)
        rec["help"], o = cstr(code, o)
        o = even(o)
        lib["tokens"].append(rec)
        num += 1
    o += 2
    if l(code, o):
        lib["maxtype"] = struct.unpack(">IIIIIHHH", code[o:o + 26])
    return lib


def main(argv):
    tokens_only = "--tokens" in argv
    detail = "--detail" in argv
    files = [a for a in argv if not a.startswith("--")]
    for path in files:
        data = open(path, "rb").read()
        for code, relocs in split_biglib(data):
            lib = parse_lib(code)
            syslib = lib["libnum"] & 0x8000
            if tokens_only:
                if syslib:
                    continue
                for t in lib["tokens"]:
                    if t["name"] is not None:
                        print("TOKEN %d/%d %s %s" % (t["number"] >> 7, t["number"] & 0x7F,
                                                     t["name"], t["help"]))
                continue
            print("LIB %d%s size=%d relocs=%d init=$%X return=%d finit=$%X error=$%X tokens=%d%s"
                  % (lib["libnum"] if not syslib else lib["libnum"] - 0x10000,
                     " (system)" if syslib else "", len(code), len(relocs), lib["init"],
                     lib["return"], lib["finit"], lib["error"], len(lib["tokens"]),
                     " maxtype" if "maxtype" in lib else ""))
            if detail:
                for t in lib["tokens"]:
                    print("  %-10s %04X %s" % (KINDS.get(t["kind"] & 7, "kind%X" % t["kind"]),
                                               t["number"], t["name"]))
                    for f in t["forms"]:
                        print("      args=%s libs=%s subs=%s" % (
                            f.get("args"), ["%d:%04X" % r for r in f["libs"]],
                            ["$%X" % s for s in f["subs"]]))


if __name__ == "__main__":
    main(sys.argv[1:])
