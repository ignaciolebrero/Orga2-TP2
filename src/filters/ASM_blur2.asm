; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Blur 2                                     ;
;                                                                           ;
; ************************************************************************* ;
	extern malloc
	extern free
	%define elimprim 	00000000h
; void ASM_blur2( uint32_t w, uint32_t h, uint8_t* data )
global ASM_blur2
	divs: dd 9.0, 9.0, 9.0, 9.0
	shuf: db 0x00,0x04,0x08,0x0C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	_floor: dd 0x7F80
ASM_blur2:
	push RBP
	mov RBP, RSP
	push RBX
	push R12
	push R13
	push R14
	push R15
	sub rsp, 8
	ldmxcsr [_floor] 	; Algo de redondeo
	mov edi, edi 		; Extiendo ceros
	mov esi, esi 	
	
	; Malloceo memoria temp (push y pop para no perder cosas importantes)
	push rdi
	push rsi
	push rdx
	mov r12d, edi
	mov r13d, esi
	mov rax, r12
	mul r13
	shl rax, 2
	mov rdi, rax
	call malloc
	mov r10, rax  	; r10 puntero a estructura temporal
	pop rdx
	pop rsi
	pop rdi
	
	mov r8, rdi 	; r8 = w 		Copio tamaños para calcular direcciones
	mov r9, rsi 	; r9 = h
	;dec rdi 		; rdi = w-1 : Limite del loop de pixeles en fila
	dec rsi 		; rsi = h-1 : Limite del loop de filas
	mov rbx, 0 		; rbx = 1 : "iw" itera pixeles en fila
	mov rcx, 1 		; rcx = 1 : "ih" itera filas
	movdqu xmm13, [divs] 	; xmm13 = | 9.0 | 9.0 | 9.0 | 9.0 |
	movdqu xmm14, [shuf] 	; Shuffle para pasar dword int a byte int
	pxor xmm15, xmm15			; xmm15 = |0|
	mov r15, rdi 			
	sub r15, 4 				; Limite ultimo pixel w 
	mov r14, rsi 			
	dec r14 				; Limite ultimo pixel h 
							; Al cargar los datos para el ultimo pixel, el pixel "de mas" no existe, sino que es espacio de memoria
							; que no se supone que puedo acceder. R15 y R14 es para detectar cuando llego a esta posicion
	
	;Esto es para saltear el read de la primera fila, ya que accederia a algo que no me corresponde
	movdqu xmm3, [rdx] 		; xmm3 = |d[0][3]|d[0][2]|d[0][1]|d[0][0]|
	pslldq xmm3, 4 	 		; xmm3 = |d[0][2]|d[0][1]|d[0][0]| 	X	 |
	jmp salteoprimerpixel

	loopw:
		movdqu xmm3, [rdx + rbx*4 - 4] 		; xmm3 = |d[0][iw+2]|d[0][iw+1]|d[0][iw]	|d[0][iw-1]	| d son 4 bytes A R G y B
		salteoprimerpixel:
		movdqu xmm4, [rdx + rbx*4  + 4] 	; xmm4 = |d[0][iw+4]|d[0][iw+3]|d[0][iw+2]	|d[0][iw+1]	|
		
		lea r12, [rdx + r8*4] 
		lea r12, [r12 + rbx*4 - 4] 			; r12 apunta a la misma columna de la siguiente fila

		movdqu xmm6, [r12]	 		; xmm6 = |d[1][iw+2]|d[1][iw+1]|d[1][iw]	|d[1][iw-1]	| 
		movdqu xmm7, [r12 + 8]		; xmm7 = |d[1][iw+4]|d[1][iw+3]|d[1][iw+2]	|d[1][iw+1]	|

		movdqu xmm5, xmm4  			; xmm5 = xmm4
		punpcklbw xmm3, xmm15 		; xmm3 = |d[0][iw]	|d[0][iw-1]|
		punpcklbw xmm4, xmm15 		; xmm4 = |d[0][iw+2]|d[0][iw+1]|    	Extiendo ceros: byte a word
		punpckhbw xmm5, xmm15 		; xmm5 = |d[0][iw+4]|d[0][iw+3]|

		movdqu xmm8, xmm7  			; xmm8 = xmm7
		punpcklbw xmm6, xmm15 		; xmm6 = |d[1][iw]	|d[1][iw-1]|
		punpcklbw xmm7, xmm15 		; xmm7 = |d[1][iw+2]|d[1][iw+1]| 		Extiendo ceros: byte a word
		punpckhbw xmm8, xmm15 		; xmm8 = |d[1][iw+4]|d[1][iw+3]|

		lea r13, [r10 + r8*4]
		lea r13, [r13 + rbx*4]		; posicion del pixel a calcular
		lea r12, [r12 + r8*4] 		; posicion del pixel de la fila siguiente a procesar
		looph:
			movdqu xmm0, xmm3 		;Descarto fila vieja
			movdqu xmm1, xmm4
			movdqu xmm2, xmm5

			movdqu xmm3, xmm6 
			movdqu xmm4, xmm7
			movdqu xmm5, xmm8

			movdqu xmm6, [r12]	 		; xmm6 = |d[ih+1][iw+2]|d[ih+1][iw+1]|d[ih+1][iw]	|d[ih+1][iw-1]	| 
			movdqu xmm7, [r12 + 8]		; xmm7 = |d[ih+1][iw+4]|d[ih+1][iw+3]|d[ih+1][iw+2]	|d[ih+1][iw+1]	|
			contlastpixel:

			movdqu xmm8, xmm7  			; xmm8 = xmm7
			punpcklbw xmm6, xmm15 		; xmm6 = |d[ih+1][iw]	|d[ih+1][iw-1]|
			punpcklbw xmm7, xmm15 		; xmm7 = |d[ih+1][iw+2]	|d[ih+1][iw+1]|
			punpckhbw xmm8, xmm15 		; xmm8 = |d[ih+1][iw+4]	|d[ih+1][iw+3]|

			paddw xmm0, xmm3 			
			paddw xmm0, xmm6 			; xmm0 = |sum(d[x][iw])x={ih-1, ih, ih+1}	|sum(d[x][iw-1])x={ih-1, ih, ih+1}|
			paddw xmm1, xmm4 			
			paddw xmm1, xmm7 			; xmm1 = |sum(d[x][iw+2])x={ih-1, ih, ih+1}	|sum(d[x][iw+1])x={ih-1, ih, ih+1}|
			paddw xmm2, xmm5 			
			paddw xmm2, xmm8 			; xmm2 = |sum(d[x][iw+4])x={ih-1, ih, ih+1}	|sum(d[x][iw+3])x={ih-1, ih, ih+1}|

			movdqu xmm10, xmm0
			movdqu xmm9, xmm0
			punpcklwd xmm9, xmm15 		; xmm9 = |sum(d[x][iw-1])x={ih-1, ih, ih+1} |	Extiendo ceros: word a dword
			punpckhwd xmm10, xmm15 		; xmm10= |sum(d[x][iw])x={ih-1, ih, ih+1}	|
			movdqu xmm11, xmm1
			punpcklwd xmm11, xmm15 		; xmm11= |sum(d[x][iw+1])x={ih-1, ih, ih+1} |
			
			paddd xmm9, xmm10
			paddd xmm9, xmm11 			; xmm9 = |sum(d[x][y])x={ih-1, ih, ih+1} y={iw-1,iw,iw+1} |
			CVTDQ2PS xmm9, xmm9 		; convierto a SP FP
			divps xmm9, xmm13 			; xmm9 = |	B/9	| 	G/9	| R/9 	| A/9 	|
			CVTPS2DQ xmm9, xmm9			; xmm9 = |	B'	| 	G'	| R' 	| A' 	| 	En enteros
			pshufb xmm9, xmm14 			; xmm9 = |	0	| 	0	| 0 	|B|G|R|A|
			PEXTRD [r13], xmm9, 00b 	; grabo a memoria primer pixel 
			
			movdqu xmm12, xmm1
			punpckhwd xmm12, xmm15 		; xmm12= |sum(d[x][iw+2])x={ih-1, ih, ih+1}	|
			paddd xmm10, xmm12
			paddd xmm10, xmm11 			; xmm10= |sum(d[x][y])x={ih-1, ih, ih+1} y={iw,iw+1,iw+2} |
			CVTDQ2PS xmm10, xmm10 		; convierto a SP FP
			divps xmm10, xmm13 			; xmm10 = |	B/9	| 	G/9	| R/9 	| A/9 	|
			CVTPS2DQ xmm10, xmm10			; xmm10 = |	B'	| 	G'	| R' 	| A' 	| 	En enteros
			pshufb xmm10, xmm14 			; xmm10 = |	0	| 	0	| 0 	|B|G|R|A|
			PEXTRD [r13 + 4], xmm10, 00b 	; grabo a memoria segundo pixel 

			movdqu xmm9, xmm2
			punpcklwd xmm9, xmm15 		; xmm9= |sum(d[x][iw+3])x={ih-1, ih, ih+1}	|
			paddd xmm11, xmm9
			paddd xmm11, xmm12 			; xmm11= |sum(d[x][y])x={ih-1, ih, ih+1} y={iw+1,iw+2,iw+3} |
			CVTDQ2PS xmm11, xmm11 		; convierto a SP FP
			divps xmm11, xmm13 			; xmm11 = |	B/9	| 	G/9	| R/9 	| A/9 	|
			CVTPS2DQ xmm11, xmm11			; xmm11 = |	B'	| 	G'	| R' 	| A' 	| 	En enteros
			pshufb xmm11, xmm14 			; xmm11 = |	0	| 	0	| 0 	|B|G|R|A|
			PEXTRD [r13 + 8], xmm11, 00b 	; grabo a memoria tercer pixel 

			movdqu xmm11, xmm2
			punpckhwd xmm11, xmm15 		; xmm11= |sum(d[x][iw+4])x={ih-1, ih, ih+1}	|
			paddd xmm12, xmm9
			paddd xmm12, xmm11 			; xmm12= |sum(d[x][y])x={ih-1, ih, ih+1} y={iw+2,iw+3,iw+4} |
			CVTDQ2PS xmm12, xmm12 		; convierto a SP FP
			divps xmm12, xmm13 			; xmm12 = |	B/9	| 	G/9	| R/9 	| A/9 	|
			CVTPS2DQ xmm12, xmm12			; xmm12 = |	B'	| 	G'	| R' 	| A' 	| 	En enteros
			pshufb xmm12, xmm14 			; xmm12 = |	0	| 	0	| 0 	|B|G|R|A|
			PEXTRD [r13 + 12], xmm12, 00b 	; grabo a memoria cuarto pixel 

			lea r13, [r13 + r8*4]
			lea r12, [r12 + r8*4]

			inc rcx 			; incremento ih
			cmp rbx, r15  		; Me fijo si llegue a la ultima columna a procesar
			jne cont
			cmp rcx, r14 		; En caso de estar en ultima columna a procesar, me fijo si llegue a ultima fila a procesar
			je lastpixel 		; Salto a ultimo caso especial (ultimo pixel)
			cont:
			cmp rcx, rsi 		; Me fijo si llegue a ultima linea, loop normal
			jne looph
		mov rcx, 1
		add rbx, 4
		cmp rbx, rdi
		jne loopw
	jmp copy

	lastpixel:
	movdqu xmm0, xmm3 		;Descarto fila vieja
	movdqu xmm1, xmm4
	movdqu xmm2, xmm5

	movdqu xmm3, xmm6 
	movdqu xmm4, xmm7
	movdqu xmm5, xmm8

	movdqu xmm6, [r12]	 		; xmm6 = |d[ih+1][iw+2]|d[ih+1][iw+1]|d[ih+1][iw]	|d[ih+1][iw-1]	| 
	movdqu xmm7, [r12 + 4]		; xmm7 = |d[ih+1][iw+3]|d[ih+1][iw+2]|d[ih+1][iw+1]	| d[ih+1][iw]	|
	psrldq xmm7, 4 				; xmm7 = | X 		   |d[ih+1][iw+3]|d[ih+1][iw+2]	|d[ih+1][iw+1]	|
	jmp contlastpixel

	; Copio todo lo procesado a la imagen original
	copy:
	lea r12, [r10 + r8*4] 	; r12 apunta a data temporal, desde segunda linea
	lea r14, [rdx + r8*4]	; r14 apunta a data original, desde segunda linea
	xor rcx, rcx			; rcx = 0 countx 
	mov rbx, 1 				; rbx = 1 county (no paso por borde superior)
	mov r15, r8 			; r15 = w
	dec r15 				; r15 = w-1 (para ver si llego al borde, los bordes no se cambian)
	dec r9 					; r9 = h-1 (idem)
	copywhile:
		cmp rcx, 0 			; Borde izquierdo
		je borde
		cmp rcx, r15 		; Borde derecho
		je borde
		mov r11d, [r12] 	; Copy
		mov [r14], r11d 	; Paste
		borde:				; Si vengo aca salteo la copia
		inc rcx  			; inc x
		add r14, 4 			; Avanzo
		add r12, 4 			; *
		cmp rcx, r8 		; Termino la fila
		jne copywhile 
		mov rcx, 0 
		inc rbx 			; inc y
		cmp rbx, r9 		; Borde inferior
		jne copywhile

	; Freeo la data temporal
	mov rdi, r10
	call free

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret