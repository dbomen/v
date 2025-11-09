. import with: EXTREF c_i
v       START 0
        EXTDEF c_i
        EXTREF cl,cr,cu,cd,crsrnl,rch,pch,map_ch,input
        EXTREF wnull,wesc
        EXTREF spush,spop,sp

. V interface
. -------------------------------------------------------

. NORMAL mode
. =======================================================
. i (go to insert mode)
c_i     +STL @sp     . call insert_loop
        +JSUB spush
        JSUB insert
        +JSUB spop
        +LDL @sp

        RSUB
. =======================================================

. INSERT mode
. =======================================================
. #TODO - ENTER special char + shifting chars from right if needed
. writes characters from keyboard to screen
. ESC to break the loop
insert          STA vsaved_a

                +LDA wnull       . reset input
                +STCH @input

insert_loop     CLEAR A         . get and compare character
                +LDCH @input
                +COMP wnull
                JEQ insert_loop
                STA crnt_ch

                . special characters check
                . ------------------------
                +COMP wesc
                JEQ insert_escape
                J insert_main

insert_escape   J insert_end
                . ------------------------

insert_main     . #TODO: shift chars from right!

                LDA crnt_ch     . write character
                +STL @sp
                +JSUB spush
                +JSUB pch
                +JSUB spop
                +LDL @sp

                +STL @sp        . try to move cursor right #TODO if on edge it overwrites char everytime
                +JSUB spush
                +JSUB cr
                +JSUB spop
                +LDL @sp

                +LDA wnull       . reset input
                +STCH @input
                J insert_loop
                
insert_end      LDA vsaved_a
                RSUB

crnt_ch         RESW 1
. =======================================================


vsaved_a    RESW 1      . helper var to save OG value of register A
. -------------------------------------------------------

        END v
