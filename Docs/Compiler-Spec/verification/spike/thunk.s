; thunk in vasm Motorola syntax
        xdef    _ab3_thunk_add
        section code,code
_ab3_thunk_add:
        add.l   d1,d0
        rts
