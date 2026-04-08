.globl make_node
.globl insert
.globl get
.globl getAtMost

.text

make_node:
    # x10: val
    addi x2, x2, -16
    sd x1, 8(x2)
    sd x8, 0(x2)
    
    add x8, x10, x0
    li x10, 24
    call malloc
    
    sw x8, 0(x10)
    sd x0, 8(x10)
    sd x0, 16(x10)
    
    ld x8, 0(x2)
    ld x1, 8(x2)
    addi x2, x2, 16
    ret

insert:
    # x10: root
    # x11: val
    bne x10, x0, insert_not_null
    
    add x10, x11, x0
    tail make_node

insert_not_null:
    addi x2, x2, -32
    sd x1, 24(x2)
    sd x8, 16(x2)
    sd x9, 8(x2)
    
    add x8, x10, x0
    add x9, x11, x0
    
    lw x5, 0(x8)
    beq x11, x5, insert_end
    bgt x11, x5, insert_right
    
    ld x10, 8(x8)
    add x11, x9, x0
    call insert
    sd x10, 8(x8)
    j insert_end
    
insert_right:
    ld x10, 16(x8)
    add x11, x9, x0
    call insert
    sd x10, 16(x8)
    
insert_end:
    add x10, x8, x0
    
    ld x1, 24(x2)
    ld x8, 16(x2)
    ld x9, 8(x2)
    addi x2, x2, 32
    ret

get:
    # x10: root
    # x11: val
get_loop:
    beq x10, x0, get_end
    lw x5, 0(x10)
    beq x11, x5, get_end
    blt x11, x5, get_left
    
    ld x10, 16(x10)
    j get_loop
    
get_left:
    ld x10, 8(x10)
    j get_loop
    
get_end:
    ret

getAtMost:
    # x10: val
    # x11: root
    li x6, -1
getAtMost_loop:
    beq x11, x0, getAtMost_end
    lw x5, 0(x11)
    beq x5, x10, getAtMost_exact
    bgt x5, x10, getAtMost_left
    
    add x6, x5, x0
    ld x11, 16(x11)
    j getAtMost_loop
    
getAtMost_left:
    ld x11, 8(x11)
    j getAtMost_loop
    
getAtMost_exact:
    ret
    
getAtMost_end:
    add x10, x6, x0
    ret
