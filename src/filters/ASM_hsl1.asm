; ************************************************************************* ;
; Organizacion del Computador II                                            ;
;                                                                           ;
;   Implementacion de la funcion HSL 1                                      ;
;                                                                           ;
; ************************************************************************* ;
extern malloc
extern free  
extern rgbTOhsl
extern hslTOrgb

%define PIXEL_SIZE      4h

lemask: dd 0.0, 360.0, 1.0, 1.0, ; 1 | 1 | 360 | 0

; void ASM_hsl1(uint32_t w, uint32_t h, uint8_t* data, float hh, float ss, float ll)
global ASM_hsl1
ASM_hsl1: ;edi w, esi h, rdx data, xmm0 hh, xmm1 ss, xmm2 ll
	push rbp
	mov  rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub  rbp, 8

	mov edi, edi ;limpio parte alta
	mov esi, esi 
	xor r15, r15

	movq   xmm8, xmm2   ;xmm8 = ll
	pslldq xmm8, 4 		;xmm8 = 0 | 0 | ll | 0
	addps  xmm8, xmm1   ;xmm8 = 0 | 0 | ll | ss
	pslldq xmm8, 4      ;xmm8 = 0 | ll | ss | 0
	addps  xmm8, xmm0   ;xmm8 = 0 | ll | ss | hh
	pslldq xmm8, 4  	;xmm8 = ll | ss | hh | 0

	movdqu xmm9, [lemask] ;xmm9 = 1 | 1 | 360 | 0
	movdqu xmm6, xmm9	  ;xmm6 = 1 | 1 | 360 | 0
	movdqu xmm7, xmm6
	pslldq xmm7, 8		  ;xmm7 = 360 | 0 |  0  | 0
	psrldq xmm7, 8		  ;xmm7 =  0  | 0 | 360 | 0
	psubd  xmm6, xmm7	  ;xmm6 =  1  | 1 |  0  | 0 


	mov rbx, rdi ;rbx = w
	mov r12, rsi ;r12 = h
	mov r13, rdx ;r13 = data

	mov rax, r12 ;rax = h
	mul rbx 	 ;rax = w * h
	mov r9, 4
	mul r9
	mov r14, rax ;r14 = w * h * 4

	mov rdi, 16d
	call malloc
	mov r12, rax ;r12 = *dst

	.ciclo:
		mov rsi, r12
		lea rdi, [r13 + r15]
		call rgbTOhsl		   ;rsi = pixel en hsl ;pixel en registro = l s h a
		movdqu 	 xmm11, [r12]   ;xmm11 = l | s | h | a 

		;el ultimo "else" se toma como implicito y se busca las modificaciones hacia los otros casos de ser necesario
		;primer if
		pxor   xmm5 , xmm5
		pxor   xmm15, xmm15
		addps  xmm11, xmm8 	 ;xmm11 = l+ll | s+ss | h+hh | a
		movdqu  xmm4, xmm11  ;xmm4 = l+ll | s+ss | h+hh | a
		movdqu  xmm13, xmm9	 ;xmm13 = 1 | 1 | 360 | 0
		cmpleps xmm13, xmm11 ;xmm13 = 1 <= l+ll | 1 <= s+ss | 360 <= h+hh | 0
		
		;h+hh >= 360
		movdqu  xmm5, xmm13  ;xmm5 = 1 <= l+ll | 1 <= s+ss | 360 <= h+hh | 0
		pand    xmm5, xmm7   ;xmm7 =  0 | 0 | 360 o 0 | 0
		subps   xmm11, xmm5  ;xmm11 = l+ll | s+ss | h+hh o h+hh-360| 0

		;s+ss >= 1 | l+ll >= 1
		movdqu  xmm5, xmm4	 ;xmm5 = l+ll |  s+ss  |  h+hh  | 0
		subps   xmm5, xmm6	 ;xmm5 = l+ll-1 | s+ss-1 | h+hh | 0
		pand    xmm5, xmm13  ;xmm5 = l+ll-1 o 0 | s+ss-1 o 0 | h+hh o 0 | 0
		psrldq  xmm5, 8 	 ;xmm5 = |  0  | 0  | l+ll-1 o 0 | s+ss+1 o 0 
		pslldq  xmm5, 8 	 ;xmm5 = l+ll-1 o 0 | s+ss-1 o 0 | 0 | 0 |
		subps   xmm11, xmm5  ;xmm11 = l+ll o 1  | s+ss o 1 | h+hh o h+hh-360  | 0

		;segundo if
		movdqu  xmm14, xmm4 ;xmm14 = l+ll | s+ss | h+hh | 0
		cmpltps xmm14, xmm15 ;xmm14 = l+ll < 0 | s+ss < 0 | h+hh < 0 | 0 

		;h+hh < 360
		movdqu  xmm5, xmm14  ;xmm5 = l+ll < 0 | s+ss < 0 | h+hh < 0 | 0 
		pand    xmm5, xmm7   ;xmm5 = 0 | 0 | 360 o 0 | 0
		addps   xmm11, xmm5  ;xmm11 = l+ll o 1 | s+ss o 1 | h+hh o h+hh-360 o h+hh+360| 0

		;s+ss < 0 | l+ll < 0
		movdqu  xmm5, xmm4   ;xmm5 = l+ll |  s+ss  |  h+hh  | 0
		pand    xmm5, xmm14  ;xmm5 = l+ll o 0 | s+ss o 0 | h+hh o 0 | 0 |
		psrldq  xmm5, 8 	 ;xmm5 = |  0  | 0  | l+ll o 0 | s+ss o 0 
		pslldq  xmm5, 8 	 ;xmm5 = l+ll o 0 | s+ss o 0 | 0 | 0 |
		subps   xmm11, xmm5  ;xmm11 = l+ll o 1 o 0 | s+ss o 1 o 0 | h+hh o h+hh-360 o h+hh+360 | 0


		movdqu   [r12], xmm11
		mov 	 rdi, r12
		lea 	 rsi, [r13 + r15]
		call 	 hslTOrgb

		add r15, PIXEL_SIZE
		cmp r15, r14
	jl  .ciclo

	add rbp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
  ret


