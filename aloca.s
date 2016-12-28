#eax --- Usado para acesso aos cabeçalhos e controle dos dados e retorno dos ponteiros para as posições de memória alocadas.
#ebx --- Utilizado para calculos da posição corrente.
#ecx --- Utilizado para receber o valor do tamanho de um bloco aloca anteriormente para comparação.
#edx --- Utilizado para receber o valor do parametro passado pelo chamador, que é o tamanho a ser alocado. 


.section .data

	#=== Variáveis Globais ===#

	inicio_Heap: .int 0
	pos_Corrente: .int 0
	total_Livre: .int 0
	total_Ocupado: .int 0
	segmentos_Ocupados: .int 0 
	segmentos_Livres: .int 0
	mem_Atual: .int 0
	
	count: .int 0

	#=== Variáveis para o Calloc ===#
	
	num_alocs: .int 0
	tam_alocs: .int 0
	cal_total: .int 0
	
	#==== VAriaveis Realloc ====#
	
	dados: .int 0
	
	#=== Constantes ===#

	.equ TAM_CABECALHO, 8
	.equ BRK, 45
	.equ LINUX_SYSCALL, 0x80
	.equ DISPONIVEL , 1
	.equ INDISPONIVEL , 0


	#=== Strings ===#
	str: .string "Verificando espaço...\n"
	str_Inicio: .string "\nInicio heap: %p \n"	
	str_Fim: .string "Fim heap: %p \n"
	str_Livre: .string "Segmento %d: %d bytes livres\n"
	str_Ocupado: .string "Segmento %d: %d bytes ocupados\n"
	livres: .string "Segmentos Livres: %d/%d bytes\n\n"
	ocupados: .string "Segmentos Ocupados: %d/%d bytes\n"
	str_Aviso: .string "Não foi alocado nada ainda!!!\n"


	#==== Strings fragmentação Lucas ====#	
	str_fragmentationfree: .string " * "
	str_fragmentationfull: .string " - "
	str_pula: .string "\n"
	str_address: .string "%p"
	Aviso: .string "Não existe epaços alocados na pilha!\n"


	tmp: .int 0
	cont: .int 0
	cont_ocupado: .int 0
	cont_vazio: .int 0
	address: .int 0 
	vetor: .int 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


##############################################################################################################################
#Função de Malloc!
##############################################################################################################################
.section .text
.globl aloca
.type aloca ,@function

primeiro_aloca:							#Serve para guardar o inicio da heap na primeira vez que é executado o aloca
	pushl %ebp
	movl %esp , %ebp

	movl $BRK,%eax
	movl $0,%ebx 						#Retorna posição do último endereço válido em eax.	
	int $LINUX_SYSCALL

	incl %eax							#Incrementa em 1 o valor em eax, retornando o primeiro endereço da heap.
								

	movl %eax , inicio_Heap
	movl %eax , pos_Corrente

	movl %ebp , %esp
	popl %ebp
	jmp continua

aloca:

	pushl %ebp
	movl %esp , %ebp
		
	cmpl $0, inicio_Heap				#Verifica se é a primeira vez que chama a função no programa.
	je primeiro_aloca
	jmp continua


continua:

	movl inicio_Heap ,%eax
	movl pos_Corrente ,%ebx
	movl 8(%ebp),%edx
	
	jmp verifica_para_alocar


verifica_para_alocar:
	cmpl %eax, %ebx						#Se a pos. corrente for igual ao endereço de procura precisa de mais memória!
	je mais_memoria

	movl 4(%eax) , %ecx					#Pega o tamanho do bloco.


	cmpl $INDISPONIVEL,0(%eax)			#Se o espaço não esta disponível, verifica próximo endereço.
	je proximo_endereco
	
	pushl %ecx							#Salva o %ecx para realizar um calculo de tamanho do bloco.
	subl $16, %ecx						#Subtrai 16 de %ecx pois 16 é o tamanho de dois cabeçalhos que devem ser adicionados caso va alocar.
		
	cmpl %ecx, %edx						#Se o tamanho a ser alocado for menor que o espaço disponivel, aloca!	
	jl alocar_menor

	
	popl %ecx							#Retorna o %ecx para o valor anterior.

	
	cmpl %ecx, %edx						#Se o tamanho a ser alocado for igual ao espaço disponivel, aloca!
	je alocar_igual

	jmp proximo_endereco				#Se o espaço não for suficiente, vai para o proximo endereço.


