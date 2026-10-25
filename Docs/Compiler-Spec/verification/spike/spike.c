/* Spike: how a C backend would emit an AB3 inline-asm block (Compiler-Spec 10.6.3) */
#include <stdio.h>

struct globals { long a, b, c, sum, wild[4]; };   /* AB3 globals, addressed via a5 */
struct globals G;
struct globals *volatile Gp = &G;

/* bridge helper for "GetReg d4,a*10+b": reads the variables from memory */
long ab3_getreg_1(void) { return Gp->a * 10 + Gp->b; }

/* thunk assembled with vasm, register parameters */
extern long ab3_thunk_add(long x __asm("d0"), long y __asm("d1"));

int main(void)
{
    G.a = 3; G.b = 4;
    long cached = G.a;                    /* may live in a register */

    {
        register struct globals *g __asm("a0") = &G;
        __asm__ volatile (
            "movem.l d2-d7/a2-a6,-(sp)\n\t"   /* block prologue: keep gcc's registers */
            "move.l  a0,a5\n\t"               /* a5 = AB3 globals */
            "move.l  #77,d3\n\t"              /* must survive the bridge */
            "move.l  #5,0(a5)\n\t"            /* wild write: a = 5 */
            "movem.l d0-d3/d5-d7/a0-a6,-(sp)\n\t" /* bridge: GetReg d4,a*10+b */
            "jsr     _ab3_getreg_1\n\t"
            "move.l  d0,d4\n\t"
            "movem.l (sp)+,d0-d3/d5-d7/a0-a6\n\t"
            "add.l   d3,d4\n\t"               /* 5*10+4 + 77 = 131 */
            "move.l  d4,12(a5)\n\t"           /* sum = 131 */
            "lea     16(a5),a1\n\t"           /* wild: computed pointer */
            "moveq   #3,d0\n"
            "1:\tmove.l d0,(a1)+\n\t"
            "dbf     d0,1b\n\t"
            "movem.l (sp)+,d2-d7/a2-a6"
            : : "a"(g) : "memory", "d0", "d1", "a1", "cc");
    }

    printf("a=%ld (5) sum=%ld (131) wild=%ld,%ld,%ld,%ld (3,2,1,0) cached=%ld (3)\n",
           G.a, G.sum, G.wild[0], G.wild[1], G.wild[2], G.wild[3], cached);
    printf("thunk=%ld (42)\n", ab3_thunk_add(40, 2));
    return 0;
}
