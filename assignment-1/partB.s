# Register Mapping:
# $a0 = int* w (base address of weights array)
# $a1 = int* x (base address of inputs array)
# $a2 = int n (length of arrays)
# $a3 = int bias (bias value)
# $t0 = i (loop counter)
# $v0 = sum (accumulator, initialized to bias)
# $t3 = w[i] (current weight value)
# $t5 = x[i] (current input value)

neuron:
    # --- INITIALIZATION ---
    li   $t0, 0           # i = 0
    move $v0, $a3         # sum = bias (initialize accumulator with bias argument)

LOOP:
    # --- LOOP CONDITION ---
    bge  $t0, $a2, END    # if (i >= n) goto END

    # --- ARRAY ADDRESSING ---
    sll  $t1, $t0, 2      # offset = i * 4 (convert index to byte offset)
    
    # Load w[i]
    add  $t2, $a0, $t1    # p1 = &w[i] (base w + offset)
    lw   $t3, 0($t2)      # load w[i] into $t3
    
    # Load x[i]
    add  $t4, $a1, $t1    # p2 = &x[i] (base x + offset)
    lw   $t5, 0($t4)      # load x[i] into $t5

    # --- ACCUMULATION ---
    mul  $t6, $t3, $t5    # product = w[i] * x[i]
    add  $v0, $v0, $t6    # sum = sum + product

    # --- LOOP INCREMENT ---
    addi $t0, $t0, 1      # i++
    j    LOOP             # Jump back to start of loop

END:
    # --- ACTIVATION FUNCTION (ReLU) ---
    bgez $v0, SKIP        # if (sum >= 0) goto SKIP
    move $v0, $zero       # sum = 0 (if sum < 0, clamp it to 0)

SKIP:
    # --- EPILOGUE: Return ---
    jr   $ra              # Return sum (value in $v0)
