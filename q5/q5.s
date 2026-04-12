# O(n) time, O(1) space
#   - Open input.txt, lseek to end to get size
#   - Use two pointers: left=0, right=size-1 (strip trailing newline)
#   - lseek + read 1 byte from each end, compare, converge inward
#   - No file buffering; only a single byte on stack at a time
#
# Register usage (numeric names):
#   x1  = ra  (return address)
#   x2  = sp  (stack pointer)
#   x5  = t0  (temporary)
#   x6  = t1  (temporary)
#   x8  = fd  (file descriptor)
#   x9  = file size
#   x10 = a0  (syscall arg/return)
#   x11 = a1  (syscall arg)
#   x12 = a2  (syscall arg)
#   x13 = a3  (syscall arg)
#   x17 = a7  (syscall number)
#   x18 = right pointer
#   x19 = left pointer
#   x20 = char at left
#   x21 = char at right
#
# Syscalls (RISC-V Linux):
#   openat=56, close=57, lseek=62, read=63, write=64, exit=93

.section .rodata
filename:
    .string "input.txt"
yes_str:
    .string "Yes\n"
no_str:
    .string "No\n"

.section .text
.globl main

main:
    # Stack frame: 64 bytes
    #   x2+0  : 1-byte read buffer
    #   x2+8  : saved x21
    #   x2+16 : saved x20
    #   x2+24 : saved x19
    #   x2+32 : saved x18
    #   x2+40 : saved x9
    #   x2+48 : saved x8
    #   x2+56 : saved x1 (ra)
    addi x2, x2, -64
    sd   x1,  56(x2)
    sd   x8,  48(x2)
    sd   x9,  40(x2)
    sd   x18, 32(x2)
    sd   x19, 24(x2)
    sd   x20, 16(x2)
    sd   x21,  8(x2)

    # openat(AT_FDCWD=-100, "input.txt", O_RDONLY=0, 0)
    li   x10, -100
    la   x11, filename
    li   x12, 0
    li   x13, 0
    li   x17, 56
    ecall
    mv   x8,  x10          # x8 = fd

    # lseek(fd, 0, SEEK_END=2) -> file size
    mv   x10, x8
    li   x11, 0
    li   x12, 2            # SEEK_END
    li   x17, 62
    ecall
    mv   x9,  x10          # x9 = file size

    # Empty file is a palindrome
    beqz x9, do_yes

    # right = size - 1
    addi x18, x9, -1       # x18 = right pointer

    # Peek at last byte: skip trailing newline if present
    mv   x10, x8
    mv   x11, x18
    li   x12, 0            # SEEK_SET
    li   x17, 62
    ecall
    mv   x10, x8
    mv   x11, x2           # buf = x2+0
    li   x12, 1
    li   x17, 63
    ecall
    lb   x5,  0(x2)
    li   x6,  10           # '\n'
    bne  x5,  x6, init_left
    addi x18, x18, -1      # newline found: right--

init_left:
    # After stripping newline string may be empty -> palindrome
    bltz x18, do_yes

    li   x19, 0            # x19 = left pointer

# Main two-pointer loop
loop:
    # If pointers have crossed, it's a palindrome
    bge  x19, x18, do_yes

    # Seek to left, read 1 byte
    mv   x10, x8
    mv   x11, x19
    li   x12, 0            # SEEK_SET
    li   x17, 62
    ecall
    mv   x10, x8
    mv   x11, x2
    li   x12, 1
    li   x17, 63
    ecall
    lb   x20, 0(x2)        # x20 = char at left

    # Seek to right, read 1 byte
    mv   x10, x8
    mv   x11, x18
    li   x12, 0            # SEEK_SET
    li   x17, 62
    ecall
    mv   x10, x8
    mv   x11, x2
    li   x12, 1
    li   x17, 63
    ecall
    lb   x21, 0(x2)        # x21 = char at right

    # If chars differ -> not a palindrome
    bne  x20, x21, do_no

    # Advance both pointers inward
    addi x19, x19, 1
    addi x18, x18, -1
    j    loop

do_yes:
    li   x10, 1            # stdout
    la   x11, yes_str
    li   x12, 4            # "Yes\n" = 4 bytes
    li   x17, 64           # write
    ecall
    j    do_exit

do_no:
    li   x10, 1            # stdout
    la   x11, no_str
    li   x12, 3            # "No\n" = 3 bytes
    li   x17, 64           # write
    ecall

do_exit:
    ld   x1,  56(x2)
    ld   x8,  48(x2)
    ld   x9,  40(x2)
    ld   x18, 32(x2)
    ld   x19, 24(x2)
    ld   x20, 16(x2)
    ld   x21,  8(x2)
    addi x2,  x2, 64
    li   x10, 0
    ret
