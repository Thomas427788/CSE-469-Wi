#
#
# Compute the fib number recursively.
#
#
.section .text
.global my_fib

my_fib:
    # Base case: if (n <= 1), return n
    li t0, 1            # Load immediate value 1 into t0
    ble a0, t0, base_case # If num <= 1, jump to base_case

    # Recursive case: my_fib(n) = my_fib(n-1) + my_fib(n-2)
    addi sp, sp, -16    # Allocate stack space for recursion
    sw ra, 12(sp)       # Save return address
    sw a0, 8(sp)        # Save current num

    # Compute my_fib(n-1)
    addi a0, a0, -1     # num = num - 1
    jal my_fib       # Recursive call: my_fib(n-1)
    sw a0, 4(sp)        # Save my_fib(n-1) result

    # Compute my_fib(n-2)
    lw a0, 8(sp)        # Restore original num
    addi a0, a0, -2     # num = num - 2
    jal my_fib       # Recursive call: my_fib(n-2)

    # Combine results: my_fib(n-1) + my_fib(n-2)
    lw t1, 4(sp)        # Load my_fib(n-1) result
    add a0, a0, t1      # a0 = my_fib(n-1) + my_fib(n-2)

    # Restore stack and return
    lw ra, 12(sp)       # Restore return address
    addi sp, sp, 16     # Deallocate stack space
    jr ra               # Return to caller

base_case:
    # Return num (a0) for base case
    li a0, 1             # Return 1 for n == 0 or n == 1
    jr ra                # Return to caller