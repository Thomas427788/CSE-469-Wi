.text
.globl my_strcpy
#
#
# e.g. my_strcpy(dest, src);
#     copy the src string into the destination string
#     return a pointer to the destination string
#
my_strcpy:
    mv t0, a0              # Save the original destination address in t0 (result)

copy_loop:
    lb t1, 0(a1)           # Load the byte from src (t1 = *src)
    sb t1, 0(a0)           # Store the byte to dest (*dest = *src)
    beqz t1, done          # If the byte is null terminator (t1 == 0), exit loop

    addi a1, a1, 1         # Increment src pointer (src++)
    addi a0, a0, 1         # Increment dest pointer (dest++)
    j copy_loop            # Repeat the loop

done:
    mv a0, t0              # Move the original dest pointer into a0 (return value)
    ret                    # Return from the function