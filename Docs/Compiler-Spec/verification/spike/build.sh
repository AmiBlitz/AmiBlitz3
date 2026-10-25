#!/bin/sh
# Builds the gcc backend spike (Compiler-Spec 10.7); needs m68k-amigaos-gcc and vasm in PATH.
set -e
cd "$(dirname "$0")"
vasmm68k_mot -quiet -Fhunk -o thunk.o thunk.s
for o in O0 O2; do
  m68k-amigaos-gcc -$o -mcrt=nix20 -Wall spike.c thunk.o -o spike_$o
done
rm -f thunk.o
