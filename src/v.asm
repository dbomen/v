. import with: EXTREF c_i
v       START 0
        EXTDEF c_i,c_h,c_l,c_k,c_j,c_g,c_G
        EXTREF cl,cr,cu,cd,crsrnl,ctop,cbtm,cfirst,clast,rch,pch,map_ch,input,shiftr,shiftl
        EXTREF wnull,wesc,went
        EXTREF spush,spop,sp

. V interface
. -------------------------------------------------------

. NORMAL mode
. =======================================================
. .......................................................
. i (go to insert mode)
c_i     +STL @sp
        +JSUB spush

        JSUB insert . go to the insert loop

        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. h
. go left (no constraints)
c_h     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

        +JSUB cl

        +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. l
. go right (constraint: if next char == 0 => cannot go right)
c_l     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

        +JSUB cr

        CLEAR A
        +JSUB rch
        +COMP wnull
        JEQ c_lback

        J c_lend

c_lback +JSUB cl

c_lend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. k
. go up (no constraints)
c_k     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

        +JSUB cu

        +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. j
. go down (constraint: if bottom char == 0 => cannot go down)
c_j     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

        +JSUB cd

        CLEAR A
        +JSUB rch
        +COMP wnull
        JEQ c_jback

        J c_jend

c_jback +JSUB cu

c_jend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. g
. go top
c_g     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

c_gloop +JSUB cu        . go up until EOF
        COMP #0
        JEQ c_gend
        J c_gloop

c_gend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. G
. go bottom
c_G     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

c_Gloop +JSUB cd        . go down until EOF
        COMP #0
        JEQ c_Gend      . if at edge => stop

        CLEAR A         . if null => go back and stop
        +JSUB rch
        +COMP wnull
        JEQ c_Gback

        J c_Gloop

c_Gback +JSUB cu
c_Gend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................
. =======================================================

. INSERT mode
. =======================================================
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

insert_escape   +JSUB spop      . pop character off the stack to keep stack consistent
                J insert_end

insert_enter    +JSUB spop      . pop character off the stack to keep stack consistent
                +JSUB crsrnl
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
                
insert_end      CLEAR A         . if cursor at null character => move left
                +JSUB rch
                +COMP wnull
                JEQ insert_end_mv
                J insert_end_stack
insert_end_mv   +JSUB cl

insert_end_stack    +JSUB spop
                    +LDA @sp
                    +JSUB spop
                    +LDL @sp
                    RSUB
. =======================================================
. -------------------------------------------------------

        END v