mais_memoria:

	addl $TAM_CABECALHO, %ebx			#Adiciona o espaço para o primeiro cabeçalho. 
	addl %edx, %ebx						#Adiciona o tamanho do bloco para controle do brk.
	addl $TAM_CABECALHO, %ebx			#Adiciona o espaço para o segundo cabeçalho.

	pushl %eax							#Empilha os valores para utilizar os registradores sem perder os dados.
	pushl %ebx
	pushl %edx

	movl $BRK, %eax
	int $LINUX_SYSCALL					#Caso ebx seja igual a 0, retorna 0 em eax (Erro).  
	cmpl $0, %eax
	je deu_erro

	popl %edx							#Restaura os valores dos registradores.
	popl %ebx
	popl %eax


	movl $INDISPONIVEL, 0(%eax)			#Monta o primeiro cabeçalho.
	movl %edx, 4(%eax)

	addl $TAM_CABECALHO, %eax			#eax contém o endereço da memória localizada após o cabeçalho.
	

	movl $INDISPONIVEL, -8(%ebx)			#Monta o segundo cabeçalho.
	movl %edx, -4(%ebx)

	
	movl %ebx, pos_Corrente
	
	movl %ebp , %esp
	popl %ebp

	ret


deu_erro:

	movl $0,%eax						#No erro retorna-se 0

	movl %ebp , %esp
	popl %ebp
	ret


proximo_endereco:

	addl $TAM_CABECALHO, %eax			#Próximo endereço para verificação é o cabeçalho + tamanho do bloco
	addl %ecx,%eax                  
	addl $TAM_CABECALHO, %eax

	jmp verifica_para_alocar
	
	


alocar_menor:
	
	movl $INDISPONIVEL, 0(%eax)			#Muda para indisponivel no primeiro cabeçalho do primeiro bloco.
	movl %edx, 4(%eax)
	addl $TAM_CABECALHO, %eax

	addl %edx, %eax						#Caminha para o segundo cabeçalho do primeiro bloco.	
	movl $INDISPONIVEL, 0(%eax)    		#Muda para indisponivel no segundo cabeçalho do bloco alocado.
	movl %edx, 4(%eax)					#Move tamanho do bloco para o cab.
	addl $TAM_CABECALHO, %eax	

	subl %edx, %ecx			
	#subl $16, %ecx						#Calcula tamanho do bloco que sobrou (-) o espaço para os cabeçalhos.
	movl $DISPONIVEL, 0(%eax)			#Coloca o espaço como disponivel no primeiro cabeçalho.
	movl %ecx, 4(%eax)					#Salva tamanho do bloco restante.
	addl $TAM_CABECALHO, %eax	
	
	movl %eax, %ebx
	
	addl %ecx, %ebx						#Caminha para o segundo cabeçalho do segundo bloco.
	
	movl $DISPONIVEL, 0(%ebx)	
	movl %ecx, 4(%ebx)
	addl $TAM_CABECALHO, %ebx			#Posição correta após o cabeçalho.
	
	movl %ebp , %esp
	popl %ebp
	ret


alocar_igual:

	movl $INDISPONIVEL, 0(%eax)			#Atualiza primeiro cabeçalho.
	addl $TAM_CABECALHO, %eax
	
	movl %eax, %ebx
	addl %ecx, %ebx						#Caminha até o segundo cabeçalho.

	movl $INDISPONIVEL, 0(%ebx)			#Atualiza segundo cabeçalho.
	addl $TAM_CABECALHO, %ebx


	movl %ebp, %esp
	popl %ebp
	ret


##############################################################################################################################
#Função de liberar memória!

.globl libera_memoria
.type libera_memoria ,@function	

libera_memoria:
	pushl %ebp
	movl %esp , %ebp

	movl 8(%ebp),%eax
	
	cmpl $0, %eax
	je fim
	
	movl $DISPONIVEL , -8(%eax)     	#Muda para disponivel no primeiro cabeçalho.
    movl -4(%eax), %ebx					#Move o tamanho do bloco para ebx usado para o retorno.

   	addl %ebx, %eax		 				#Soma o valor de eax com o tamanho do bloco para chegar no segundo cabeçalho.
	movl $DISPONIVEL, 0(%eax)	 		#Muda para disponivel no segundo cabeçalho.
	
	addl $TAM_CABECALHO, %eax			#Final do segundo cabeçalho.
	movl %eax, %ebx


	cmpl pos_Corrente, %ebx				#Verifica se é o ultimo bloco da heap.
	je del_bloco_verif					#---Caso verdadeira vai para a função que deleta o ultimo bloco.

	#jmp init_verifica_mem				#---Caso falso Organiza a memória.
	
	movl %ebp , %esp
	popl %ebp
	ret
	
del_bloco_verif:						#tentando deletar os blocos livres no final da memoria.
	cmpl inicio_Heap, %eax				#Verifica se é o primeiro bloco para terminar o del_bloc.
	je fim
	
	subl $TAM_CABECALHO, %eax	
	cmpl $DISPONIVEL, 0(%eax)			#Verifica se esta disponivel para excluir o bloco.
	je del_bloco
	
	#jmp init_verifica_mem
	
	movl %ebp, %esp
	popl %ebp
	ret

