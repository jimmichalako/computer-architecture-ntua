# Register Mapping:
# $a0 = int num_layers (argument)
# $s0 = int* input (pointer to current layer input in X)
# $s1 = int* wptr (pointer to weights W)
# $s2 = int* bptr (pointer to biases B)
# $s3 = int layer (outer loop counter)
# $s4 = int j (inner loop counter)
# $s5 = int num_layers (saved copy of argument)
# $s6 = int n_in (number of inputs for current layer)
# $s7 = int n_out (number of neurons in current layer)

network:
    # --- PROLOGUE: Save registers to stack ---
    addi $sp, $sp, -36        # Adjust stack pointer (allocate 36 bytes for 9 items)
    sw   $ra, 32($sp)         # Save return address
    sw   $s0, 28($sp)         # Save $s0 (input pointer)
    sw   $s1, 24($sp)         # Save $s1 (wptr)
    sw   $s2, 20($sp)         # Save $s2 (bptr)
    sw   $s3, 16($sp)         # Save $s3 (layer)
    sw   $s4, 12($sp)         # Save $s4 (j)
    sw   $s5, 8($sp)          # Save $s5 (num_layers)
    sw   $s6, 4($sp)          # Save $s6 (n_in)
    sw   $s7, 0($sp)          # Save $s7 (n_out)

    # --- INITIALIZATION ---
    
    # int *input = X; 
    la   $s0, X               # $s0 = &X[0] (input pointer)

    # int *wptr = W;
    la   $s1, W               # $s1 = &W[0] (weight pointer)

    # int *bptr = B;
    la   $s2, B               # $s2 = &B[0] (bias pointer)
    
    move $s5, $a0             # Save num_layers argument into $s5
    
    # --- OUTER LOOP: for (layer = 1; layer < num_layers; layer++) ---
    li   $s3, 1               # layer = 1

OUTER_LOOP:
    # --- OUTER LOOP CONDITION ---
    bge  $s3, $s5, EXIT_NETWORK # if (layer >= num_layers) goto EXIT_NETWORK

    # --- LOAD LAYER SIZES FROM LAYERS[] ---
    la   $t0, LAYERS          # Load base address of LAYERS array
    
    # Get n_in = LAYERS[layer-1]
    sub  $t1, $s3, 1          # $t1 = layer - 1
    sll  $t1, $t1, 2          # Convert index to bytes (* 4)
    add  $t1, $t0, $t1        # Address of LAYERS[layer-1]
    lw   $s6, 0($t1)          # Load n_in into $s6

    # Get n_out = LAYERS[layer]
    sll  $t2, $s3, 2          # Convert layer index to bytes (* 4)
    add  $t2, $t0, $t2        # Address of LAYERS[layer]
    lw   $s7, 0($t2)          # Load n_out into $s7

    # --- INNER LOOP: for (j = 0; j < n_out; j++) ---
    li   $s4, 0               # j = 0

INNER_LOOP:
    # --- INNER LOOP CONDITION ---
    bge  $s4, $s7, END_INNER  # if (j >= n_out) goto END_INNER

    # --- PREPARE ARGUMENTS FOR neuron() ---
    # Call: neuron(wptr, input, n_in, *bptr)
    # Mapping for neuron: $a0=weights, $a1=inputs, $a2=n, $a3=bias
    
    # 1. $a0 = wptr (Stored in $s1)
    move $a0, $s1             # Copy current weight pointer

    # 2. $a1 = input (Stored in $s0)
    move $a1, $s0             # Pass the current input pointer directly

    # 3. $a2 = n_in (Stored in $s6)
    move $a2, $s6             # Copy n_in

    # 4. $a3 = *bptr (Value pointed to by $s2)
    lw   $a3, 0($s2)          # Load the bias value from memory

    # --- CALL FUNCTION ---
    jal  neuron               # Jump and Link to neuron (result in $v0)

    # --- STORE RESULT ---
    # target address = input + (n_in + j) * 4
    # We write to the next layer's section in X (relative to current position)
    
    add  $t4, $s6, $s4        # $t4 = n_in + j
    sll  $t4, $t4, 2          # $t4 = (n_in + j) * 4 (bytes)
    add  $t5, $s0, $t4        # $t5 = input pointer + offset_bytes
    sw   $v0, 0($t5)          # Store result in X array

    # --- UPDATE POINTERS ---
    # wptr += n_in 
    sll  $t6, $s6, 2          # $t6 = n_in * 4 (bytes)
    add  $s1, $s1, $t6        # Advance wptr ($s1)
    
    # bptr += 1
    addi $s2, $s2, 4          # Advance bptr ($s2) by 4 bytes

    # --- INNER LOOP INCREMENT ---
    addi $s4, $s4, 1          # j++
    j    INNER_LOOP           # Jump to start of inner loop

END_INNER:
    # --- UPDATE INPUT POINTER (OFFSET) ---
    # input += n_in
    # Advance the input pointer to the start of the next layer
    sll  $t8, $s6, 2          # $t8 = n_in * 4 (bytes)
    add  $s0, $s0, $t8        # Advance the input pointer ($s0)

    # --- OUTER LOOP INCREMENT ---
    addi $s3, $s3, 1          # layer++
    j    OUTER_LOOP           # Jump to start of outer loop

EXIT_NETWORK:
    # --- RETURN VALUE ---
    # return *input
    # At the end, $s0 points to the final output in X
    lw   $v0, 0($s0)          # Load final result into return register $v0

    # --- EPILOGUE: Restore and Return ---
    lw   $s7, 0($sp)          # Restore $s7
    lw   $s6, 4($sp)          # Restore $s6
    lw   $s5, 8($sp)          # Restore $s5
    lw   $s4, 12($sp)         # Restore $s4
    lw   $s3, 16($sp)         # Restore $s3
    lw   $s2, 20($sp)         # Restore $s2
    lw   $s1, 24($sp)         # Restore $s1
    lw   $s0, 28($sp)         # Restore $s0
    lw   $ra, 32($sp)         # Restore return address
    addi $sp, $sp, 36         # Restore stack pointer
    jr   $ra                  # Return to caller
