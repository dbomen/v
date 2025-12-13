. import with: EXTREF c_i
v       START 0
        EXTDEF c_i
        EXTREF cl,cr,cu,cd,crsrnl,rch,pch,map_ch,input,shiftr,shiftl
        EXTREF wnull,wesc,went
        EXTREF spush,spop,sp

. V interface
. -------------------------------------------------------

. NORMAL mode
. =======================================================
. i (go to insert mode)
c_i     +STL @sp
        +JSUB spush

        JSUB insert . go to the insert loop

        +JSUB spop
        +LDL @sp
        RSUB
. =======================================================

. INSERT mode
. =======================================================
. #TODO - ENTER special char + shifting chars from right if needed
. writes characters from keyboard to screen
. ESC to break the loop
insert          +STL @sp
                +JSUB spush
                +STA @sp        . store old A
                +JSUB spush

                +LDA wnull      . reset input
                +STCH @input

insert_loop     CLEAR A         . get and compare character
                +LDCH @input
                +COMP wnull
                JEQ insert_loop
                +STA @sp        . store current character
                +JSUB spush

                . special characters check
                . ------------------------
                +COMP wesc
                JEQ insert_escape

                +COMP went
                JEQ insert_enter

                J insert_main

insert_escape   J insert_end

insert_enter    +JSUB crsrnl
                J insert_reset
                . ------------------------

insert_main     +JSUB shiftr

                +JSUB spop      . get and write character
                +LDA @sp
                +JSUB pch

                +JSUB cr        . try to move cursor right #FIXME if on edge it overwrites char everytime

insert_reset    +LDA wnull      . reset input
                +STCH @input
                J insert_loop
                
insert_end      +JSUB spop
                +LDA @sp
                +JSUB spop
                +LDL @sp
                RSUB

crnt_ch         RESW 1
. =======================================================
. -------------------------------------------------------

        END v
