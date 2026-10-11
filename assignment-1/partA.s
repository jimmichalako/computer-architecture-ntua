# Register Mapping:
# $a0 = int* a (base address of array)
# $a1 = int length
# $s1 = min (must be saved to stack because it's a saved register)
# $t0 = i (loop counter)
# $t2 = p (pointer address)
# $s2 = *p (current value loaded from array)

findmin:
    # --- PROLOGUE: Save registers to stack ---
    addi $sp, $sp, -8      # Adjust stack pointer to make room for 2 items
    sw   $ra, 4($sp)       # Save return address
    sw   $s1, 0($sp)       # Save $s1 (callee-saved) so we can use it for 'min'

    # --- INITIALIZATION ---
    addi $t0, $zero, 1     # i = 1
    addi $t2, $a0, 0       # p = &a[0] (copy base address from argument $a0)
    lw   $s1, 0($t2)       # min = *p (load the 1st element into min)

LOOP:
    # --- LOOP CONDITION ---
    beq  $t0, $a1, END     # if (i == length) goto END

    # --- POINTER ARITHMETIC ---
    addi $t2, $t2, 4       # p++ (increment pointer by 4 bytes for next int)
    lw   $s2, 0($t2)       # Load current value (*p) into temporary register $s2

    # --- MIN CHECK: if (*p < min) ---
    slt  $t1, $s2, $s1     # Set $t1 = 1 if (*p < min), else $t1 = 0
    beq  $t1, $zero, NEXT  # If $t1 is 0 (false), skip the update
    add  $s1, $s2, $zero   # min = *p (update min with the new smaller value)

NEXT:
    # --- LOOP INCREMENT ---
    addi $t0, $t0, 1       # i++
    j    LOOP              # Jump back to start of loop

END:
    # --- EPILOGUE: Restore and Return ---
    add  $v0, $s1, $zero   # Place 'min' into return register $v0
    lw   $s1, 0($sp)       # Restore original $s1 value
    lw   $ra, 4($sp)       # Restore return address
    addi $sp, $sp, 8       # Restore stack pointer
    jr   $ra               # Return to caller
