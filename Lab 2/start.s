.extern main
.globl _start

.text

_start:
#
# Uncomment / add to / etc to test lab 2


                        auipc   a4,0x1000
                        addi    a4,a4,-436
                        add a5,a5,a4
                        add a5,a5,a4
#
# place additional test instructions here

    # Testing ADDI (I-Type)
    addi    x1, x0, 10        # x1 = 10
    addi    x2, x0, 20        # x2 = 20
    addi    x3, x1, -5        # x3 = x1 + (-5) = 5

    # Testing ADD and SUB (R-Type)
    add     x4, x1, x2        # x4 = x1 + x2 = 30
    sub     x5, x2, x1        # x5 = x2 - x1 = 10

    # Testing SLL and SLLI (Shift Left Logical)
    slli    x6, x1, 2         # x6 = x1 << 2 = 10 << 2 = 40
    sll     x7, x1, x2        # x7 = x1 << (x2[4:0]) = 10 << (20 % 32) = 0

    # Testing SRL, SRLI, SRA, and SRAI
    srli    x8, x6, 1         # x8 = x6 >> 1 = 40 >> 1 = 20 (logical right shift)
    srai    x9, x6, 1         # x9 = x6 >>> 1 = 40 >> 1 = 20 (arithmetic right shift)
    srl     x10, x6, x1       # x10 = x6 >> (x1[4:0]) = 40 >> (10 % 32) = 0
    sra     x11, x6, x1       # x11 = x6 >>> (x1[4:0]) = 40 >>> (10 % 32) = 0

    # Test ADD with larger values
    addi    x12, x0, -15      # x12 = -15
    add     x13, x12, x2      # x13 = x12 + x2 = -15 + 20 = 5

    # Testing AUIPC
    auipc   a4, 0x1000     # a4 = PC + (0x1000 << 12)
    addi    a5, a4, -436   # a5 = a4 - 436
    add     a5, a5, a4     # a5 = a5 + a4
    add     a5, a5, a4     # a5 = a5 + a4






### Everything below here is not required for lab2.
######
#
#  halt
#        li a0, 0x0002FFFC
#        sw zero, 0(a0)
        
# Eventually this is is the start of your code for future labs (by lab 4 this will be needed)
    li      sp, (0x00030000 - 16)
    call    main
    call    halt
    j       _start