del_bloco:
	movl 4(%eax), %ecx
	movl $0, 4(%eax)
	subl %ecx, %eax
	subl $TAM_CABECALHO, %eax
	movl $0, 4(%eax)
	movl %eax, pos_Corrente				#Depois de deletar o ultimo bloco a pos_Corrente é atualizada.

	movl pos_Corrente, %ebx		


	pushl %eax							#Empilha os valores para utilizar os registradores sem perder os dados.
	pushl %ebx
	pushl %edx

	movl $BRK, %eax
	int $LINUX_SYSCALL					#Puxa a BRK para a posição corrente.
	  
	cmpl $0, %eax
	je deu_erro

	popl %edx							#Restaura os valores dos registradores.
	popl %ebx
	popl %eax
	
	jmp del_bloco_verif

	movl %ebp , %esp
	popl %ebp

	ret
	
init_verifica_mem:						#Inicia da verificação para organização da heap
	
	movl inicio_Heap, %eax
	
	movl 4(%eax), %ecx
	movl %eax, %ebx
	
	cmpl $DISPONIVEL, 0(%ebx)	
	je proximo_bloco_Dis

	jmp proximo_bloco_Ind
	
proximo_bloco_Dis:						#Se o bloco anterior estiver livre.
	
	
	addl $TAM_CABECALHO, %ebx
	
		
	addl %ecx, %ebx
	addl $TAM_CABECALHO, %ebx			#Primeira posição após o segundo cabeçalho.
	
	movl 4(%ebx), %edx
	cmpl $DISPONIVEL, 0(%ebx)			#Se o proximo bloco tambem estiver disponivel vai para o org_mem que espande os dois blocos para virar apenas um.
	je org_mem
	
		
	movl %edx, %ecx              		#Caso esteja indisponivel, continua andando pela memoria para verificar se há mais algum espaço para arrumar.
	jmp proximo_bloco_Ind
	

proximo_bloco_Ind:						#Se o bloco  estiver indisponivel.
	
	addl $TAM_CABECALHO, %ebx
	addl %ecx, %ebx
	addl $TAM_CABECALHO, %ebx
	
	cmpl %ebx, pos_Corrente					#caso a posição corrente ele retorna.
	je fim
	
	movl 4(%ebx), %ecx
	#movl %edx, %ecx						#POOHAAAAA --------->>>>>>>>>
	cmpl $DISPONIVEL, 0(%ebx)			#Se o proximo bloco esta disponivel entra no proximo_bloco_dis para verificar o posterior.
	je proximo_bloco_Dis
	 
	jmp proximo_bloco_Ind 
	

org_mem:
		
	#addl $TAM_CABECALHO, %ebx
	addl %edx, %ebx
	
	addl %edx, %ecx
	addl $16, %ecx						#tamanho do 1ºbloco + 16 bytes dos dois cabeçalhos do meio + tamanho do 2º bloco.
	
	movl %ecx, 4(%ebx)
	movl %ecx, %edx
	addl $TAM_CABECALHO, %ebx
	
	cmpl $DISPONIVEL, 0(%ebx)
	je org_mem
	
	subl $TAM_CABECALHO, %ebx
	subl %ecx, %ebx
	movl %ecx, -4(%ebx)
	
	jmp proximo_bloco_Ind
	
	movl %ebp , %esp
	popl %ebp
	ret
	
fim:
		
	movl %ebp , %esp
	popl %ebp
	ret
	
	
#############################################################################################################################
#Função Calloc!!!
#############################################################################################################################
.globl meuCalloc
.type meuCalloc, @function

primeiro_calloc:
	pushl %ebp
	movl %esp , %ebp

	movl $BRK,%eax
	movl $0,%ebx 						#Retorna posição do último endereço válido em eax.	
	int $LINUX_SYSCALL

	incl %eax							#Incrementa em 1 o valor em eax, retornando o primeiro endereço da heap.
								
	movl %eax , inicio_Heap
	movl %eax , pos_Corrente

	movl %ebp , %esp
	popl %ebp
	
	jmp continua_calloc

meuCalloc: 								#Função inicia parecida com o meuAloca, caso seja a primeira alocação de memoria vai para o primeiro calloc.
	pushl %ebp	
	movl %esp, %ebp
	
	movl 8(%ebp), %eax
	movl %eax, num_alocs
	movl 12(%ebp), %edx
	movl %edx, tam_alocs
	
	cmpl $0, %edx
	je fim_calloc
		
	cmpl $0, inicio_Heap
	je primeiro_calloc
	
	jmp continua_calloc
	

continua_calloc:
	movl inicio_Heap ,%eax
	movl pos_Corrente ,%ebx
	
	
	movl num_alocs, %ecx
	subl $1, %ecx
	imul $16, %ecx
	imul num_alocs, %edx 				#Calculo para ver o tamanho total do bloco.
	addl %ecx, %edx
	
	movl %edx, cal_total
	
	jmp verifica_calloc
	
