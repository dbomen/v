. import with: EXTREF cl,cr,cu,cd,rch,pch,crsrnl
io      EXTDEF cl,cr,cu,cd,rch,pch,crsrnl
        EXTREF spush,spop,sp

. #TODO
. IO interface
. -------------------------------------------------------

. Other
. =======================================================
. read character
. result in A
rch     LDCH @input
        RSUB

. print character to cursor
pch     STCH @cursor
        RSUB

. cursor to new line
crsrnl  STA scsaved_a

        LDA cursor
        SUB output
        DIV scrcol
        ADD #1
        MUL scrcol
        ADD output
        STA cursor

        LDA scsaved_a
        RSUB
. =======================================================


input   WORD 0xc800 . addr of keyboard

output  WORD 0xb800 . addr of screen
cursor  WORD 0xb800 . addr of cursor
scrcol  WORD 80     . screen number of columns
scrrow  WORD 25     . screen number of rows

scsaved_a   RESW 1      . helper var to save OG value of register A
scsaved_b   RESW 1      . helper var to save OG value of register B

cursor_ch   BYTE 0xAF   . hex of the character that indicates where the cursor is
. -------------------------------------------------------

        END io
