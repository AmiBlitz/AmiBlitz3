#!/usr/bin/env python3
"""Extract the macros stored in an AmiBlitz3 resident file (.res).

Usage: res_macros.py <file.res> <tokens.txt>

<tokens.txt> is the output of "AmiBlitz3 -dump token" and is used to turn
the token words in the macro bodies back into text.

A resident file is an AmigaOS hunk file whose first hunk holds the data the
compiler copies into its lists (see fixtypes/fixmacs/fixconsts in
AmiBlitz3.ab3). A macro entry looks like this (offsets relative to the hunk
start, pointers are relocated by LoadSeg):

  +0  next.l      pointer to the next macro entry (0 = last)
  +4  body.l      pointer to the body
  +8  length.w    body length in bytes
  +10 count.w     expansion counter (`@)
  +12 nameend.b   offset of the byte after the name (= 13 + len(name))
  +13 name        0-terminated, padded to an even address
      body        tokenized text, statements joined by ":"

The entries are found by scanning for headers whose body pointer matches the
position right after the name; the list is then followed via "next".
"""
import re
import struct
import sys

HUNK_HEADER = 0x3F3
HUNK_CODE, HUNK_DATA = 0x3E9, 0x3EA


def first_hunk_offset(d):
    """Return the file offset of the data of the first hunk."""
    if struct.unpack(">I", d[:4])[0] != HUNK_HEADER:
        raise ValueError("not an AmigaOS hunk file")
    pos = 4
    while struct.unpack(">I", d[pos:pos + 4])[0]:      # resident library names
        pos += 4 + 4 * struct.unpack(">I", d[pos:pos + 4])[0]
    pos += 4
    _, first, last = struct.unpack(">III", d[pos:pos + 12])
    pos += 12 + 4 * (last - first + 1)                  # hunk size table
    if struct.unpack(">I", d[pos:pos + 4])[0] & 0x3FFFFFFF not in (HUNK_CODE, HUNK_DATA):
        raise ValueError("first hunk is not CODE/DATA")
    return pos + 8


def load_tokens(path):
    tokens = {}
    for line in open(path, encoding="latin-1"):
        m = re.match(r"TOKEN (\d+)/(\d+) (\S+)", line)
        if m:
            word = 0x8000 | int(m.group(1)) << 7 | int(m.group(2))
            tokens.setdefault(word, m.group(3))
    return tokens


def entry_at(d, base, rel):
    off = base + rel
    if off < base or off + 14 > len(d):
        return None
    nxt, body, length, count, nameend = struct.unpack(">IIHHB", d[off:off + 13])
    if nameend < 14:
        return None
    name = d[off + 13:off + nameend - 1]
    if d[off + nameend - 1] != 0 or not name or any(c < 0x21 or c > 0x7E for c in name):
        return None
    if body != rel + ((nameend + 1) & ~1) or base + body + length > len(d):
        return None
    return nxt, body, length, name.decode("latin-1")


def detokenize(raw, tokens):
    out, i, in_str = [], 0, False
    while i < len(raw):
        c = raw[i]
        if c == 0x22:
            in_str = not in_str
        if c >= 0x80 and not in_str:
            word = c << 8 | raw[i + 1]
            out.append(tokens.get(word, "????%04X" % word))
            i += 2
            continue
        out.append(chr(c))
        i += 1
    return "".join(out)


def main(res_path, tokens_path):
    d = open(res_path, "rb").read()
    tokens = load_tokens(tokens_path)
    base = first_hunk_offset(d)

    entries = {}
    for rel in range(0, len(d) - base - 14, 2):
        e = entry_at(d, base, rel)
        if e:
            entries[rel] = e
    targets = {e[0] for e in entries.values()}
    heads = [rel for rel in entries if rel not in targets]

    # take the longest chain - that is the macro list
    best = []
    for head in heads:
        chain, rel = [], head
        while rel in entries and rel not in chain:
            chain.append(rel)
            rel = entries[rel][0]
        if len(chain) > len(best):
            best = chain

    for rel in best:
        _, body, length, name = entries[rel]
        text = detokenize(d[base + body:base + body + length], tokens)
        print("Macro %s\n  %s\nEnd Macro\n" % (name, text))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
