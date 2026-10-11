.data
    # ==========================================================================
    # DATA SECTION
    # ==========================================================================
    
    # LAYERS: Defines structure (Input=3, Hidden=2, Output=1)
    LAYERS: .word 3, 2, 1
    
    # X: Input/Output Array (Total size = 3 + 2 + 1 = 6 integers)
    # Input: [29, 50, 20] because last two digits of AM=YZ=29
    X:      .word 29, 50, 20, 0, 0, 0
    
    # W: Weights
    # Layer 1 (to h0): -2, 5, 3
    # Layer 1 (to h1): -5, 2, 2
    # Layer 2 (to y):  1, 1
    W:      .word -2, 5, 3, -5, 2, 2, 1, 1
    
    # B: Biases
    # h0=0, h1=0, y=0
    B:      .word 0, 0, 0

    # STRINGS
    msg_result: .asciiz "Neural Network Output: "
    msg_class1: .asciiz "\nResult: The digit is 1\n"
    msg_class7: .asciiz "\nResult: The digit is 7\n"

.text
.globl main

# ==============================================================================
# MAIN FUNCTION (PART D)
# ==============================================================================
main:
    # --- 1. PREPARE ARGUMENTS ---
    # The network function takes num_layers as an argument ($a0)
    li   $a0, 3

    # --- 2. CALL NETWORK ---
    jal  network           # Call Part C function
    
    # Result is returned in $v0. Save it to $s0 safely.
    move $s0, $v0

    # --- 3. PRINT NUMERICAL RESULT ---
    # Print label
    li   $v0, 4            # syscall: print_string
    la   $a0, msg_result
    syscall

    # Print integer
    li   $v0, 1            # syscall: print_int
    move $a0, $s0
    syscall

    # --- 4. CLASSIFICATION (Threshold Check) ---
    # Threshold = 230
    # if (output >= 230) print "7" else print "1"
    
    li   $t0, 230
    bge  $s0, $t0, PRINT_7

PRINT_1:
    li   $v0, 4            # syscall: print_string
    la   $a0, msg_class1
    syscall
    j    EXIT_MAIN

PRINT_7:
    li   $v0, 4            # syscall: print_string
    la   $a0, msg_class7
    syscall

EXIT_MAIN:
    # --- 5. EXIT ---
    li   $v0, 10           # syscall: exit
    syscall

# ==============================================================================
# NETWORK FUNCTION (PART C)
# ==============================================================================
# Register Mapping:
# $a0 = int num_layers (argument, saved to stack at 0($sp))
# $s0 = int* input (pointer to current layer input in X)
# $s1 = int* wptr (pointer to weights W)
# $s2 = int* bptr (pointer to biases B)
# $s3 = int layer (outer loop counter)
# $s4 = int j (inner loop counter)
# $s5 = int n_in (inputs per neuron in current layer)
# $s6 = int n_out (neurons in current layer)

network:
    # --- PROLOGUE: Save registers to stack ---
    addi $sp, $sp, -36        # Allocate 36 bytes
    sw   $ra, 32($sp)         # Save return address
    sw   $s0, 28($sp)         # Save $s0
    sw   $s1, 24($sp)         # Save $s1
    sw   $s2, 20($sp)         # Save $s2
    sw   $s3, 16($sp)         # Save $s3
    sw   $s4, 12($sp)         # Save $s4
    sw   $s5, 8($sp)          # Save $s5
    sw   $s6, 4($sp)          # Save $s6
    sw   $a0, 0($sp)          # Save num_layers ($a0) to stack

    # --- INITIALIZATION ---
    la   $s0, X               # $s0 = &X[0] (input pointer)
    la   $s1, W               # $s1 = &W[0] (weight pointer)
    la   $s2, B               # $s2 = &B[0] (bias pointer)

    # --- OUTER LOOP: for (layer = 1; layer < num_layers; layer++) ---
    li   $s3, 1               # layer = 1

OUTER_LOOP:
    # Check Loop Condition (using num_layers from stack)
    lw   $t0, 0($sp)          # Load num_layers
    bge  $s3, $t0, EXIT_NETWORK

    # --- LOAD LAYER SIZES FROM LAYERS[] ---
    la   $t0, LAYERS
    
    # n_in = LAYERS[layer-1]
    sub  $t1, $s3, 1          # layer - 1
    sll  $t1, $t1, 2          # * 4
    add  $t1, $t0, $t1        # address
    lw   $s5, 0($t1)          # $s5 = n_in

    # n_out = LAYERS[layer]
    sll  $t2, $s3, 2          # layer * 4
    add  $t2, $t0, $t2        # address
    lw   $s6, 0($t2)          # $s6 = n_out

    # --- INNER LOOP: for (j = 0; j < n_out; j++) ---
    li   $s4, 0               # j = 0

INNER_LOOP:
    bge  $s4, $s6, END_INNER

    # --- PREPARE ARGUMENTS FOR neuron() ---
    move $a0, $s1             # wptr
    move $a1, $s0             # input pointer
    move $a2, $s5             # n_in
    lw   $a3, 0($s2)          # *bptr (load bias value)

    jal  neuron               # Call neuron

    # --- STORE RESULT ---
    # target = input + (n_in + j)
    add  $t4, $s5, $s4        # n_in + j
    sll  $t4, $t4, 2          # to bytes
    add  $t5, $s0, $t4        # address in X
    sw   $v0, 0($t5)          # Store result

    # --- UPDATE POINTERS ---
    # wptr += n_in
    sll  $t6, $s5, 2          # n_in * 4
    add  $s1, $s1, $t6
    
    # bptr += 1
    addi $s2, $s2, 4

    # --- INNER LOOP INCREMENT ---
    addi $s4, $s4, 1          # j++
    j    INNER_LOOP

END_INNER:
    # --- UPDATE INPUT POINTER ---
    # input += n_in
    sll  $t8, $s5, 2          # n_in * 4
    add  $s0, $s0, $t8        # Advance input pointer

    # --- OUTER LOOP INCREMENT ---
    addi $s3, $s3, 1          # layer++
    j    OUTER_LOOP

EXIT_NETWORK:
    # --- RETURN VALUE ---
    lw   $v0, 0($s0)          # return *input

    # --- EPILOGUE ---
    lw   $s6, 4($sp)
    lw   $s5, 8($sp)
    lw   $s4, 12($sp)
    lw   $s3, 16($sp)
    lw   $s2, 20($sp)
    lw   $s1, 24($sp)
    lw   $s0, 28($sp)
    lw   $ra, 32($sp)
    addi $sp, $sp, 36
    jr   $ra

# ==============================================================================
# NEURON FUNCTION (PART B)
# ==============================================================================
# Register Mapping:
# $a0 = int* w
# $a1 = int* x
# $a2 = int n
# $a3 = int bias
# $v0 = sum

neuron:
    li   $t0, 0           # i = 0
    move $v0, $a3         # sum = bias

NEURON_LOOP:
    bge  $t0, $a2, NEURON_END
    
    sll  $t1, $t0, 2      # offset = i * 4
    
    add  $t2, $a0, $t1    # &w[i]
    lw   $t3, 0($t2)      # w[i]
    
    add  $t4, $a1, $t1    # &x[i]
    lw   $t5, 0($t4)      # x[i]
    
    mul  $t6, $t3, $t5    # w[i] * x[i]
    add  $v0, $v0, $t6    # sum += product
    
    addi $t0, $t0, 1      # i++
    j    NEURON_LOOP

NEURON_END:
    bgez $v0, NEURON_SKIP
    move $v0, $zero       # ReLU: if sum < 0, sum = 0

NEURON_SKIP:
    jr   $ra
