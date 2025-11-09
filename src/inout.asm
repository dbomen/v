. import with: EXTREF ioinit,cl,cr,cu,cd,crsrnl,rch,pch,map_ch,input
. import ASCII ch with: EXTREF chnull,chesc,wnull,wesc
. import hidden with: EXTREF output,cursor,scrcol,scrrow
io      START 0
        . uncomment for hidden API
        . EXTDEF output,cursor,scrcol,scrrow
        EXTDEF ioinit,cl,cr,cu,cd,crsrnl,rch,pch,map_ch,input
        EXTDEF chnull,chesc,wnull,wesc
        EXTREF spush,spop,sp

. IO interface
. -------------------------------------------------------

. init IO - inits screen (clears screen and resets cursor)
ioinit      STA scsaved_a
            STA scsaved_b

            LDA output   . reset cursor
            STA cursor

            LDA #ioinit_cb
            +STL @sp     . call map_ch
            +JSUB spush
            JSUB map_ch
            +JSUB spop
            +LDL @sp

            LDA output   . reset cursor
            STA cursor
            +STL @sp     . call draw_crsr
            +JSUB spush
            JSUB draw_crsr
            +JSUB spop
            +LDL @sp

            LDA scsaved_b
            LDA scsaved_a
            RSUB

. callback for map_ch. Writes #0x00 to cell
ioinit_cb   LDCH #0x00
            +STL @sp     . call pch
            +JSUB spush
            JSUB pch
            +JSUB spop
            +LDL @sp
            RSUB

. Movement
. all return if can't move because of edge (SOR, EOR, SOC, EOC) in A. {0=EOL, 1=no EOL}
. =======================================================
. move cursor left
cl          STB scsaved_b

            LDA cursor  . if SOC (first column) => end
            SUB output
            LDB scrcol
            +STL @sp
            +JSUB spush
            JSUB mod
            +JSUB spop
            +LDL @sp
            COMP #0
            JEQ clend

            +STL @sp     . call remv_crsr
            +JSUB spush
            JSUB remv_crsr
            +JSUB spop
            +LDL @sp

            LDA cursor  . move cursor left
            SUB #1
            STA cursor

            +STL @sp     . call draw_crsr
            +JSUB spush
            JSUB draw_crsr
            +JSUB spop
            +LDL @sp

            LDA #1
clend       LDB scsaved_b
            RSUB

. move cursor right
cr          STB scsaved_b

            LDA cursor  . if EOC (last column) => end
            SUB output
            ADD #1
            LDB scrcol
            +STL @sp
            +JSUB spush
            JSUB mod
            +JSUB spop
            +LDL @sp
            COMP #0
            JEQ crend

            +STL @sp     . call remv_crsr
            +JSUB spush
            JSUB remv_crsr
            +JSUB spop
            +LDL @sp

            LDA cursor  . move cursor right
            ADD #1
            STA cursor

            +STL @sp     . call draw_crsr
            +JSUB spush
            JSUB draw_crsr
            +JSUB spop
            +LDL @sp

            LDA #1
crend       LDB scsaved_b
            RSUB

. move cursor up
cu          STB scsaved_b

            LDA cursor  . if SOR (first row) => end
            SUB output
            DIV scrcol
            COMP #0
            JEQ cuend

            +STL @sp     . call remv_crsr
            +JSUB spush
            JSUB remv_crsr
            +JSUB spop
            +LDL @sp

            LDA cursor  . move cursor up
            SUB scrcol
            STA cursor

            +STL @sp     . call draw_crsr
            +JSUB spush
            JSUB draw_crsr
            +JSUB spop
            +LDL @sp

            LDA #1
cuend       LDB scsaved_b
            RSUB

. move cursor down
cd          STB scsaved_b

            LDA cursor  . if EOR (last row) => end
            SUB output
            DIV scrcol
            ADD #1
            COMP scrrow
            LDA #0
            JEQ cdend

            +STL @sp     . call remv_crsr
            +JSUB spush
            JSUB remv_crsr
            +JSUB spop
            +LDL @sp

            LDA cursor  . move cursor down
            ADD scrcol
            STA cursor

            +STL @sp     . call draw_crsr
            +JSUB spush
            JSUB draw_crsr
            +JSUB spop
            +LDL @sp

            LDA #1