verifica_calloc:
	cmpl %eax, %ebx						#Se a pos. corrente for igual ao endereço de procura precisa de mais memória!
	je mais_mem_calloc

	movl 4(%eax), %ecx					#Pega o tamanho do bloco.

	cmpl $INDISPONIVEL, 0(%eax)			#Se o espaço não esta disponível, verifica próximo endereço.
	je proximo_end_calloc
	
	pushl %ecx
	subl $16, %ecx
	
	cmpl %ecx, %edx						#Se o tamanho de todos os blocos for menor, aloca!
	jl verif_calloc_menor

	popl %ecx
	
	cmpl %ecx, %edx						#Se o tamanho a ser alocado for igual ao espaço disponivel, aloca!
	je verif_calloc_igual
	
	jmp proximo_end_calloc
	
mais_mem_calloc:
	addl $TAM_CABECALHO, %ebx			#Adiciona o espaço para o primeiro cabeçalho. 
	addl %edx, %ebx						#Adiciona o tamanho do bloco para controle do brk.

	
	pushl %eax							#Empilha os valores para utilizar os registradores sem perder os dados.
	pushl %ebx
	pushl %edx

	movl $BRK, %eax
	int $LINUX_SYSCALL					#Caso ebx seja igual a 0, retorna 0 em eax (Erro).  
	cmpl $0, %eax
	je deu_erro

	popl %edx							#Restaura os valores dos registradores.
	popl %ebx
	popl %eax
	
	pushl %ecx
	
	movl $0, %ecx
	movl tam_alocs, %edx
	
	jmp calloc_aqui

calloc_aqui:
	addl $1, %ecx
	
	movl $INDISPONIVEL, 0(%eax)			#Monta o primeiro cabeçalho.
	movl %edx, 4(%eax)
	addl $TAM_CABECALHO, %eax			#eax contém o endereço da memória localizada após o cabeçalho.
	addl %edx, %eax

	movl $INDISPONIVEL, 0(%eax)			#Monta o segundo cabeçalho.
	movl %edx, 4(%eax)
	addl $TAM_CABECALHO, %eax
	
	cmpl num_alocs, %ecx				#Se o ainda não terminou de alocar todos os blocos continua alocando.
	jl calloc_aqui
	
	popl %ecx
	
	addl $TAM_CABECALHO, %ebx			#Posição corrente correta após segundo cabeçalho.
	movl %ebx, pos_Corrente
      
	movl %ebx, %eax
	subl $TAM_CABECALHO, %eax
	subl cal_total, %eax				#Endereço de retorno da função calloc.
	
	movl $0, %ebx
	
	jmp verifica_zera_mem				#Coloca 0 nos espaços alocados.
	
	
proximo_end_calloc:

	addl $TAM_CABECALHO, %eax			#Próximo endereço para verificação é o cabeçalho + tamanho do bloco
	addl %ecx,%eax                  
	addl $TAM_CABECALHO, %eax

	jmp verifica_calloc
	
verif_calloc_menor:
	movl tam_alocs, %edx				#Arruma os registradores para o callocar um espaço menor do que o presente no bloco livre.
	pushl %ebx
    movl $0, %ebx
	
	jmp calloc_menor
	
calloc_menor:
	addl $1, %ebx						#Incrementa o contador de segmentos.
	movl $INDISPONIVEL, 0(%eax)		
	movl %edx, 4(%eax)
	
	addl $TAM_CABECALHO, %eax		
	addl %edx, %eax
	movl $INDISPONIVEL, 0(%eax)
	movl %edx, 4(%eax)
	addl $TAM_CABECALHO, %eax			#%eax possui o endereço do incio do proximo bloco.
	
	cmpl num_alocs, %ebx
	jl calloc_menor

	popl %ebx
		
	movl cal_total, %edx			
	pushl %ecx
	subl %edx, %ecx						#Calcula o tamanho do bloco restante.

	movl $DISPONIVEL, 0(%eax)		
	movl %ecx, 4(%eax)	
	addl $TAM_CABECALHO, %eax

	movl %eax, %ebx
	
	addl %ecx, %ebx						#Caminha para o segundo cabeçalho do segundo bloco.
	
	movl $DISPONIVEL, 0(%ebx)	
	movl %ecx, 4(%ebx)
	addl $TAM_CABECALHO, %ebx
	
	subl $16, %eax	
	subl cal_total, %eax				#Endereço de retorno da função, que é o primeiro bloco allocado.

	movl $0, %ebx
	
	jmp verifica_zera_mem

	
	
verif_calloc_igual:
	movl tam_alocs, %edx				#Arruma os registradores para allocar uma quantia de bloco em que a soma da igual ao tamanho do bloco livre.
	pushl %ebx
    movl $0, %ebx
    	
    jmp calloc_igual
    	
calloc_igual:
	addl $1, %ebx
	movl $INDISPONIVEL, 0(%eax)
	movl %edx, 4(%eax)
	
	addl $TAM_CABECALHO, %eax
	addl %edx, %eax
	movl $INDISPONIVEL, 0(%eax)			#Monta o segundo cabeçalho.
	movl %edx, 4(%eax)	
	addl $TAM_CABECALHO, %eax			#Posição, no primeiro cabeçalho do bloco seguinte.
	
	cmpl num_alocs, %ebx
	jl calloc_igual
	
	
	subl $TAM_CABECALHO, %eax
	subl cal_total, %eax
	
	movl $0, %ebx
	
	jmp verifica_zera_mem

