; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Merge 2                                    ;
;                                                                           ;
; ************************************************************************* ;

; void ASM_merge2(uint32_t w, uint32_t h, uint8_t* data1, uint8_t* data2, float value)

global ASM_merge2


;value--> xmm0

section .data
mask_ordenar: db 0x00, 0x04,0x08, 0x0c, 0x01, 0x05, 0x09, 0x0d, 0x02,0x06, 0x0a, 0x0e, 0x03, 0x07, 0x0b, 0x0f
mask_shuf: db  0x00, 0x01,0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00,0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01
v256: dd 256.0, 0.0, 0.0, 0.0

section .text


ASM_merge2:
	push rbp
	mov  rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub  rsp, 8


	mov r13, rdx ; r13 = data1
	mov r14, rcx ; r14 = data2



	;limpio parte alta
	mov edi, edi
	mov esi, esi

	mov r12d, edi
	mov r15d, esi
	mov rax, r12
	mul r15
	shr rax, 2
	xor r12, r12
	mov r12, rax

	xorps xmm5, xmm5 ; xmm5=0|0|0|0
	movdqu xmm15, [v256]

	mov r15d, 256
	mulss xmm15, xmm0 ; xmm15=0|0|0|value*256
	cvtss2si ebx, xmm15 ; lo convertimos a enteros de 32 bit ebx=value*256, pero como el numero es menor a 256 lo podemos pensar como un entero de 16 bit
	pxor xmm1, xmm1
	movd xmm1, ebx   ; xmm1= value*256
	sub r15d, ebx
	xorps xmm9, xmm9			 
	movd xmm9, r15d   ; xmm9 = 256 -value*256(entero)

	movdqu xmm14, [mask_shuf]

	pshufb xmm9, xmm14; xmm9 = 256-value*256 | 256-value*256 | 256-value*256 | 256-value*256 | 256-value*256 | 256-value*256 | 256-value*256 | 256-value*256 
	pshufb xmm1, xmm14; xmm1 = value*256 | value*256 | value*256 | value*256 |value*256 | value*256 | value*256 | value*256

	movdqu xmm14, [mask_ordenar]
