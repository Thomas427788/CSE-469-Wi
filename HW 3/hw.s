# Function: my_atoi
#
# Convert a string into a integer.
#
# e.g. my_atoi("-55") should return: -55
#      my_atoi("+55") should return +55
#      my_atoi("55") should return 55
#
.text
.globl my_atoi

my_atoi:
    # a0 contains the address of the input string
    li t0, 0       # t0 will store the result
    li t1, 0       # t1 is the negate flag
    li t2, 0       # t2 is a temporary register

    # Check if input string is null
    beqz a0, end

    # Check for negative sign
    lb t2, 0(a0)
    li t3, '-'
    bne t2, t3, check_plus
    li t1, 1       # Set negate flag
    addi a0, a0, 1 # Move to next character
    j start_conversion

check_plus:
    li t3, '+'
    bne t2, t3, start_conversion
    addi a0, a0, 1 # Move to next character

start_conversion:
    lb t2, 0(a0)   # Load current character

conversion_loop:
    beqz t2, apply_sign  # If null terminator, end conversion

    # Check if character is a digit
    li t3, '0'
    blt t2, t3, apply_sign
    li t3, '9'
    bgt t2, t3, apply_sign

    # Multiply result by 10
    slli t3, t0, 3  # t3 = result * 8
    slli t4, t0, 1  # t4 = result * 2
    add t0, t3, t4  # t0 = result * 10

    # Add current digit
    addi t2, t2, -48  # Convert ASCII to integer
    add t0, t0, t2    # Add to result

    addi a0, a0, 1    # Move to next character
    lb t2, 0(a0)      # Load next character
    j conversion_loop

apply_sign:
    beqz t1, end    # If not negative, we're done
    neg t0, t0      # Negate the result if necessary

end:
    mv a0, t0       # Move result to a0 for return
    ret