cdend       LDB scsaved_b
            RSUB

. cursor to new line
crsrnl      STB scsaved_b

            LDA cursor  . if EOR (last row) => end
            SUB output
            DIV scrcol
            ADD #1
            COMP scrrow
            LDA #0
            JEQ cnlend
    
            +STL @sp    . call remv_crsr
            +JSUB spush
            JSUB remv_crsr
            +JSUB spop
            +LDL @sp
    
            LDA cursor  . move cursor to new line
            SUB output
            DIV scrcol
            ADD #1
            MUL scrcol
            ADD output
            STA cursor
    
            +STL @sp    . call draw_crsr
            +JSUB spush
            JSUB draw_crsr
            +JSUB spop
            +LDL @sp
    
            LDA #1
cnlend      LDB scsaved_b
            RSUB

. remove cursor indicator
. overwrites A
. overwrites B
remv_crsr   LDA cursor      . move cursor to indicator position
            ADD scrcol
            STA cursor

            LDCH chnull     . get null character
            +STL @sp         . call pch
            +JSUB spush
            JSUB pch
            +JSUB spop
            +LDL @sp

            LDA cursor      . move cursor back
            SUB scrcol
            STA cursor

            RSUB

. draw cursor indicator
. overwrites A
. overwrites B
draw_crsr   LDA cursor      . move cursor to indicator position
            ADD scrcol
            STA cursor

            LDCH chcrsr  . get cursor indicator character
            +STL @sp         . call pch
            +JSUB spush
            JSUB pch
            +JSUB spop
            +LDL @sp

            LDA cursor      . move cursor back
            SUB scrcol
            STA cursor

            RSUB

. (A % B) = A - (A / B) * B
mod         STA scsaved_a
            DIVR B, A
            MULR A, B
            LDA scsaved_a
            SUBR B, A
            RSUB
. =======================================================

. Other
. =======================================================
. read character
. result in A (last BYTE)
rch     LDCH @input
        RSUB

. print character to cursor
pch     STCH @cursor
        RSUB

. execute a callback for each cell on screen
. params:
.   callback in register A
. while (!= 0)
.    while (!= 0)
.        callback();
.        cr();
.    crsrnl();
map_ch      STA map_cb

            LDA #1
map_chl1    COMP #0
            JEQ map_chend

map_chl2    COMP #0
            JEQ map_chl1end

            +STL @sp         . call callback
            +JSUB spush
            JSUB @map_cb
            +JSUB spop
            +LDL @sp
            +STL @sp         . call cr
            +JSUB spush
            JSUB cr
            +JSUB spop
            +LDL @sp
            J map_chl2

map_chl1end +STL @sp         . call crsrnl
            +JSUB spush
            JSUB crsrnl
            +JSUB spop
            +LDL @sp
            J map_chl1

map_chend    RSUB
map_cb      RESW 1
. =======================================================


input   WORD 0xc000 . addr of keyboard

output  WORD 0xb800 . addr of screen
cursor  WORD 0xb800 . addr of cursor
scrcol  WORD 80     . screen number of columns
scrrow  WORD 25     . screen number of rows

scsaved_a   RESW 1      . helper var to save OG value of register A
scsaved_b   RESW 1      . helper var to save OG value of register B

chnull      BYTE 0x00   . hex of the null character
chesc       BYTE 0x1B   . hex of the escape character
chcrsr      BYTE 0xAF   . hex of the cursor indicator character

wnull      WORD 0x00   . hex of the null character (3 BYTES)
wesc       WORD 0x1B   . hex of the escape character (3 BYTES)
wcrsr      WORD 0xAF   . hex of the cursor indicator character (3 BYTES)
. -------------------------------------------------------

        END io
