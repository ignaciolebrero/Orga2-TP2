; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion Blur 1                                     ;
;                                                                           ;
; ************************************************************************* ;
	extern malloc
	extern free
	%define elimprim 	00000000h

; void ASM_blur1( uint32_t w, uint32_t h, uint8_t* data )
; 					edi 	, esi 		, rdx
global ASM_blur1
	divs: dd 9.0, 9.0, 9.0, 9.0
	shuf: db 0x00,0x04,0x08,0x0C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	_floor: dd 0x7F80
ASM_blur1:
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
	mov eax, elimprim ; eax = 0 dword, lo voy a usar para borrar el pixel que agarro de mas
	dec rdi 		; rdi = w-1 : Limite del loop de pixeles en fila
	dec rsi 		; rsi = h-1 : Limite del loop de filas
	mov rbx, 1 		; rbx = 1 : "iw" itera pixeles en fila
	mov rcx, 1 		; rcx = 1 : "ih" itera filas
	movdqu xmm9, [divs] 	; xmm9 = | 9.0 | 9.0 | 9.0 | 9.0 |
	movdqu xmm10, [shuf] 	; Shuffle para pasar dword int a byte int
	mov r15, rdi 			
	dec r15 				; Limite ultimo pixel w 
	mov r14, rsi 			
	dec r14 				; Limite ultimo pixel h 
							; Al cargar los datos para el ultimo pixel, el pixel "de mas" no existe, sino que es espacio de memoria
							; que no se supone que puedo acceder. R15 y R14 es para detectar cuando llego a esta posicion
	loopw:
		movdqu xmm1, [rdx + rbx*4 - 4] 		; xmm1 = |d[0][iw+2]|d[0][iw+1]|d[0][iw]|d[0][iw-1]| d son 4 bytes A R G y B
		lea r12, [rdx + r8*4] 
		lea r12, [r12 + rbx*4 - 4] 			; r12 apunta a la misma columna de la siguiente fila
		movdqu xmm3, [r12]	; xmm3 = |d[1][iw+2]|d[1][iw+1]|d[1][iw]|d[1][iw-1]|
		pinsrd xmm1, eax, 03h 		; xmm1 = | 	0 		|d[0][iw+1]|d[0][iw]|d[0][iw-1]|
		pinsrd xmm3, eax, 03h  		; xmm3 = | 	0 		|d[1][iw+1]|d[1][iw]|d[1][iw-1]|
		movdqu xmm2, xmm1  			; xmm2 = xmm1
		movdqu xmm4, xmm3 			; xmm4 = xmm3
		pxor xmm8, xmm8 			; xmm8 = |0|
		punpcklbw xmm1, xmm8 		; xmm1 = |d[0][iw]	|d[0][iw-1]|  d ahora son 4 words A R G y B extendidos con ceros
		punpckhbw xmm2, xmm8 		; xmm2 = |  0 		|d[0][iw+1]|
		punpcklbw xmm3, xmm8 		; xmm3 = |d[1][iw]	|d[1][iw-1]|
		punpckhbw xmm4, xmm8 		; xmm4 = |  0 		|d[1][iw+1]|
		paddw xmm1, xmm2 			; xmm1 = |d[0][iw]|d[0][iw-1]+d[0][iw+1]|
		paddw xmm3, xmm4 			; xmm3 = |d[1][iw]|d[1][iw-1]+d[1][iw+1]|
		movdqu xmm2, xmm1 			; xmm2 = xmm1
		movdqu xmm4, xmm3 			; xmm4 = xmm3
		psrldq xmm2, 8 				; xmm2 = | 0 		|d[0][iw]|
		psrldq xmm4, 8 				; xmm4 = | 0 		|d[1][iw]|
		paddw xmm1, xmm2 			; xmm1 = | X 		|d[0][iw-1]+d[0][iw+1]+d[0][iw]| 
		paddw xmm3, xmm4 			; xmm3 = | X 		|d[1][iw-1]+d[1][iw+1]+d[1][iw]| 
		movdqu xmm2, xmm3 			; xmm2 = xmm3 
		lea r13, [r10 + r8*4]
		lea r13, [r13 + rbx*4]		; posicion del pixel a calcular
		lea r12, [r12 + r8*4] 		; posicion del pixel de la fila siguiente a procesar
		looph:
			movdqu xmm0, xmm1 			;xmm0 suma pixeles fila anterior
			movdqu xmm1, xmm2 			;xmm1 suma pixeles fila actual
			movdqu xmm2, [r12] 			; xmm2 = |d[ih+1][iw+2] |d[ih+1][iw+1]|d[ih+1][iw]|d[ih+1][iw -1]|
			pinsrd xmm2, eax, 03h  		; xmm2 = | 	0 			|d[ih+1][iw+1]|d[ih+1][iw]|d[ih+1][iw -1]|
			contlastpixel:
			movdqu xmm3, xmm2 			; xmm3 = xmm2
			punpcklbw xmm2, xmm8 		; xmm2 = |d[ih+1][iw]	|d[ih+1][iw-1]|  d ahora son 4 words A R G y B extendidos con ceros
			punpckhbw xmm3, xmm8 		; xmm3 = |  0 			|d[ih+1][iw+1]|
			paddw xmm2, xmm3 			; xmm2 = |d[ih+1][iw]|d[ih+1][iw-1]+d[ih+1][iw+1]|
			movdqu xmm3, xmm2 			; xmm3 = xmm2
			psrldq xmm3, 8 				; xmm3 = | 0 		|d[ih+1][iw]|
			paddw xmm2, xmm3 			; xmm2 = | X 		|d[ih+1][iw-1]+d[ih+1][iw+1]+d[ih+1][iw]| 
			paddw xmm0, xmm2
			paddw xmm0, xmm1 			; xmm0 = | X 		|SUMA d[x][y] con x = {ih-1, ih, ih+1} y = {iw-1, iw, iw+1}|
			punpcklwd xmm0, xmm8 		; xmm0 = |SUMA d[x][y] con x = {ih-1, ih, ih+1} y = {iw-1, iw, iw+1}|  4 dwords A R G y B extendidos con ceros
			CVTDQ2PS xmm3, xmm0 		; xmm3 = |	R 	| 	A 	| B 	| G 	|
			divps xmm3, xmm9 			; xmm3 = |	R/9	| 	A/9	| B/9 	| G/9 	|
			CVTPS2DQ xmm0, xmm3 		; xmm0 = |	R'	| 	A'	| B' 	| G' 	|
			pshufb xmm0, xmm10 			; xmm0 = |	0	| 	0	| 0 	|R|A|G|B|
			PEXTRD [r13], xmm0, 00b 	; grabo a memoria
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
		inc rbx
		cmp rbx, rdi
		jne loopw
	jmp copy

	lastpixel:
	movdqu xmm0, xmm1 				;xmm0 suma pixeles fila anterior
	movdqu xmm1, xmm2 				;xmm1 suma pixeles fila actual
	movdqu xmm2, [r12-4] 		; xmm2 = |d[ih+1][iw+1]	|d[ih+1][iw]	|d[ih+1][iw -1]	|d[ih+1][iw -2]|
	psrldq xmm2, 4 				; xmm2 = |  0 		 	|d[ih+1][iw+1]	|d[ih+1][iw]	|d[ih+1][iw -1]|
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