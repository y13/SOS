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

clear_screen:
	pushl	%ebp
	movl	%esp, %ebp

	pushl 	%eax
	pushl 	%ebx
	pushl 	%ecx
	pushl 	%edx

	movb	$0x07, %ah
	movb	$0x00, %al
    movb    $0x07, %bh
    movb 	$0x00, %ch
    movb 	$0x00, %cl
    movb 	$0x18, %dh
    movb 	$0x4F, %dl
    int 	$0x10 

    movb	$0x02, %ah
	movb 	$0x00, %dh
    movb 	$0x00, %dl
    movb    $0x00, %bh
	int 	$0x10

    popl	%edx
    popl	%ecx
    popl	%ebx
    popl	%eax

	pop 	%ebp
	ret

start:
	loop_read_write:
		movb	$0x00, %ah
		int 	$0x16
		
		cmp		$'1', %al
		je		clear
		
		movb	$0x0E, %ah
		int 	$0x10
		jmp		loop_read_write

		clear:
			call clear_screen
			jmp		loop_read_write

	jmp		halt

halt:	
	jmp		halt
	
. = _start + 510
.byte	0x55, 0xAA
