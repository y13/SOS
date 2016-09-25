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
	loop_read_write:
		movb	$0x00, %ah
		int 	$0x16
		
		movb	$0x0E, %ah
		int 	$0x10
		jmp		loop_read_write

	jmp		halt

halt:	
	jmp		halt
	
. = _start + 510
.byte	0x55, 0xAA