verifica_zera_mem:
	movl $0, %ecx
	addl $1, %ebx
	
	jmp zera_mem


zera_mem:								#Zera todas as posições de memoria do calloc.
	movl $0, 0(%eax)
	addl $1, %eax
	addl $1, %ecx
	
	
	cmpl tam_alocs, %ecx
	jl zera_mem
	
	addl $16, %eax
	
	cmpl num_alocs, %ebx
	jl verifica_zera_mem
	
	subl $16, %eax
	
	subl cal_total, %eax				#Endereço de retorno da função com as posições de memoria alocada zerados.
		
	
	movl %ebp, %esp
	popl %ebp
	ret

fim_calloc:
	movl $0, %eax						#Caso de erro, move 0 para o registrador de retorno e sai.
	movl %ebp, %esp
	popl %ebp
	ret
	
	
##############################################################################################################################
#Fragmentação LUCAS

.globl imprime_fragmentacao
.type imprime_fragmentacao ,@function

imprime_fragmentacao:

	pushl %ebp
	movl %esp, %ebp

	movl inicio_Heap, %eax
	movl pos_Corrente, %ebx

	cmpl %eax, %ebx
	je imprAviso 

	movl %ebx, address
	pushl address
	pushl $str_address
	call printf
	addl $8, %esp

	jmp while

continua_fragmentacao:

	movl -4(%ebx), %ecx
	subl $TAM_CABECALHO, %ebx
	subl %ecx, %ebx

	movl inicio_Heap, %eax
	addl $TAM_CABECALHO, %eax

	cmpl  %eax, %ebx
	je acabou

	subl $TAM_CABECALHO, %ebx

	jmp while

while:

	movl -8(%ebx), %ecx
	cmpl $DISPONIVEL, %ecx
	je if_vazio

        jmp if_ocupado

if_vazio:

	pushl $str_fragmentationfree

	call printf
	addl $4, %esp

	addl $1, cont
	addl $1, cont_vazio

	cmpl $50, cont
	je reset_cont_vazio

	movl -4(%ebx), %ecx

	cmpl %ecx, cont_vazio
	jl if_vazio

	movl $0, cont_vazio

	jmp continua_fragmentacao

if_ocupado:

	pushl $str_fragmentationfull

	call printf
	addl $4, %esp

	addl $1, cont
	addl $1, cont_ocupado

	cmpl $50, cont
	je reset_cont_ocupado

	movl -4(%ebx), %ecx

	cmpl %ecx, cont_ocupado
	jl if_ocupado

	movl $0, cont_ocupado

	jmp continua_fragmentacao

reset_cont_ocupado:

	movl $0, cont
	pushl $str_pula
	call printf
	addl $4, %esp

	subl $TAM_CABECALHO, %ebx
	movl cont_ocupado, %edx
	subl %edx, %ebx

	movl %ebx, address
	pushl address
	pushl $str_address
	call printf
	addl $8, %esp

	movl cont_ocupado, %edx
	addl %edx, %ebx
	addl $TAM_CABECALHO, %ebx

	jmp if_ocupado

reset_cont_vazio:

	movl $0, cont
	pushl $str_pula
	call printf
	addl $4, %esp

	subl $TAM_CABECALHO, %ebx
	movl cont_vazio, %edx
	subl %edx, %ebx

	movl %ebx, address
	pushl address
	pushl $str_address
	call printf
	addl $8, %esp

	movl cont_vazio, %edx
	addl %edx, %ebx
	addl $TAM_CABECALHO, %ebx

	jmp if_vazio

imprAviso:

	pushl $Aviso
	call printf
	addl $4, %esp

	movl %ebp, %esp
	popl %ebp
	ret

acabou:

	#pushl $str_pula
	#call printf
	#addl $4, %esp

	movl %ebp, %esp
	popl %ebp
	ret



##############################################################################################################################
#Função Realloc
.globl meuRealloc
.type meuRealloc ,@function


