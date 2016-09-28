.section	.text

.globl		_start
_start:
.code16
	# Stop interrupts
	cli

	# Set registers to 0
	xorl	%eax, %eax
	movl	%eax, %ebx
	movl	%eax, %ecx
	movl	%eax, %edx
	movl	%eax, %ds
	movl	%eax, %es
	movl	%eax, %fs
	movl	%eax, %gs
	movl	%eax, %ss
	
	# Restart interrupts
	sti
	# Jump to main function
	jmp	start

.globl		clear_screen
.type		clear_screen, @function
clear_screen:
	# Protect ebp
	pushl	%ebp
	# Set ebp to the base of the function's stack
	movl	%esp, %ebp

	# Clear screen
	movb	$0x07, %ah 	# Scroll-down code
	movb	$0x00, %al 	# Scroll down all lines
	movb	$0x07, %bh 	# Overwrite with blank spaces
	movb 	$0x00, %ch 	# New page starts at line 0
	movb 	$0x00, %cl 	# New page starts at collum 0
	movb 	$0x18, %dh 	# New page starts goes up to line 0 0x18
	movb 	$0x4F, %dl 	# New page starts goes up to collum 0x4F
	int 	$0x10 	# Screen-interrupt code

	# Set cursor to (0,0)
	movb	$0x02, %ah 	# Set-cursor code
	movb 	$0x00, %dh 	# Set to line 0
	movb 	$0x00, %dl 	# set to collum 0
	movb	$0x00, %bh 	# Pages's number
	int 	$0x10 	# Screen-interrupt code

	# Reset ebp and esp
	movl	%ebp, %esp
	pop 	%ebp
	ret

.globl		print_devices
.type		print_devices, @function
print_devices:
	pushl	%ebp
	movl	%esp, %ebp

	int	$0x11

	movl	%eax, -4(%ebp)	# Protect interruption return

	andl	$0x0002, %eax	# Numeric coprocessor bitmask
	cmp	$0, %eax
	je	print_devices_no_num_cop

	pushl	$dev_num_coprocessor
	call	print_string
	popl	%edx

	pushl	$detected_msg
	call	print_string
	popl	%edx


	print_devices_no_num_cop:

	movl	-4(%ebp), %eax	# Restore interruption return into eax
	andl	$0x0100, %eax	# DMA bitmask
	cmp	$0, %eax
	je	print_devices_no_dma

	pushl	$dev_dma
	call	print_string
	popl	%edx

	pushl	$detected_msg
	call	print_string
	popl	%edx


	print_devices_no_dma:

	movl	-4(%ebp), %eax
	andl	$0x000D, %eax	# Number of 64K memory banks bitmask
	shr	$2, %eax		# Remove trailing zeroes

	addb	$'0', %al		# Get corresponding character to the number obtained
	movb	$0xE, %ah
	movb	$7, %bl

	int	$0x10

	pushl	$dev_memory
	call	print_string
	popl	%edx

	pushl	$detected_msg
	call	print_string
	popl	%edx

	pushl	$newline
	call	print_string
	popl	%edx

	movl	%ebp, %esp
	popl	%ebp
	ret

.globl	print_mem
.type	print_mem, @function
print_mem:
	int	$0x12

	pushw	$0	# Fill 64 bits for argument
	push	%ax
	call	print_hex
	pop	%eax

	pushl	$memory
	call	print_string
	pop	%eax

	pushl	$detected_msg
	call	print_string
	pop	%eax

	ret


.globl	print_hex
.type	print_hex, @function
print_hex:
	push	%ebp
	mov	%esp, %ebp

	mov	6(%ebp), %edx	# Function argument

	mov	$0xE, %ah
	xor	%bh, %bh
	mov	$7, %bl

	mov	$'0', %al
	int	$0x10

	mov	$'x', %al
	int	$0x10

	xor	%ecx, %ecx
	mov	$32, %cl		# Only register that can shift others (????)

	print_hex_loop:
		sub	$4, %cl		# Shift 4 bits less than previous iteration

		mov	%edx, %eax		# Preserve edx
		shr	%cl, %eax		# Shift eax for the bitmask
		and	$0xF, %al		# Get next hex digit

		cmp	$9, %al		# If al > 9
		jg	print_hex_letter	# Print 'A' through 'F'
					# Else
		add	$'0', %al		# Print '0' through '9'
		jmp	print_hex_cont

		print_hex_letter:
		sub	$10, %al		# al = al-10 + 'A'
		add	$'A', %al

		print_hex_cont:

		mov	$0xE, %ah
		int	$0x10

		cmp	$0, %cl		# Repeat until last hex digit
		jne	print_hex_loop

	mov	%ebp, %esp
	pop	%ebp
	ret

.globl	print_string
.type	print_string, @function

print_string:
	# Protect ebp
	pushl	%ebp

	# Set ebp to the base of the function's stack
	movl	%esp, %ebp

	# Fetch and push arguments to the functions's stack
	movl	6(%ebp), %eax
	pushl	%eax

	# Read pushed arguments and store it on edx
	movl	-4(%ebp), %edx

	# Print loop
	loop_print_string:
		movb	(%edx), %al # Put string's current char in register
		cmpb	$0, %al	# Compare current char to '\0'
		je   	loop_print_string_end

		pushl	%edx	# Protect edx
		movb	$0x0E, %ah	# Put-char code
		int 	$0x10	# Screen-interrupt code
		popl	%edx	# Reset edx

		inc	%edx	# Get string's next char
		jmp 	loop_print_string
	loop_print_string_end:

	# Reset ebp and esp
	movl	%ebp, %esp
	popl 	%ebp
	ret

.globl		start
start:
	loop_read_write:
		movb	$0x00, %ah	# Read-char code
		int 	$0x16	# Keyboard-interrupt code
		
		cmp	$'1', %al
		je	clear
		
		cmp	$'2', %al
		je	string

		cmp	$'3', %al
		je	devices

		cmp	$'4', %al
		je	reboot

		cmp	$'5', %al
		je	hex

		movb	$0x0E, %ah	# Put-char code
		int 	$0x10	# Screen-interrupt code

		jmp	loop_read_write

		clear:
			call 	clear_screen
			jmp	loop_read_write

		string:
			pushl	$version_msg	# Push argument
			call 	print_string
			addl	$4, %esp		# Pop argument
			jmp	loop_read_write

		devices:
			call	print_devices
			jmp	loop_read_write

		reboot:
			call	clear_screen
			int 	$0x19		# Reboot interrupt

		hex:
			call	print_mem
			jmp	loop_read_write

	jmp	halt

halt:	
	jmp	halt


newline:
	.asciz	"\n\r"

version_msg:
	.asciz	"S.O.S v0.0.1\n\r"

dev_memory:
	.asciz	" x 64K RAM banks"

dev_num_coprocessor:
	.asciz	"Numeric coprocessor"

dev_dma:
	.asciz	"DMA"

memory:
	.asciz	" KB of RAM"

detected_msg:
	.asciz	" detected\n\r"

. = _start + 510
.byte	0x55, 0xAA
