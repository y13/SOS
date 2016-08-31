.globl	_start
.text

_start:
.code16
	xorw	%ax, %ax
	movw	%ax, %ds
	movw	%ax, %ss
	movw	%ax, %fs
	jmp		start

init_msg:
	.ascii	"S.O.S - Superior Operating System!\nAlpha Version 0.0.1\0"

#TO DO
#arg1: endereco da string; #arg2: posicao para imrpimir 
#print_string:

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

	movl	$0xB8000, %ebx
	movl	$init_msg, %ecx
	loop_print:
		movb	(%ecx), %al
		cmpb	$0, %al
		je 		loop_print_end

		cmpb	$10, %al
		je		loop_print_newline

		movw	%ax, (%ebx)
		addl	$2, %ebx
		jmp		loop_print_loopback

		loop_print_newline:
			pushl	%eax
			pushl	%edx
			movl	%ebx, %eax
			movl	$0xA0, %ebx
			xorl	%edx, %edx

			subl	$0xB8000, %eax
			addl	%ebx, %eax
			divl	%ebx
			mull	%ebx
			addl	$0xB8000, %eax

			movl	%eax, %ebx
			popl	%edx
			popl	%eax
			
		loop_print_loopback:
			addl	$1, %ecx
			jmp		loop_print
	loop_print_end:


loop:	jmp loop
. = _start + 510	#"magic number" para entender que é um codigo de BIOS
.byte	0x55, 0xAA