meuRealloc:

	pushl %ebp
	movl %esp, %ebp

	movl 8(%ebp), %eax                 		#Passa o ponteiro para %eax.
	movl 12(%ebp), %edx               		#Passa o valor a ser reallocado para %edx. 
	
	cmpl $DISPONIVEL, -8(%eax)            	#Verifica se esta disponivel.
	je fim_realloca                     

	cmpl $0, %edx							#Se o tamanho para ser reallocado for igual a zero, libera o bloco da memoria.
	je realloca_free

	movl -4(%eax), %ecx                		#Passa o valor alocado para %ecx.
	movl %ecx, dados
	
	pushl %ecx
	
	subl $16, %ecx							#Subtrai o valor de ecx em 16 por causa dos cabeçalhos adicionais para uma alocação menor que o tamanho do bloco existente.

	cmpl %ecx, %edx                   		#verifica se o tamanho do bloco é suficiente para o tamanho desejado.
	jl realloca_menor

	popl %ecx
	
	cmpl %ecx, %edx							#Se o tamanho para ser reallocado for igual ao do ponteiro, só retorna para o chamador.
	je fim_realloca
	
	movl %eax, %ebx
	movl $DISPONIVEL, -8(%ebx)				#Libera o bloco passado como parametro da chamada.
	addl %ecx, %ebx
	movl $DISPONIVEL, 0(%ebx)
	addl $TAM_CABECALHO, %ebx
	
	pushl %eax
	
	subl $TAM_CABECALHO, %eax				
	cmpl inicio_Heap, %eax					#Caso seja algum lugar no meio da heap ou no final volta para o inicio para achar um lugar para alocar.
	jne volta_proinicio
	
	popl %eax
	
	jmp ver_prox_disp_tam					#Caso o tamanho desejado for maior que o tamanho do bloco atual verificara os proximos blocos na heap.

	movl %ebp , %esp
	popl %ebp
	ret

volta_proinicio:
	movl inicio_Heap, %eax					#Volta para o inicio da heap para alocar o bloco de preferencia nos primeiros segmentos da heap.
	addl $TAM_CABECALHO, %eax
	
	cmpl $INDISPONIVEL, -8(%eax)
	je while_ver_bloco
	
	movl -4(%eax), %ecx
	
	pushl %ecx
	
	subl $16, %ecx
	
	cmpl %ecx, %edx
	jl realloca_menor						#Se estiver disponivel e o bloco livre for maior aloca aqui.
	
	popl %ecx
	
	cmpl %ecx, %edx
	je realloc_aqui							#Se o bloco livre for do mesmo tamanho aloca aqui.
		
	jmp while_ver_bloco						#Se estiver livre mas o bloco for menor vai buscar pra frente.
	
realloc_aqui:
	movl $INDISPONIVEL, -8(%eax)
	movl %eax, %ebx
	
	addl %ecx, %ebx
	movl $INDISPONIVEL, 0(%ebx)
	
	jmp fim_realloca
	
	
ver_prox_disp_tam:
  
	addl %ecx, %eax							#Caminha para o final do bloco, posição atual: inicio do segundo cabeçalho.
	addl $16, %eax							#Posição atual: primeiro espaço do bloco usavel.

	cmpl $INDISPONIVEL, -8(%eax)			#Verifica se o bloco atual esta indisponivel.
	je while_ver_bloco

	movl %ecx, %ebx
	movl -4(%eax), %ecx						#Pega o tamanho do bloco atual para calculos.
	
	addl %ebx, %ecx
	addl $16, %ecx
	
	subl $16, %eax
	subl %ebx, %eax							#Posição atual: endereço de retorno atual da chamada.
	
	movl %ecx, -4(%eax)
	
	movl %eax, %ebx
	addl %ecx, %ebx
	addl $TAM_CABECALHO, %ebx
	movl %ecx, -4(%ebx)
	
	pushl %ecx
	
	subl $16, %ecx
	
	cmpl %ecx, %edx                       	#Compara se o bloco disponivel é maior que o tamanho a ser realocado.
	jl realloca_menor
	
	popl %ecx
	
	jmp while_ver_bloco
  
	
	movl %ebp , %esp
	popl %ebp
	ret

while_ver_bloco:

	movl -4(%eax), %ecx						#Pega o tamanho do bloco atual.
	addl %ecx, %eax							#Caminha até o segundo cabeçalho.		
	addl $TAM_CABECALHO, %eax				#Posição atual: final do segundo cabeçalho.
	
	cmpl pos_Corrente, %eax					#Se a posição atual for igual ao final da heap aloca mais memoria.
	je mais_mem_realloca
	
	addl $TAM_CABECALHO, %eax				#Caso não seja o final da heap passa para o final do cabeçalho seguinte.

	movl -4(%eax), %ecx
	cmpl $INDISPONIVEL, -8(%eax)			#Verifica se o bloco atual esta indisponivel.
	je while_ver_bloco

	pushl %ecx
	
	subl $16, %ecx

	cmpl %ecx, %edx							#Se disponivel, verifica o tamanho do bloco para ver se é possivel alocar aqui.
	jl realloca_menor

	popl %ecx
	
	jmp while_ver_bloco
	


realloca_menor:
	
	movl -4(%eax), %ecx					#Pega o tamanho do bloco anterior para calcular o tamanho do restante para montar os cabeçalhos.
	movl %edx, -4(%eax)					#Coloca o novo tamanho no cabecaçalho
	movl $INDISPONIVEL, -8(%eax)
	
	movl %eax, %ebx                    
	addl %edx, %ebx                    	#Soma para alocar o novo tamanho

	addl $TAM_CABECALHO, %ebx          	
	movl $INDISPONIVEL, -8(%ebx)
	movl %edx, -4(%ebx)					#Segundo cabeçalho montado com os novo valores.

	jmp aloca_vazio

aloca_vazio:

	addl $TAM_CABECALHO, %ebx			#Vai para o primeiro cabeçalho do bloco restante.
	
	subl %edx, %ecx						
	subl $16, %ecx						#Calcula o tamanho do espaço restante.
	movl %ecx, -4(%ebx)					
	movl $DISPONIVEL, -8(%ebx)			#Monta o primeiro cabeçalho do bloco restante.

	addl %ecx, %ebx						#Caminha até o segundo cabeçalho.
	addl $TAM_CABECALHO, %ebx
  	movl %ecx, -4(%ebx)
	movl $DISPONIVEL, -8(%ebx)			#Termina o segundo cabeçalho.
	
	jmp comeca_move_dados
	
	movl %ebp , %esp
	popl %ebp
	ret


mais_mem_realloca:	

	movl pos_Corrente, %ebx
	addl $TAM_CABECALHO, %ebx			#Adiciona o espaço para o primeiro cabeçalho. 
	addl %edx, %ebx						#Adiciona o tamanho do bloco para controle do brk.
	addl $TAM_CABECALHO, %ebx			#Adiciona o espaço para o segundo cabeçalho.

	pushl %eax							#Empilha os valores para utilizar os registradores sem perder os dados.
	pushl %ebx
	pushl %edx

	movl $BRK, %eax
	int $LINUX_SYSCALL					#Caso ebx seja igual a 0, retorna 0 em eax (Erro).  
	cmpl $0, %eax
	je deu_erro

	popl %edx							#Restaura os valores dos registradores.
	popl %ebx
	popl %eax

	movl $INDISPONIVEL, 0(%eax)			#Monta o primeiro cabeçalho.
	movl %edx, 4(%eax)

	addl $TAM_CABECALHO, %eax			#eax contém o endereço da memória localizada após o cabeçalho.
	

	movl $INDISPONIVEL, -8(%ebx)		#Monta o segundo cabeçalho.
	movl %edx, -4(%ebx)

	movl %ebx, pos_Corrente
	
	jmp comeca_move_dados
	
	movl %ebp , %esp
	popl %ebp

	ret
	
comeca_move_dados:
	
	movl %eax, %ebx
	movl 8(%ebp), %eax
	 	
	movl %eax, %ecx
	addl dados, %ecx
	
	jmp move_dados

move_dados:
	
	movl (%eax), %edx
	movl %edx, (%ebx)
	
	incl %eax
	incl %ebx
	
	cmpl %ecx, %eax
	jle move_dados
	
	jmp fim_realloca
	  
		
realloca_free:

	movl $DISPONIVEL , -8(%eax)     	#Muda para disponivel no primeiro cabeçalho.
    movl -4(%eax), %ecx				 	#Move o tamanho do bloco para ebx usado para o retorno.

    addl %ecx, %eax		 			 	#Soma o valor de eax com o tamanho do bloco para chegar no segundo cabeçalho.
	movl $DISPONIVEL, 0(%eax)		 	#Muda para disponivel no segundo cabeçalho.
	
	addl $TAM_CABECALHO, %eax		 	#Final do segundo cabeçalho.


	movl %ebp, %esp
	popl %ebp
	ret

fim_realloca:

	movl %ebp , %esp
	popl %ebp
	ret
	
	
##############################################################################################################################
#Função que imprime um mapa!!
.globl imprMapa
.type imprMapa ,@function	

imprMapa:
	pushl %ebp
	movl %esp , %ebp

	movl inicio_Heap ,%eax
	movl pos_Corrente ,%ebx 

	cmpl %eax, %ebx					#Caso não tenha usado o aloca ou a memória foi liberada por completo imprime a string de nao uso.
	je nao_usou_aloca

	pushl inicio_Heap				#Imprime o inicio da heap começando o mapa.
	pushl $str_Inicio
	call printf
	addl $8,%esp

	pushl pos_Corrente				#Imprime a posição corrente = BRK.
	pushl $str_Fim
	call printf
	addl $8, %esp
	
	movl $1,%eax 					#Contador de segmentos.
	movl inicio_Heap,%ebx

	jmp analisando_mapa

analisando_mapa:

	pushl 4(%ebx)  					#Empilha o tamanho do bloco.
	pushl %eax     					#Empilha o contador de segmentos.

	cmpl $INDISPONIVEL,0(%ebx)		#Verifica se o bloco esta ocupado ou não para imprimir a string correspondente.
	je imprime_ocupado
	
	jmp imprime_livre 

