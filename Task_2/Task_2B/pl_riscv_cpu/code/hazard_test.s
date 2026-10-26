# hazard_test.s - directed hazard test (assemble in Ripes, text segment at 0x0)
        addi x1, x0, 5        # x1 = 5
        addi x2, x1, 3        # fwd from MEM            -> x2 = 8
        add  x3, x2, x1       # x2 from MEM, x1 from WB -> x3 = 13
        sub  x4, x3, x2       #                         -> x4 = 5
        sw   x4, 0(x0)        # store data fwd          -> mem[0] = 5
        lw   x5, 0(x0)        #                         -> x5 = 5
        add  x6, x5, x5       # LOAD-USE stall          -> x6 = 10
        addi x7, x0, 1        #                         -> x7 = 1
        beq  x6, x6, skip     # taken, fwd into branch
        addi x7, x7, 100      # must be flushed
        addi x7, x7, 200      # must be flushed
skip:   addi x8, x7, 1        #                         -> x8 = 2
        jal  x9, tgt          #                         -> x9 = 52 (pc 48 + 4)
        addi x8, x8, 50       # must be flushed
tgt:    addi x10, x9, 0       # fwd jal link value      -> x10 = 52
        addi x0, x1, 7        # write to x0 (ignored)
        add  x11, x0, x1      # x0 must stay 0          -> x11 = 5
        sw   x1, 16(x0)       # Rd field = 16 but sw does NOT write a reg; mem[16]=5
        add  x14, x16, x1     # x16 must be 0 (no bogus fwd) -> x14 = 5
        sw   x1, 4(x0)
        lw   x12, 4(x0)
        sw   x12, 8(x0)       # load then store of loaded value -> mem[8] = 5, x12 = 5
        add  x15, x12, x1     # lw -> sw -> add chain   -> x15 = 10
done:   beq  x0, x0, done
# Expected: x1=5 x2=8 x3=13 x4=5 x5=5 x6=10 x7=1 x8=2 x9=52 x10=52 x11=5 x12=5 x14=5 x15=10 x16=0 x0=0
