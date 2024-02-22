:: Build the Blitz Basic 2 library using VASM
:: http://sun.hasenbraten.de/vasm/
:: https://www.chibiakumas.com/z80/vasm.php (Windows build)
:: --------------------------------------------------------------
:: -kick1hunks: makes the compiled object compatible with KS 1.x
:: -Fhunkexe: creates a standard Amiga executable
:: -nosym: don't iclude debugging symbols
:: -o ptplayer.obj: output file name
:: ptplayer.s: source to compile
vasmm68k_mot -kick1hunks -Fhunkexe -nosym -o ptplayer.obj ptplayer.s
