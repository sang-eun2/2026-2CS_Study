section .data
    msg db 'Hello, NASM!', 10
    len equ $ - msg
section .text
global _start
_start:
    mov eax, 1
    mov edi, 1
    lea rsi, [rel msg]
    mov edx, len
    syscall
    mov eax, 60
    xor edi, edi
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
