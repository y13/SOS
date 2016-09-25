.globl	_start
.text

_start:
.code16
	#Parar interrupcoes
	cli
	
	#Zzerar registradores
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
	jmp		start

.globl		clear_screen
.type		clear_screen, @function
clear_screen:
	#Proteger ebp
	pushl	%ebp
	movl	%esp, %ebp

	#Protegar reistradores
	pushl 	%eax
	pushl 	%ebx
	pushl 	%ecx
	pushl 	%edx

	#Limpar tela
	movb	$0x07, %ah #Codigo de scroll down
	movb	$0x00, %al #Todas as linhas
    movb    $0x07, %bh #Sobrepor com branco
    movb 	$0x00, %ch #Nova pagina comeca na linha 0
    movb 	$0x00, %cl #Nova pagina comeca na coluna 0
    movb 	$0x18, %dh #Nova pagina vai ate a linha 0x18
    movb 	$0x4F, %dl #Nova pagina vai ate a linha 0x4F
    int 	$0x10 #Codigo de interrupcao de tela

    #Setar cursor para o comeco 
    movb	$0x02, %ah #Codigo de setar cursor
	movb 	$0x00, %dh #Linha a setar
    movb 	$0x00, %dl #Coluna a setar
    movb    $0x00, %bh #Numero da pagina
	int 	$0x10 #Codigo de interrupcao de tela

	#Resetar registradores
    popl	%edx
    popl	%ecx
    popl	%ebx
    popl	%eax

    #Resetar ebp
	pop 	%ebp
	ret

start:
	loop_read_write:
		movb	$0x00, %ah #Codigo de leitra de caractere
		int 	$0x16 #Codigo de interrupcao do teclado
		
		cmp		$'1', %al #Compara o caractere lido com '1'
		je		clear
		
		movb	$0x0E, %ah #Codigo de impressao de caractere
		int 	$0x10 #Codigo de interrupcao de tela
		jmp		loop_read_write

		clear:
			call clear_screen
			jmp		loop_read_write

	jmp		halt

halt:	
	jmp		halt
	
. = _start + 510
.byte	0x55, 0xAA
