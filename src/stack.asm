. import with: EXTREF sinit,spush,spop,sp
stk     EXTDEF sinit,spush,spop,sp

. stack interface
. --------------------------------------------
. USAGE:
. PUSHA
.       STA @sp
.       JSUB spush
. POPA
.       JSUB spop
.       LDA @sp

. init stack - sp at the start of the stack
sinit       STA ssaved_a
            LDA #stack
            STA sp
            LDA ssaved_a
            RSUB

. sp += WORD
spush       STA ssaved_a
            LDA sp
            ADD #3
            STA sp
            LDA ssaved_a
            RSUB

. sp -= WORD
spop        STA ssaved_a
            LDA sp
            SUB #3
            STA sp
            LDA ssaved_a
            RSUB

ssaved_a    WORD 0
sp          WORD 0
stack       RESW 1000
. --------------------------------------------

        END stk