continua_mapa:
	popl %eax
	popl 4(%ebx)

	movl %ebx,%ecx

	addl $TAM_CABECALHO,%ecx		#Caminha na memória para  acessar o proximo bloco para verificação.
	addl 4(%ebx),%ecx
	addl $TAM_CABECALHO,%ecx

	movl %ecx,%ebx
	
	cmpl pos_Corrente, %ebx			#Se a posição atual for igual a corrente termina o mapa.
	je terminando_mapa

	addl $1,%eax					#Incrementa o contador de segmentos, e continua o mapa.
	jmp analisando_mapa

imprime_ocupado:
	movl total_Ocupado,%edx
	movl segmentos_Ocupados,%ecx

	addl 4(%ebx),%edx
	addl $1,%ecx

	movl %edx,total_Ocupado
	movl %ecx,segmentos_Ocupados

	pushl $str_Ocupado				
	call printf         			# Demais parâmetros empilhados em analisando mapa.
	addl $4,%esp        

	jmp continua_mapa

imprime_livre:
	movl total_Livre,%edx
	movl segmentos_Livres,%ecx
	addl 4(%ebx),%edx	
	addl $1,%ecx

	movl %edx,total_Livre
	movl %ecx,segmentos_Livres

	pushl $str_Livre	
	call printf						# Demais parâmetros empilhados em analisando mapa.
	addl $4,%esp
	
	jmp continua_mapa

terminando_mapa:
	pushl total_Ocupado
	pushl segmentos_Ocupados
	pushl $ocupados

	call printf
	addl $12,%esp					#Imprime o número de bytes ocupados e quantos segmentos estão ocupados.

	pushl total_Livre
	pushl segmentos_Livres
	pushl $livres

	call printf
	addl $12,%esp					#Imprime o total de bytes livres e quantos blocos estão livres.
	
	movl $0,total_Livre
	movl $0,segmentos_Livres
	movl $0,total_Ocupado
	movl $0,segmentos_Ocupados		#Zera as variaveis para uso posterior se necessario.

	movl %ebp , %esp
	popl %ebp
	ret

nao_usou_aloca:
	pushl $str_Aviso				
	call printf
	
	movl %ebp , %esp
	popl %ebp
	ret



###################################################################################
#DESFRAGMENTAÇÂO
.globl desfrag
.type desfrag, @function

desfrag:
  
	movl pos_Corrente, %ebx
	movl inicio_Heap, %eax
	movl $0, %edi

	jmp while_frag

while_frag:
    
	addl $TAM_CABECALHO, %eax
	movl -4(%eax), %ecx
	addl %ecx, %eax
	addl $TAM_CABECALHO, %eax

	movl -8(%eax), %ecx

	cmpl $DISPONIVEL, %ecx
	je while_frag

	movl -4(%eax), %ecx

	movl %ecx, vetor(,%edi,4)
	addl $1, %edi

	cmpl %ebx, %eax
	je acabou

	jmp while_frag

imprfrag:

	movl pos_Corrente, %ebx
	movl inicio_Heap, %eax

	movl $0, %edi

	jmp while_imprfrag


while_imprfrag:

	movl vetor(,%edi,4), %ecx
	addl $1, %edi

	cmpl $0, %ecx
	je imprime_de_novo

	addl $TAM_CABECALHO, %eax
	movl $INDISPONIVEL, -8(%eax)
	movl %ecx, -4(%eax)
	addl %ecx, %eax
	addl $TAM_CABECALHO, %eax
	movl $INDISPONIVEL, -8(%eax)
	movl %ecx, -4(%eax)

	jmp while_imprfrag

	
imprime_de_novo:

	movl %eax, pos_Corrente
	movl pos_Corrente, %ebx
	movl inicio_Heap, %eax

	movl $0, cont

	pushl $str_pula
	call printf
	addl $4, %esp

	pushl $str_pula
	call printf
	addl $4, %esp

	movl %ebx, address
	pushl address
	pushl $str_address
	call printf
	addl $8, %esp

	jmp ocupado


while_impr_de_novo:

	movl -4(%ebx), %ecx
	subl $TAM_CABECALHO, %ebx
	subl %ecx, %ebx

	movl inicio_Heap, %eax
	addl $TAM_CABECALHO, %eax

	cmpl  %eax, %ebx
	je acabou

	subl $TAM_CABECALHO, %ebx

	jmp ocupado
	

ocupado:

	pushl $str_fragmentationfull

	call printf
	addl $4, %esp

	addl $1, cont
	addl $1, cont_ocupado

	cmpl $20, cont
	je reset_ocupado

	movl -4(%ebx), %ecx

	cmpl %ecx, cont_ocupado
	jl ocupado

	movl $0, cont_ocupado

	jmp while_impr_de_novo

reset_ocupado:

	movl $0, cont
	pushl $str_pula
	call printf
	addl $4, %esp

	subl $TAM_CABECALHO, %ebx
	movl cont_ocupado, %edx
	subl %edx, %ebx

	movl %ebx, address
	pushl address
	pushl $str_address
	call printf
	addl $8, %esp

	movl cont_ocupado, %edx
	addl %edx, %ebx
	addl $TAM_CABECALHO, %ebx

	jmp ocupado


