.section	.text

.globl		_start
_start:
.code16
	# Stop interrupts
	cli

	# Set registers to 0
	xor	%eax, %eax
	mov	%eax, %ebx
	mov	%eax, %ecx
	mov	%eax, %edx
	mov	%eax, %ds
	mov	%eax, %es
	mov	%eax, %fs
	mov	%eax, %gs
	mov	%eax, %ss
	
	# Restart interrupts
	sti
	# Jump to main function
	jmp	start


.globl	clear_screen
.type	clear_screen, @function
clear_screen:
	# Protect ebp
	push	%ebp
	# Set ebp to the base of the function's stack
	mov	%esp, %ebp

	# Clear screen
	mov	$0x07, %ah	# Scroll-down code
	mov	$0x00, %al	# Scroll down all lines
	mov	$0x07, %bh	# Overwrite with blank spaces
	mov	$0x00, %ch	# New page starts at line 0
	mov	$0x00, %cl	# New page starts at collum 0
	mov	$0x18, %dh	# New page starts goes up to line 0 0x18
	mov	$0x4F, %dl	# New page starts goes up to collum 0x4F
	int	$0x10	# Screen-interrupt code

	# Set cursor to (0,0)
	mov	$0x02, %ah	# Set-cursor code
	mov	$0x00, %dh	# Set to line 0
	mov	$0x00, %dl	# set to collum 0
	mov	$0x00, %bh	# Pages's number
	int	$0x10	# Screen-interrupt code

	# Reset ebp and esp
	mov	%ebp, %esp
	pop	%ebp
	ret


.globl		print_devices
.type		print_devices, @function
print_devices:
	push	%ebp
	mov	%esp, %ebp

	int	$0x11

	mov	%eax, -4(%ebp)	# Protect interruption return

	and	$0x0002, %eax	# Numeric coprocessor bitmask
	cmp	$0, %eax
	je	print_devices_no_num_cop

	pushl	$dev_num_coprocessor
	call	print_string
	pop	%edx

	pushl	$detected_msg
	call	print_string
	pop	%edx


	print_devices_no_num_cop:

	movl	-4(%ebp), %eax	# Restore interruption return into eax
	and	$0x0100, %eax	# DMA bitmask
	cmp	$0, %eax
	je	print_devices_no_dma

	pushl	$dev_dma
	call	print_string
	pop	%edx

	pushl	$detected_msg
	call	print_string
	pop	%edx


	print_devices_no_dma:

	movl	-4(%ebp), %eax
	and	$0x000D, %eax	# Number of 64K memory banks bitmask
	shr	$2, %eax		# Remove trailing zeroes

	addb	$'0', %al		# Get corresponding character to the number obtained
	mov	$0xE, %ah
	mov	$7, %bl

	int	$0x10

	pushl	$dev_memory
	call	print_string
	pop	%edx

	pushl	$detected_msg
	call	print_string
	pop	%edx

	pushl	$newline
	call	print_string
	pop	%edx

	movl	%ebp, %esp
	pop	%ebp
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
	push	%ebp

	# Set ebp to the base of the function's stack
	mov	%esp, %ebp

	# Fetch and push arguments to the functions's stack
	movl	6(%ebp), %eax
	push	%eax

	# Read pushed arguments and store it on edx
	movl	-4(%ebp), %edx

	# Print loop
	loop_print_string:
		mov	(%edx), %al # Put string's current char in register
		cmp	$0, %al	# Compare current char to '\0'
		je	loop_print_string_end

		push	%edx	# Protect edx
		mov	$0x0E, %ah	# Put-char code
		int	$0x10	# Screen-interrupt code
		pop	%edx	# Reset edx

		inc	%edx	# Get string's next char
		jmp	loop_print_string

	loop_print_string_end:

	# Reset ebp and esp
	mov	%ebp, %esp
	pop	%ebp
	ret

.globl		start
start:
	loop_read_write:
		mov	$0x00, %ah	# Read-char code
		int	$0x16	# Keyboard-interrupt code
		
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

		mov	$0x0E, %ah	# Put-char code
		int	$0x10	# Screen-interrupt code

		jmp	loop_read_write

		clear:
			call	clear_screen
			jmp	loop_read_write

		string:
			pushl	$version_msg	# Push argument
			call	print_string
			add	$4, %esp		# Pop argument
			jmp	loop_read_write

		devices:
			call	print_devices
			jmp	loop_read_write

		reboot:
			call	clear_screen
			int	$0x19		# Reboot interrupt

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
