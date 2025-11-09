. tests c_i
test1       START 0
            EXTREF c_i
            EXTREF ioinit,cl,cr,cu,cd,crsrnl,rch,pch,map_ch
            EXTREF sinit,spush,spop,sp

            +JSUB sinit . init stack

            +STL @sp    . init IO
            +JSUB spush
            +JSUB ioinit
            +JSUB spop
            +LDL @sp

            . tests
            . -------------------------------------
            +STL @sp    . call c_i
            +JSUB spush
            +JSUB c_i
            +JSUB spop
            +LDL @sp

halt        J halt
            . -------------------------------------

            END test1
