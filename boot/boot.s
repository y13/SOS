.section	.text

.globl		_start
_start:
.code16
	#Parar interrupcoes
	cli
	
	#Zerar registradores
	xorl	%eax, %eax
	movl	%eax, %ebx
	movl	%eax, %ecx
	movl	%eax, %edx
	movl	%eax, %ds
	movl	%eax, %es
	movl	%eax, %fs
	movl	%eax, %gs
	movl	%eax, %ss
	
	#Voltar interrupcoes
	sti
	jmp	start

.globl		clear_screen
.type		clear_screen, @function
clear_screen:
	#Proteger ebp
	pushl	%ebp
	#Setar ebp para o inicio da stack dessa funcao
	movl	%esp, %ebp

	#Limpar tela
	movb	$0x07, %ah #Codigo de scroll down
	movb	$0x00, %al #Todas as linhas
	movb	$0x07, %bh #Sobrepor com branco
	movb 	$0x00, %ch #Nova pagina comeca na linha 0
	movb 	$0x00, %cl #Nova pagina comeca na coluna 0
	movb 	$0x18, %dh #Nova pagina vai ate a linha 0x18
	movb 	$0x4F, %dl #Nova pagina vai ate a linha 0x4F
	int 	$0x10 #Codigo de interrupcao de tela

	#Setar cursor para o comeco 
	movb	$0x02, %ah #Codigo de setar cursor
	movb 	$0x00, %dh #Linha a setar
	movb 	$0x00, %dl #Coluna a setar
	movb	$0x00, %bh #Numero da pagina
	int 	$0x10 #Codigo de interrupcao de tela

	#Resetar ebp e esp
	movl	%ebp, %esp
	pop 	%ebp
	ret

.globl	print_devices
.type	print_devices, @function
print_devices:
	pushl	%ebp
	movl	%esp, %ebp

	int	$0x11

	movl	%eax, -4(%ebp)


	andl	$0x0002, %eax
	cmp	$0, %eax
	je	print_devices_no_num_cop

	pushl	$dev_num_coprocessor
	call	print_string
	popl	%edx

	pushl	$dev_msg_end
	call	print_string
	popl	%edx


	print_devices_no_num_cop:

	movl	-4(%ebp), %eax
	andl	$0x0100, %eax
	cmp	$0, %eax
	je	print_devices_no_dma

	pushl	$dev_dma
	call	print_string
	popl	%edx

	pushl	$dev_msg_end
	call	print_string
	popl	%edx


	print_devices_no_dma:

	movl	-4(%ebp), %eax
	andl	$0x000D, %eax # número de bancos de memórias
	shr	$2, %eax

	addb	$'0', %al
	movb	$0xE, %ah
	movb	$7, %bl

	int	$0x10


	pushl	$dev_memory
	call	print_string
	popl	%edx

	pushl	$dev_msg_end
	call	print_string
	popl	%edx

	pushl	$newline
	call	print_string
	popl	%edx

	movl	%ebp, %esp
	popl	%ebp
	ret

.globl	print_hex
.type	print_hex, @function
print_hex:
	push	%ebp
	mov	%esp, %ebp

	mov	6(%ebp), %edx	# número a ser convertido

	mov	$0xE, %ah
	xor	%bh, %bh
	mov	$7, %bl

	mov	$'0', %al
	int	$0x10

	mov	$'x', %al
	int	$0x10

	xor	%ecx, %ecx
	mov	$32, %cl # único registador que pode fazer shift em outros (???????)

	print_hex_loop:
		sub	$4, %cl

		mov	%edx, %eax
		shr	%cl, %eax
		and	$0xF, %al

		cmp	$9, %al
		jg	print_hex_letter
		#jle	print_hex_letter

		add	$'0', %al
		jmp	print_hex_cont

		print_hex_letter:
		sub	$10, %al
		add	$'A', %al

		print_hex_cont:

		mov	$0xE, %ah
		int	$0x10

		cmp	$0, %cl
		jne	print_hex_loop

	mov	%ebp, %esp
	pop	%ebp
	ret

.globl	print_string
.type	print_string, @function
print_string:
	#Proteger ebp
	pushl	%ebp
	#Setar ebp para o inicio da stack dessa funcao
	movl	%esp, %ebp

	#Pegar e empilhar argumentos para a funcao
	movl	6(%ebp), %eax
	pushl	%eax

	#Ler argumentos e guardar nos registradores
	movl	-4(%ebp), %edx

	#Loop de impressao
	loop_print_string:
		movb	(%edx), %al #Colocar o caractere atual da string no registrador
		cmpb	$0, %al #Comparar para ver se ja chegou no final
		je   	loop_print_string_end

		pushl	%edx #Proteger edx
		movb	$0x0E, %ah #Codigo de impressao de caractere
		int 	$0x10 #Codigo de interrupcao de tela
		popl	%edx #Pegar edx de volta

		inc	%edx #Proximo caractere da string
		jmp 	loop_print_string
	loop_print_string_end:

	#Resetar ebp e esp
	movl	%ebp, %esp
	popl 	%ebp
	ret

.globl		start
start:
	loop_read_write:
		movb	$0x00, %ah #Codigo de leitra de caractere
		int 	$0x16 #Codigo de interrupcao do teclado
		
		cmp	$'1', %al #Compara o caractere lido com '1'
		je	clear
		
		cmp	$'2', %al #Compara o caractere lido com '2'
		je	string

		cmp	$'3', %al
		je	devices

		cmp	$'4', %al #Compara o caractere lido com '4'
		je	reboot

		cmp	$'5', %al
		je	hex

		movb	$0x0E, %ah #Codigo de impressao de caractere
		int 	$0x10 #Codigo de interrupcao de tela
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

		devices:
			call	print_devices
			jmp	loop_read_write

		reboot:
			cli
			call	clear_screen
			int 	$0x19

		hex:
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

dev_msg_end:
	.asciz	" detected\n\r"

. = _start + 510
.byte	0x55, 0xAA
