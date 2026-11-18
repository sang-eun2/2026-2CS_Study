	.file	"reference.c"
	.intel_syntax noprefix
	.text
	.globl	for_loop_sum
	.type	for_loop_sum, @function
for_loop_sum:
.LFB0:
	.cfi_startproc
	endbr64
	mov	eax, 0
	mov	edx, 0
.L2:
	cmp	eax, esi
	jge	.L4
	movsx	rcx, eax
	add	edx, DWORD PTR [rdi+rcx*4]
	add	eax, 1
	jmp	.L2
.L4:
	mov	eax, edx
	ret
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
