.globl	_start
.text

_start:
.code16
	cli
	xorl	%eax, %eax
	movl	%eax, %ebx
	movl	%eax, %ecx
	movl	%eax, %edx
	movl	%eax, %ds
	movl	%eax, %es
	movl	%eax, %fs
	movl	%eax, %gs
	movl	%eax, %ss
	sti
	jmp		loop

loop:	
	nop
	jmp		loop

. = _start + 510	#"magic number" para entender que é um codigo de BIOS
.byte	0x55, 0xAA
