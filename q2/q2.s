.section .rodata
fmt_str:
    .string "%ld "
newline_str:
    .string "\n"

.text
.globl main

main:
    # Prologue: save callee-saved registers and return address
    addi x2, x2, -64
    sd x1, 56(x2)
    sd x18, 48(x2)
    sd x19, 40(x2)
    sd x20, 32(x2)
    sd x21, 24(x2)
    sd x22, 16(x2)
    sd x23, 8(x2)
    sd x24, 0(x2)

    # Check if argc > 1
    li x5, 1
    ble x10, x5, end_main_success

    # n = argc - 1 (x18)
    addi x18, x10, -1
    add x19, x11, x0    # argv (x19)

    # malloc(n * 8) for arr
    slli x10, x18, 3
    call malloc
    add x20, x10, x0    # arr address in x20

    # malloc(n * 8) for result
    slli x10, x18, 3
    call malloc
    add x21, x10, x0    # result address in x21

    # malloc(n * 8) for stack
    slli x10, x18, 3
    call malloc
    add x22, x10, x0    # stack address in x22

    # Parse args into arr
    li x24, 0           # i = 0
parse_loop:
    bge x24, x18, parse_done
    
    # argv[i + 1] -> x10
    addi x5, x24, 1
    slli x5, x5, 3
    add x5, x19, x5
    ld x10, 0(x5)
    call atoi
    
    # arr[i] = atoi(argv[i+1])
    slli x5, x24, 3
    add x5, x20, x5
    sd x10, 0(x5)
    
    addi x24, x24, 1
    j parse_loop
parse_done:

    # Execute Next Greater Element algorithm
    # stack_top = 0
    li x23, 0
    
    # Initialize result array with -1
    li x24, 0
    li x6, -1
init_res_loop:
    bge x24, x18, init_res_done
    slli x5, x24, 3
    add x5, x21, x5
    sd x6, 0(x5)
    addi x24, x24, 1
    j init_res_loop
init_res_done:

    # for (i = n - 1; i >= 0; i--)
    addi x24, x18, -1
ng_loop:
    blt x24, x0, ng_done
    
    # arr[i] value -> x15
    slli x5, x24, 3
    add x5, x20, x5
    ld x15, 0(x5)
    
while_loop:
    # if (stack_top == 0) break
    beq x23, x0, while_end
    
    # stack.top() index -> x16
    addi x6, x23, -1
    slli x6, x6, 3
    add x6, x22, x6
    ld x16, 0(x6)
    
    # arr[stack.top()] value -> x17
    slli x7, x16, 3
    add x7, x20, x7
    ld x17, 0(x7)
    
    # if (arr[stack.top()] > arr[i]) break
    bgt x17, x15, while_end
    
    # stack.pop()
    addi x23, x23, -1
    j while_loop
while_end:

    # if (stack_top != 0) result[i] = stack.top()
    beq x23, x0, skip_res
    
    addi x6, x23, -1
    slli x6, x6, 3
    add x6, x22, x6
    ld x16, 0(x6)
    
    slli x7, x24, 3
    add x7, x21, x7
    sd x16, 0(x7)
skip_res:

    # stack.push(i)
    slli x6, x23, 3
    add x6, x22, x6
    sd x24, 0(x6)
    addi x23, x23, 1
    
    # i--
    addi x24, x24, -1
    j ng_loop
ng_done:

    # Print results
    li x24, 0
print_loop:
    bge x24, x18, print_done
    
    slli x5, x24, 3
    add x5, x21, x5
    ld x11, 0(x5)
    
    la x10, fmt_str
    call printf
    
    addi x24, x24, 1
    j print_loop
print_done:

    la x10, newline_str
    call printf

end_main_success:
    li x10, 0
    # Epilogue
    ld x1, 56(x2)
    ld x18, 48(x2)
    ld x19, 40(x2)
    ld x20, 32(x2)
    ld x21, 24(x2)
    ld x22, 16(x2)
    ld x23, 8(x2)
    ld x24, 0(x2)
    addi x2, x2, 64
    ret
