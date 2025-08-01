section .text
global calculate_distances_asm

; Function: calculate_distances_asm
; Windows x64 calling convention:
;   rcx - n (vector length)
;   rdx - x1 pointer
;   r8  - x2 pointer  
;   r9  - y1 pointer
;   [rsp+40] - y2 pointer (5th parameter on stack)
;   [rsp+48] - z pointer (6th parameter on stack, output)
;
; Formula: z[i] = sqrt((x2[i] - x1[i])^2 + (y2[i] - y1[i])^2)

calculate_distances_asm:
    push rbp
    mov rbp, rsp
    
    ; Save registers that we'll modify (Windows x64 requires saving xmm6-xmm15)
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32         ; Allocate shadow space for function calls
    
    ; Load parameters from stack
    mov r10, [rbp + 48]  ; y2 pointer (5th parameter)
    mov r11, [rbp + 56]  ; z pointer (6th parameter)
    
    ; Check if n is 0
    test rcx, rcx
    jz .done
    
    ; Initialize loop counter
    xor rax, rax            ; i = 0
    mov rbx, rcx            ; n (now in rcx instead of rdi)
    
    ; Check if we can process 4 elements at once (SIMD)
    cmp rbx, 4
    jl .scalar_loop
    
    ; Calculate how many SIMD iterations we can do
    mov r12, rbx
    shr r12, 2              ; r12 = n / 4 (number of SIMD iterations)
    shl r12, 2              ; r12 = (n / 4) * 4 (elements processed by SIMD)
    
.simd_loop:
    cmp rax, r12
    jge .check_remainder
    
    ; Load 4 single-precision floats from each vector
    ; rdx = x1, r8 = x2, r9 = y1, r10 = y2
    movups xmm0, [rdx + rax*4]    ; x1[i:i+3]
    movups xmm1, [r8 + rax*4]     ; x2[i:i+3]
    movups xmm2, [r9 + rax*4]     ; y1[i:i+3]
    movups xmm3, [r10 + rax*4]    ; y2[i:i+3]
    
    ; Calculate dx = x2 - x1
    subps xmm1, xmm0              ; xmm1 = x2[i:i+3] - x1[i:i+3]
    
    ; Calculate dy = y2 - y1
    subps xmm3, xmm2              ; xmm3 = y2[i:i+3] - y1[i:i+3]
    
    ; Calculate dx^2
    mulps xmm1, xmm1              ; xmm1 = dx^2
    
    ; Calculate dy^2
    mulps xmm3, xmm3              ; xmm3 = dy^2
    
    ; Calculate dx^2 + dy^2
    addps xmm1, xmm3              ; xmm1 = dx^2 + dy^2
    
    ; Calculate sqrt(dx^2 + dy^2)
    sqrtps xmm1, xmm1             ; xmm1 = sqrt(dx^2 + dy^2)
    
    ; Store result
    movups [r11 + rax*4], xmm1    ; z[i:i+3] = result
    
    ; Increment counter by 4
    add rax, 4
    jmp .simd_loop

.check_remainder:
    ; Process remaining elements (if any) using scalar operations
    cmp rax, rbx
    jge .done

.scalar_loop:
    cmp rax, rbx
    jge .done
    
    ; Load single elements
    movss xmm0, [rdx + rax*4]     ; x1[i]
    movss xmm1, [r8 + rax*4]      ; x2[i]
    movss xmm2, [r9 + rax*4]      ; y1[i]
    movss xmm3, [r10 + rax*4]     ; y2[i]
    
    ; Calculate dx = x2 - x1
    subss xmm1, xmm0              ; xmm1 = x2[i] - x1[i]
    
    ; Calculate dy = y2 - y1
    subss xmm3, xmm2              ; xmm3 = y2[i] - y1[i]
    
    ; Calculate dx^2
    mulss xmm1, xmm1              ; xmm1 = dx^2
    
    ; Calculate dy^2
    mulss xmm3, xmm3              ; xmm3 = dy^2
    
    ; Calculate dx^2 + dy^2
    addss xmm1, xmm3              ; xmm1 = dx^2 + dy^2
    
    ; Calculate sqrt(dx^2 + dy^2)
    sqrtss xmm1, xmm1             ; xmm1 = sqrt(dx^2 + dy^2)
    
    ; Store result
    movss [r11 + rax*4], xmm1     ; z[i] = result
    
    ; Increment counter
    inc rax
    jmp .scalar_loop

.done:
    ; Restore stack and registers
    add rsp, 32         ; Deallocate shadow space
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    
    ; Restore stack frame
    mov rsp, rbp
    pop rbp
    ret