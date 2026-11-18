	.file	"reference.c"
	.intel_syntax noprefix
	.text
	.globl	for_loop_sum
	.type	for_loop_sum, @function
for_loop_sum:
.LFB0:
	.cfi_startproc
	endbr64
	test	esi, esi
	jle	.L4
	mov	rax, rdi
	lea	edx, -1[rsi]
	lea	rcx, 4[rdi+rdx*4]
	mov	edx, 0
.L3:
	add	edx, DWORD PTR [rax]
	add	rax, 4
	cmp	rax, rcx
	jne	.L3
.L1:
	mov	eax, edx
	ret
.L4:
	mov	edx, 0
	jmp	.L1
	.cfi_endproc
.LFE0:
	.size	for_loop_sum, .-for_loop_sum
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	 1f - 0f
	.long	 4f - 1f
	.long	 5
0:
	.string	 "GNU"
1:
	.align 8
	.long	 0xc0000002
	.long	 3f - 2f
2:
	.long	 0x3
3:
	.align 8
4:
