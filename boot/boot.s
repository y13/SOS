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
	jmp		start

start:
	movb	$' ', %al
	movb	$0x07, %ah

	movl	$0xB8000, %ebx
	movl	$0xB8FA0, %ecx
	loop_clean:
		movw	%ax, (%ebx)
		addl	$2, %ebx
		cmpl	%ebx, %ecx
		jne	loop_clean
		
	jmp		halt

halt:	
	jmp		halt
	
. = _start + 510
.byte	0x55, 0xAA