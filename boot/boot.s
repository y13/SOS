.section	.text

.globl		_start
_start:
.code16
	#Stop interrupts
	cli
	
	#Set registers to 0
	xorl	%eax, %eax
	movl	%eax, %ebx
	movl	%eax, %ecx
	movl	%eax, %edx
	movl	%eax, %ds
	movl	%eax, %es
	movl	%eax, %fs
	movl	%eax, %gs
	movl	%eax, %ss
	
	#Restart interrupts
	sti
	#Jump to main function
	jmp	start

.globl		clear_screen
.type		clear_screen, @function
clear_screen:
	#Protect ebp
	pushl	%ebp
	#Set ebp to the base of the function's stack
	movl	%esp, %ebp

	#Clean screen
	movb	$0x07, %ah #Scroll-down code
	movb	$0x00, %al #Scroll down all lines
	movb	$0x07, %bh #Overwrite with blank spaces
	movb 	$0x00, %ch #New page starts at line 0
	movb 	$0x00, %cl #New page starts at collum 0
	movb 	$0x18, %dh #New page starts goes up to line 0 0x18
	movb 	$0x4F, %dl #New page starts goes up to collum 0x4F
	int 	$0x10 #Screen-interrupt code

	#Set cursor to (0,0)
	movb	$0x02, %ah #Set-cursor code
	movb 	$0x00, %dh #Set to line 0
	movb 	$0x00, %dl #set to collum 0
	movb	$0x00, %bh #Pages's number
	int 	$0x10 #Screen-interrupt code

	#Reset ebp and esp
	movl	%ebp, %esp
	pop 	%ebp
	ret

.globl		print_string
.type		print_string, @function
print_string:
	#Protect ebp
	pushl	%ebp
	#Set ebp to the base of the function's stack
	movl	%esp, %ebp

	#Fetch and push arguments to the functions's stack
	movl	6(%ebp), %eax
	pushl	%eax

	#Read pushed arguments and store it on edx
	movl	-4(%ebp), %edx

	#Print loop
	loop_print_string:
		movb	(%edx), %al #Put string's current char in register
		cmpb	$0, %al #Compare current char to '\0'
		je   	loop_print_string_end

		pushl	%edx #Protect edx
		movb	$0x0E, %ah #Put-char code
		int 	$0x10 #Screen-interrupt code
		popl	%edx #Reset edx

		inc		%edx #Get string's next char
		jmp 	loop_print_string
	loop_print_string_end:

	#Reset ebp and esp
	movl	%ebp, %esp
	pop 	%ebp
	ret

.globl		start
start:
	loop_read_write:
		movb	$0x00, %ah #Read-char code
		int 	$0x16 #Screen-interrupt code
		
		cmp	$'1', %al
		je	clear
		
		cmp	$'2', %al
		je	string

		cmp		$'4', %al
		je		reboot

		movb	$0x0E, %ah #Put-char code
		int 	$0x10 #Screen-interrupt code
		jmp	loop_read_write

		clear:
			pushl	%eax
			call 	clear_screen
			popl	%eax
			jmp	loop_read_write

		string:
			pushl	%eax
			call	clear_screen
			pushl	$version_msg
			call 	print_string
			popl	%eax
			jmp	loop_read_write

		reboot:
			cli
			call	clear_screen
			int 	$0x19

	jmp		halt

halt:	
	jmp	halt

version_msg:
	.asciz	"S.O.S - Superior Operating System 0.0.1"

. = _start + 510
.byte	0x55, 0xAA
