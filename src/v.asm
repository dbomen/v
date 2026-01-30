. import with: EXTREF c_i,c_h,c_l,c_k,c_j,c_g,c_G,c_w,c_b,c_0,c_dlr
v       START 0
        EXTDEF c_i,c_h,c_l,c_k,c_j,c_g,c_G,c_w,c_b,c_0,c_dlr
        EXTREF cl,cr,cu,cd,crsrnl,ctop,cbtm,cfirst,clast,cprev,rch,pch,map_ch,input,shiftr,shiftl
        EXTREF wnull,wesc,went,wcrsr,wspace
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

        . if line null (if first character in line == 0) => go back and stop
        +JSUB cfirst
        CLEAR A
        +JSUB rch
        +COMP wnull
        JEQ c_jback

        +JSUB cprev
        J c_jend

c_jback +JSUB cprev
        +JSUB cu
c_jend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. g
. go to first character
c_g     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

        +JSUB ctop

c_gend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. G
. go to last character
c_G     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

c_Gloop +JSUB cd        . go down until EOF
        COMP #0
        JEQ c_Gend      . if at edge => stop

        . if line null (if first character in line == 0) => go back and stop
        +JSUB cfirst
        CLEAR A
        +JSUB rch
        +COMP wnull
        JEQ c_Gback

        J c_Gloop

c_Gback +JSUB cu
c_Gend  +JSUB cr        . go right until EOR (end of row - fist null character)
        CLEAR A
        +JSUB rch
        +COMP wnull
        JEQ c_Geend
        J c_Gend

c_Geend +JSUB cl

        +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. w
. go to next word in line
c_w     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

c_wloop +JSUB cr

        COMP #0         . if EOF (EOR) then end
        JEQ c_wend

        CLEAR A
        +JSUB rch
        +COMP wnull      . if EOR (because next is null) then go back and end
        JEQ c_wback

        +COMP wspace     . if space try going right and end
        JEQ c_wspac

        J c_wloop       . else try again

c_wspac +JSUB cr
        COMP #0         . if EOF (EOR) then end
        JEQ c_wend
        CLEAR A
        +JSUB rch
        +COMP wnull      . if EOR (because next is null) then go back and end
        JEQ c_wback
        +COMP wspace     . if another space try again
        JEQ c_wspac
        J c_wend        . else end

c_wback +JSUB cl
c_wend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. b
. go to previous word in line
c_b     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

c_bloop +JSUB cl

        COMP #0         . if EOF (SOR) then end
        JEQ c_bend

        CLEAR A
        +JSUB rch
        +COMP wspace     . if space try going left and end
        JEQ c_bspac

        J c_bloop       . else try again

c_bspac +JSUB cl
        COMP #0         . if EOF (SOR) then end
        JEQ c_bend
        CLEAR A
        +JSUB rch
        +COMP wspace     . if another space try again
        JEQ c_bspac
        J c_bend        . else end

c_bend  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. 0
. go to first character in line
c_0     +STL @sp
        +JSUB spush
        +STA @sp        . store old A
        +JSUB spush

        +JSUB cfirst

c_0end  +JSUB spop
        +LDA @sp
        +JSUB spop
        +LDL @sp
        RSUB
. .......................................................

. .......................................................
. $
. go to last character in line
c_dlr       +STL @sp
            +JSUB spush
            +STA @sp        . store old A
            +JSUB spush

            +JSUB clast     . go till last in line (even if null) and go back until u find a non-null character
            CLEAR A
            +JSUB rch       . if null => find non-null
            +COMP wnull
            JEQ c_dlrloop
            J c_dlrend        . else if non-null end

c_dlrloop   +JSUB cl
            COMP #0         . if EOF (SOR) => end
            JEQ c_dlrend
            CLEAR A
            +JSUB rch       . if still null => try again
            +COMP wnull
            JEQ c_dlrloop
            J c_dlrend      . else end

c_dlrend    +JSUB spop
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
