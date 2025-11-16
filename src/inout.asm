. import with: EXTREF ioinit,cl,cr,cu,cd,crsrnl,rch,pch,map_ch,input
. import ASCII ch with: EXTREF chnull,chesc,wnull,wesc
. import hidden with: EXTREF output,cursor,scrcol,scrrow
io      START 0
        . uncomment for hidden API
        . EXTDEF output,cursor,scrcol,scrrow
        EXTDEF ioinit,cl,cr,cu,cd,crsrnl,rch,pch,map_ch,input,shiftr,shiftl
        EXTDEF chnull,chesc,wnull,wesc
        EXTREF spush,spop,sp

. IO interface
. -------------------------------------------------------

. init IO - inits screen (clears screen and resets cursor)
ioinit      +STL @sp
            +JSUB spush
            +STA @sp
            +JSUB spush
            +STB @sp
            +JSUB spush

            LDA output   . reset cursor
            STA cursor

            LDA #ioinit_cb
            JSUB map_ch

            LDA output   . reset cursor
            STA cursor
            JSUB draw_crsr

            +JSUB spop
            +LDB @sp
            +JSUB spop
            +LDA @sp
            +JSUB spop
            +LDL @sp
            RSUB

. callback for map_ch. Writes #0x00 to cell
ioinit_cb   +STL @sp
            +JSUB spush

            LDCH #0x00
            JSUB pch

            +JSUB spop
            +LDL @sp
            RSUB

. Movement
. all return if can't move because of edge (SOR, EOR, SOC, EOC) in A. {0=EOL, 1=no EOL}
. =======================================================
. move cursor left
cl          +STL @sp
            +JSUB spush
            +STB @sp
            +JSUB spush

            LDA cursor  . if SOC (first column) => end
            SUB output
            LDB scrcol
            JSUB mod
            COMP #0
            JEQ clend

            JSUB remv_crsr

            LDA cursor  . move cursor left
            SUB #1
            STA cursor

            JSUB draw_crsr

            LDA #1
clend       +JSUB spop
            +LDB @sp
            +JSUB spop
            +LDL @sp
            RSUB

. move cursor right
cr          +STL @sp
            +JSUB spush
            +STB @sp
            +JSUB spush

            LDA cursor  . if EOC (last column) => end
            SUB output
            ADD #1
            LDB scrcol
            JSUB mod
            COMP #0
            JEQ crend

            JSUB remv_crsr

            LDA cursor  . move cursor right
            ADD #1
            STA cursor

            JSUB draw_crsr

            LDA #1
crend       +JSUB spop
            +LDB @sp
            +JSUB spop
            +LDL @sp
            RSUB

. move cursor up
cu          +STL @sp
            +JSUB spush
            +STB @sp
            +JSUB spush

            LDA cursor  . if SOR (first row) => end
            SUB output
            DIV scrcol
            COMP #0
            JEQ cuend

            JSUB remv_crsr

            LDA cursor  . move cursor up
            SUB scrcol
            STA cursor

            JSUB draw_crsr

            LDA #1
cuend       +JSUB spop
            +LDB @sp
            +JSUB spop
            +LDL @sp
            RSUB

. move cursor down
cd          +STL @sp
            +JSUB spush
            +STB @sp
            +JSUB spush

            LDA cursor  . if EOR (last row) => end
            SUB output
            DIV scrcol
            ADD #1
            COMP scrrow
            LDA #0
            JEQ cdend

            JSUB remv_crsr

            LDA cursor  . move cursor down
            ADD scrcol
            STA cursor

            JSUB draw_crsr

            LDA #1
cdend       +JSUB spop
            +LDB @sp
            +JSUB spop
            +LDL @sp
            RSUB

. cursor to new line
crsrnl      +STL @sp
            +JSUB spush
            +STB @sp
            +JSUB spush

            LDA cursor  . if EOR (last row) => end
            SUB output
            DIV scrcol
            ADD #1
            COMP scrrow
            LDA #0
            JEQ cnlend
    
            JSUB remv_crsr
    
            LDA cursor  . move cursor to new line
            SUB output
            DIV scrcol
            ADD #1
            MUL scrcol
            ADD output
            STA cursor
    
            JSUB draw_crsr
    
            LDA #1
cnlend      +JSUB spop
            +LDB @sp
            +JSUB spop
            +LDL @sp
            RSUB

. remove cursor indicator
. overwrites A
. overwrites B
remv_crsr   +STL @sp
            +JSUB spush

            LDA cursor      . move cursor to indicator position
            ADD scrcol
            STA cursor

            LDCH chnull     . get null character
            JSUB pch

            LDA cursor      . move cursor back
            SUB scrcol
            STA cursor

            +JSUB spop
            +LDL @sp
            RSUB

. draw cursor indicator
. overwrites A
. overwrites B
draw_crsr   +STL @sp
            +JSUB spush

            LDA cursor      . move cursor to indicator position
            ADD scrcol
            STA cursor

            LDCH chcrsr  . get cursor indicator character
            JSUB pch

            LDA cursor      . move cursor back
            SUB scrcol
            STA cursor

            +JSUB spop
            +LDL @sp
            RSUB

. (A % B) = A - (A / B) * B
mod         +STL @sp
            +JSUB spush

            +STA @sp
            +JSUB spush
            DIVR B, A
            MULR A, B
            +JSUB spop
            +LDA @sp
            SUBR B, A

            +JSUB spop
            +LDL @sp
            RSUB
. =======================================================

. Other
. =======================================================
. read character
. result in A (last BYTE)
rch     +STL @sp
        +JSUB spush

        LDCH @input

        +JSUB spop
        +LDL @sp
        RSUB

. print character to cursor
pch     +STL @sp
        +JSUB spush

        STCH @cursor

        +JSUB spop
        +LDL @sp
        RSUB

. execute a callback for each cell on screen
. params:
.   callback in register A
. while (!= 0)
.    while (!= 0)
.        callback();
.        cr();
.    crsrnl();
map_ch      +STL @sp
            +JSUB spush

            STA map_cb

            LDA #1
map_chl1    COMP #0
            JEQ map_chend

map_chl2    COMP #0
            JEQ map_chl1end

            JSUB @map_cb
            JSUB cr
            J map_chl2

map_chl1end JSUB crsrnl
            J map_chl1

map_chend   +JSUB spop
            +LDL @sp
            RSUB
map_cb      RESW 1

. shift characters right in line. Includes cursor character
shiftr      LDA #0 . TODO
            RSUB
. shift characters left in line. Includes cursor character
shiftl      LDA #0 . TODO
            RSUB
. =======================================================


input   WORD 0xc000 . addr of keyboard

output  WORD 0xb800 . addr of screen
cursor  WORD 0xb800 . addr of cursor
scrcol  WORD 80     . screen number of columns
scrrow  WORD 25     . screen number of rows

chnull     BYTE 0x00   . hex of the null character
chesc      BYTE 0x1B   . hex of the escape character
chcrsr     BYTE 0xAF   . hex of the cursor indicator character

wnull      WORD 0x00   . hex of the null character (3 BYTES)
wesc       WORD 0x1B   . hex of the escape character (3 BYTES)
wcrsr      WORD 0xAF   . hex of the cursor indicator character (3 BYTES)
. -------------------------------------------------------

        END io
