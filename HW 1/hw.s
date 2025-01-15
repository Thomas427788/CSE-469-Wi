.text
.globl sum
#
#
# Sum the numbers from start (inclusive) to finish (non-inclusive).
#
# e.g. sum(5, 8) should return: 5 + 6 + 7 for 18
#
sum:
    # Arguments:
    # a0 -> start (x)
    # a1 -> finish (y)

    addi t0, x0, 0       # Initialize result to 0 (t0 = 0)

loop:
    bge a0, a1, end      # If x >= y, exit the loop
    add t0, t0, a0       # Add current x to result
    addi a0, a0, 1       # Increment x
    j loop               # Repeat the loop

end:
    mv a0, t0            # Move the result into a0 (return value)
    ret                  # Return from the function