.ciclo:

	pxor xmm3, xmm3
	movdqu xmm3, [r13]     ;en xmm3 4 pixeles a procesar

	pshufb xmm3, xmm14 ;xmm3= r|r|r|r|g|g|g|g|b|b|b|b|a|a|a|a
	;(*) ojo el nombre de los colores b y r esta invertido(es decir que nos referimos con r al azul y con b al rojo) , pero solo es imporante la posicion de a


	;desempaquetamos
	movdqu xmm4, xmm3      ;xmm4=r|r|r|r|g|g|g|g|b|b|b|b|a|a|a|a
	punpcklbw xmm4, xmm5   ;xmm4 = 0b|0b|0b|0b|0a|0a|0a|0a 8 numeros de 16 bit
	pxor xmm2, xmm2 
	movdqu xmm2, xmm4 
	
	; limpio parte alta de xmm2  
	pslldq xmm2, 8           
	psrldq xmm2, 8 					 ; xmm2 = 0|0|0|0|0a|0a|0a|0a
	
	punpcklwd xmm2, xmm5   ; xmm2= 000a|000a|000a|000a| 8 numeros de 16 bit


	movdqu xmm7, xmm3
	punpckhbw xmm7, xmm5   ; xmm7= 0r|0r|0r|0r|0g|0g|0g|0g| 8 numeros de 16 bit

	movdqu xmm6, xmm7

	;mutiplicamos los enteros de 16 bit de xmm7

	pmullw xmm7, xmm1 ; parte baja de la multiplicacion de xmm7 con xmm1
	pmulhuw xmm6, xmm1 ; parte alta de la multiplicacion de xmm7 con xmm1

	movdqu xmm8, xmm7

	punpcklwd xmm7, xmm6  ;  xmm7= 0g*value*256|0g*value*256|0g*value*256|0g*value*256|
	punpckhwd xmm8, xmm6  ;  xmm8= 0r*value*256|0r*value*256|0r*value*256|0r*value*256

	; tambien multiplicamos a b
	psrldq xmm4, 8      ;xmm4 = 00|00|00|00|0b|0b|0b|0b 8 numeros de 16 bit
	movdqu xmm6, xmm4


	pmullw xmm4, xmm1 ; parte baja de la multiplicacion de xmm4 con xmm1
	pmulhuw xmm6, xmm1 ; parte alta de la multiplicacion de xmm4 con xmm1


	punpcklwd xmm4, xmm6 ; xmm4= 0b*value*256|0b*value*256|0b*value*256|0b*value*256|


	; para la segunda imagen


	pxor xmm10, xmm10
	movdqu xmm10, [r14]     ;en xmm10 4 pixeles a procesar

	pshufb xmm10, xmm14 ;xmm10= r|r|r|r|g|g|g|g|b|b|b|b|a|a|a|a
	;(*) ojo el nombre de los colores b y r esta invertido, pero solo es imporante la posicion de a


	;desempaquetamos
	movdqu xmm11, xmm10     ;xmm11=r|r|r|r|g|g|g|g|b|b|b|b|a|a|a|a
	punpcklbw xmm11, xmm5   ;xmm11 = 0b|0b|0b|0b|0a|0a|0a|0a 8 numeros de 16 bit
	pxor xmm15, xmm15
	movdqu xmm15, xmm11
	
	; limpio parte alta de xmm15  
	pslldq xmm15, 8           
	psrldq xmm15, 8 					 ; xmm15 = 0|0|0|0|0a|0a|0a|0a
	
	punpcklwd xmm15, xmm5   ; xmm15= 000a|000a|000a|000a| 8 numeros de 16 bit


	movdqu xmm12, xmm10
	punpckhbw xmm12, xmm5   ; xmm12= 0r|0r|0r|0r|0g|0g|0g|0g| 8 numeros de 16 bit

	;mutiplicamos los enteros de 16 bit de xmm12
	movdqu xmm6, xmm12
	pmullw xmm12, xmm9 ; parte baja de la multiplicacion de xmm12 con xmm1
	pmulhuw xmm6, xmm9 ; parte alta de la multiplicacion de xmm12 con xmm1

	movdqu xmm13, xmm12

	punpcklwd xmm12, xmm6  ;  xmm12= 0g*value*256|0g*value*256|0g*value*256|0g*value*256|
	punpckhwd xmm13, xmm6  ;  xmm13= 0r*value*256|0r*value*256|0r*value*256|0r*value*256

	; tambien multiplicamos a b
	psrldq xmm11, 8      ;xmm11 = 00|00|00|00|0b|0b|0b|0b 8 numeros de 16 bit
	movdqu xmm6, xmm11


	pmullw xmm11, xmm9 ; parte baja de la multiplicacion de xmm4 con xmm1
	pmulhuw xmm6, xmm9 ; parte alta de la multiplicacion de xmm4 con xmm1


	punpcklwd xmm11, xmm6 ; xmm4= 0b*value*256|0b*value*256|0b*value*256|0b*value*256|


;dividimos por 256 

	psrld xmm4, 8
	psrld xmm7, 8
	psrld xmm8, 8


	psrld xmm11, 8
	psrld xmm12, 8
	psrld xmm13, 8

;sumamos

	paddd xmm4, xmm11
	paddd xmm7, xmm12
	paddd xmm8, xmm13

	


; proceso de empaquetado:

	packusdw xmm2, xmm4
	packusdw xmm7, xmm8
	packuswb xmm2, xmm7
	pshufb xmm2, xmm14


	movdqu [r13], xmm2
	add r13, 16
	add r14, 16
	
	dec r12
	cmp r12, 0
	je .fin
	jmp .ciclo
	
	.fin:

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp

 	ret
