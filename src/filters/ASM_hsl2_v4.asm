; ************************************************************************* ;
; 				Organizacion del Computador II                              ;
;                                                                           ;
;   	Implementacion de la funcion HSL 2-variacion 4  					;
;       rgbTOhsl.calcMax -> siemrpe da azul                 			    ;
;                                                                           ;
; ************************************************************************* ;
extern malloc
extern free  

%define PIXEL_SIZE 4h
%define OFFSET_A   0h
%define OFFSET_R   1h	 
%define OFFSET_G   2h
%define OFFSET_B   3h

lemask:  dd 0.0, 360.0, 1.0, 1.0 ; 1 | 1 | 360 | 0
absmask: dd 0x7FFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,0xFFFFFFFF
shuf: 	 db 0x00,0x04,0x08,0x0C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
divS:	 dd 255.0001, 0.0, 0.0, 0.0 ; 0 | 0 | 0 | 255.0001
divL:    dd 510.0, 0.0, 0.0, 0.0
one:     dd 1.0 , 0.0, 0.0, 0.0
cEscala: dd 0.0 , 255.0, 255.0, 255.0
cRGB:    dd 120.0, 0.0, 0.0, 0.0
cmod2:   dd 2.0, 0.0, 0.0, 0.0
c060: 	 dd 60.0, 0.0, 0.0, 0.0


; void ASM_hsl2(uint32_t w, uint32_t h, uint8_t* data, float hh, float ss, float ll)
global ASM_hsl2
ASM_hsl2:
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
		call rgbTOhsl3		   ;rsi = pixel en hsl ;pixel en registro = l s h a
		;call rgbTOhsl
		movdqu 	 xmm11, [r12]   ;xmm11 = l | s | h | a 
		
		;el ultimo "else" se toma como implicito y se buscan las modificaciones hacia los otros casos de ser necesarias,
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
		call 	 hslTOrgb3
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
  
rgbTOhsl3:
	push rbp
	mov  rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub  rbp, 8
	
	xor r14, r14
	xor r15, r15
	xor rcx, rcx
	xor rbx, rbx
	xor rax, rax
	xor rdx, rdx
	mov r12, rdi   ;r12 = *dato
	mov r13, rsi   ;r13 = *dst
	mov eax, [r12] ;rax = r-g-b-a
	mov r8 , rax   ;r8  = r-g-b-a

	;repartimos valores
	mov  dl, al      ;rdx = a
	shrd rax, r14, 8 ;rbx = r-g-b
	mov  bl, al		 ;rbx = b
	shrd rax, r14, 8 ;rax = r-g
	mov  cl, al	     ;rcx = g
	shrd rax, r14, 8 ;rax = r

	.calcMax:
	mov r15, rbx  ;r15 = b (max actual)
	;cmp r15, rcx ;maxactual < g 
	;jl	.maxg
	;.max2:
	;cmp r15, rax ;maxactual < r 
	;jl  .maxr
	;jge .calcMin
	;.maxg:
	;mov r15, rcx ;maxactual = g
	;jmp .max2
	;.maxr:
	;mov r15, rax ;maxactual = r
	;jmp .calcMin


	.calcMin:
	mov r14, rbx ;r14 = b (min actual)
	cmp r14, rcx ;minactual > g
	jg	.ming
	.min2:
	cmp r14, rax ;minactual > r
	jg  .minr
	jle .calcD
	.ming:
	mov r14, rcx ;minactual = g
	jmp .min2
	.minr:
	mov r14, rax ;minactual = r
	jmp .calcD


	.calcD:
	xor r8, r8
	xor r9, r9
	mov r8,  rax ;r8  = r
	mov r9,  rbx ;r9  = b
	mov r10, rcx ;r10 = g
	mov rcx, r14 ;rcx = minimo
	mov rbx, r15 ;rbx = maximo
	sub r15, r14 ;r15 = maximo - minimo


	.calcH:
	xor  r11 , r11
	pxor xmm0, xmm0
	pxor xmm1, xmm1
	pxor xmm2, xmm2
	pxor xmm4, xmm4

	cmp r15, 0   ;if(max == min)
	je .Hcaso0
	cmp rbx, r8  ;if(max == r)
	je .Hcaso1				  
	cmp rbx, r10 ;if(max == g)
	je .Hcaso2				  
	cmp rbx, r9  ;if(max == b)
	je .Hcaso3				  
	jmp .calcL

	.Hcaso0:
	xorps xmm0, xmm0
	jmp .calcL

	.Hcaso1:
	movq xmm0, r10 ;xmm0 = g
	movq xmm1, r9  ;xmm1 = b
	movq xmm2, r15 ;xmm2 = d
	mov  r11 , 60
	movq xmm3, r11 ;xmm3 = 60
	mov  r11 , 6
	movq xmm4, r11 ;xmm4 = 6
	
	cvtdq2ps xmm0, xmm0	;xmm0 = (float) g
	cvtdq2ps xmm1, xmm1	;xmm0 = (float) b
	cvtdq2ps xmm2, xmm2	;xmm2 = (float) d
	cvtdq2ps xmm3, xmm3	;xmm3 = (float) 60
	cvtdq2ps xmm4, xmm4	;xmm4 = (float) 6
	jmp .Hoperar

	.Hcaso2:
	movq xmm0, r9  ;xmm0 = b
	movq xmm1, r8  ;xmm1 = r
	movq xmm2, r15 ;xmm2 = d
	mov  r11 , 60
	movq xmm3, r11 ;xmm3 = 60
	mov  r11 , 2
	movq xmm4, r11 ;xmm4 = 2
	
	cvtdq2ps xmm0, xmm0	;xmm0 = (float) b
	cvtdq2ps xmm1, xmm1 ;xmm1 = (float) r
	cvtdq2ps xmm2, xmm2	;xmm2 = (float) d
	cvtdq2ps xmm3, xmm3	;xmm3 = (float) 60
	cvtdq2ps xmm4, xmm4	;xmm4 = (float) 2
	jmp .Hoperar

	.Hcaso3:
	movq xmm0, r8  ;xmm0 = r
	movq xmm1, r10 ;xmm1 = g
	movq xmm2, r15 ;xmm2 = d
	mov  r11 , 60
	movq xmm3, r11 ;xmm3 = 60
	mov  r11 , 4
	movq xmm4, r11 ;xmm4 = 4

	cvtdq2ps xmm0, xmm0 ;xmm0 = (float) r
	cvtdq2ps xmm1, xmm1	;xmm0 = (float) g
	cvtdq2ps xmm2, xmm2	;xmm2 = (float) d
	cvtdq2ps xmm3, xmm3	;xmm3 = (float) 60
	cvtdq2ps xmm4, xmm4	;xmm4 = (float) 4
	jmp .Hoperar

	.Hoperar: ;(los comentarios de esta funcion son un mero ejemplo del caso 3, es analogo para los otros 2)
	subps    xmm0, xmm1 ;xmm0 = g-b
	divps	 xmm0, xmm2 ;xmm0 = (g-b)/d
	addps    xmm0, xmm4 ;xmm0 = ((d-b)/d) + 4
	mulps    xmm0, xmm3 ;xmm0 = 60 * ( (d-b)/d + 4 )

	;ultimo if
	mov   	 r8, 360
	pxor     xmm1, xmm1
	pxor     xmm2, xmm2
	movq  	 xmm1, r8   ;xmm1 = 360
	cvtdq2ps xmm1, xmm1
	movdqu   xmm2, xmm1 ;xmm2 = 360
	cmpleps  xmm1, xmm0 ;xmm1 = 360 <= h
	pand     xmm2, xmm1 ;xmm2 = 360 o 0 
	subps    xmm0, xmm2 ;xmm0 = h o h-360
	pslldq   xmm0, 12
	psrldq   xmm0, 12
	jmp .calcL


	.calcL:
	pxor xmm1, xmm1
	pxor xmm2, xmm2
	mov  r8, rbx  ;r8 = max
	add  r8, r14  ;r8 = max + min
	movq xmm1, r8 ;xmm1 = max + min
	cvtdq2ps xmm1, xmm1
	divps xmm1, [divL] ;xmm1 = ( max + min ) / 510
	pslldq   xmm1, 12
	psrldq   xmm1, 12

	.calcS:
	pxor xmm2, xmm2   ;xmm2  = 0
	pxor xmm11, xmm11 ;xmm11 = 0
	cmp rbx, r14
	je .terminar

	;else
	movq xmm2, r15 ;xmm2 = d
	cvtdq2ps xmm2, xmm2
	
	mov  	 r8, 1
	movq 	 xmm4, r8
	cvtdq2ps xmm4, xmm4 ;xmm4 = 1.0
	
	movdqu   xmm3, xmm4 ;xmm3 = 1.0
	addps    xmm3, xmm3 ;xmm3 = 2.0
	mulps    xmm3, xmm1 ;xmm3 = 2*l
	subps    xmm3, xmm4 ;xmm3 = 2*l - 1
	movdqu   xmm12, [absmask]
	pand     xmm3, xmm12 ; abs(2*l - 1)
	subps    xmm4, xmm3   ;xmm4 = 1 - abs( 2*l - 1 )
	divps	 xmm2, xmm4   ;xmm4 = d / ( 1 - fabs( 2*l - 1 ) )

	divps    xmm2, [divS] ;xmm2 = d / ( 1 - fabs( 2*l - 1 ) ) / 255.0001
	pslldq   xmm2, 12
	psrldq   xmm2, 12


	.terminar:
	movq xmm10, rdx
	cvtdq2ps xmm10, xmm10
	
	punpckldq xmm0, xmm1  ;xmm1  = 0 | 0 | l | h
	punpckldq xmm10, xmm2 ;xmm2  = 0 | 0 | s | a
	punpckldq xmm10, xmm0 ;xmm10 = l | s | h | a

	movdqu [r13], xmm10

	add rbp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret

hslTOrgb3: ; rdi = float *src rsi = uint8_t *dst
	push rbp
	mov  rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub  rbp, 8

	mov r12, rdi ; r12 = *src
	mov r13, rsi ; r13 = *dst

	;separacion de elementos
	pxor xmm1, xmm1
	pxor xmm2, xmm2

	movdqu 	  xmm0, [r12] ;xmm0 = l | s | h | a
	punpckldq xmm2, xmm0  ;xmm2 = h | 0 | a | 0
	punpckhdq xmm1, xmm0  ;xmm1 = l | 0 | s | 0
	;l
	psrldq xmm0, 12 ;xmm0 = 0 | 0 | 0 | l
	;s
	pslldq xmm1, 4 ;xmm1 = 0 | s | 0 | 0
	psrldq xmm1, 8 ;xmm1 = 0 | 0 | 0 | s
	;h
	movdqu xmm3, xmm2 ;xmm3 = h | 0 | a | 0
	psrldq xmm2, 12   ;xmm2 = 0 | 0 | 0 | h
	;a
	pslldq xmm3, 4 ;xmm3 = 0 | a | 0 | 0
	psrldq xmm3, 8 ;xmm3 = 0 | 0 | 0 | a

	;Cálculo de c, x y m
	.calcC:
	movdqu xmm15, [one] ;xmm15 = 1
	movdqu xmm4 , xmm15 ;xmm4  = 1
	movdqu xmm5 , xmm4  ;xmm5  = 1
	movdqu xmm10, xmm4  ;xmm5  = 1

	addss  xmm5, xmm5 ;xmm5 = 2
	mulss  xmm5, xmm0 ;xmm5 = 2*l
	subss  xmm5, xmm4 ;xmm5 = 2*l - 1

	movdqu xmm11, [absmask] ;xmm11 = 0 yo todos 1s
	pand   xmm5 , xmm11 	;xmm5  = abs(2*l - 1)

	subss  xmm4, xmm5 ;xmm4 = 1 - abs(2*l - 1)
	mulss  xmm4, xmm1 ;xmm4 = ( 1 - abs(2*l - 1) ) * s

	.calcX:
	mov r8, 60
	movq xmm10, r8
	cvtdq2ps xmm10, xmm10 ;xmm10 = 60

	movdqu xmm11, xmm2  ;xmm11 = h
	divss  xmm11, xmm10 ;xmm11 = h/60

	movdqu xmm5 , xmm15  ;xmm5  = 1
	movdqu xmm13, xmm5   ;xmm13 = 1
	movdqu xmm12, [cmod2];xmm12 = 2.0
	comiss xmm11, xmm12   
	jb .finloop
	.modresta:
	subss xmm11, xmm12 	;xmm11 = xmm11 - 60.0
	comiss xmm12, xmm11 
	jbe .modresta

	.finloop:
	subss xmm11, xmm13  ;xmm11 = mod(h/60 , 2) - 1
	movdqu xmm12, [absmask]
	pand   xmm11, xmm12	;xmm11 = abs( mod(h/60 , 2) - 1 )
	subss  xmm13, xmm11 ;xmm13 = 1 - ( abs( mod(h/60 , 2) - 1 ) )
	mulss  xmm13, xmm4  ;xmm13 = c * ( 1 - ( abs( mod(h/60 , 2) - 1 ) ) )
	movdqu xmm5 , xmm13 ;xmm5  = c * ( 1 - ( abs( mod(h/60 , 2) - 1 ) ) )

	.calcM:
	movdqu xmm10, xmm0  ;xmm10 = l
	movdqu xmm11, xmm15 ;xmm11 = 1
	addss  xmm11, xmm11 ;xmm11 = 2
	movdqu xmm12, xmm4  ;xmm12 = c

	divss  xmm12, xmm11 ;xmm12 = c/2
	subss  xmm10, xmm12 ;xmm10 = l - c/2

	;Cálculo de RGB
	.calcRGB:
	pxor   xmm12, xmm12
	movdqu xmm11, [c060]
	addss  xmm12, xmm11 ;xmm12 = 60
	movd   r10d, xmm5 	;r10 = x

	.mayig0:
	comiss xmm2, xmm12
	jb .men60
	addss xmm12, xmm11	 	;xmm12 = 120
	comiss xmm2, xmm12
	jb .men120
	addss xmm12, xmm11	 	;xmm12 = 180
	comiss xmm2, xmm12
	jb .men180
	addss xmm12, xmm11	 	;xmm12 = 240
	comiss xmm2, xmm12
	jb .men240
	addss xmm12, xmm11	 	;xmm12 = 300
	comiss xmm2, xmm12
	jb .men300
	addss xmm12, xmm11	 	;xmm12 = 360
	comiss xmm2, xmm12
	jb .men360

	.men60:
	pslldq xmm4, 12 	 ;xmm4 = c | 0 | 0 | 0
	pinsrd xmm4, r10d, 2 ;xmm4 = c | x | 0 | 0
	jmp .calcEscala

	.men120:
	pslldq xmm4, 8 		 ;xmm4 = 0 | c | 0 | 0
	pinsrd xmm4, r10d, 3 ;xmm4 = x | c | 0 | 0
	jmp .calcEscala

	.men180:
	pslldq xmm4, 8 		 ;xmm4 = 0 | c | 0 | 0
	pinsrd xmm4, r10d, 1 ;xmm4 = 0 | c | x | 0
	jmp .calcEscala

	.men240:
	pslldq xmm4, 4 		 ;xmm4 = 0 | 0 | c | 0
	pinsrd xmm4, r10d, 2 ;xmm4 = 0 | x | c | 0
	jmp .calcEscala

	.men300:
	pslldq xmm4, 4 		 ;xmm4 = 0 | 0 | c | 0
	pinsrd xmm4, r10d, 3 ;xmm4 = x | 0 | c | 0
	jmp .calcEscala

	.men360:
	pslldq xmm4, 12		 ;xmm4 = c | 0 | 0 | 0
	pinsrd xmm4, r10d, 1 ;xmm4 = c | 0 | x | 0
	jmp .calcEscala

	;Cálculo de escala
	.calcEscala:
	movdqu xmm12, xmm10 ;xmm12 = 0 | 0 | 0 | m
	pslldq xmm12, 4 	;xmm12 = 0 | 0 | m | 0
	addps  xmm12, xmm10 ;xmm12 = 0 | 0 | m | m
	pslldq xmm12, 4     ;xmm12 = 0 | m | m | 0
	addps  xmm12, xmm10 ;xmm12 = 0 | m | m | m
	pslldq xmm12, 4     ;xmm12 = m | m | m | 0

	movdqu xmm13, [cEscala] ;xmm13 = 255 | 255 | 255 | 0

	addps  xmm4, xmm12 ;xmm4 = r+m | g+m | b+m | X
	mulps  xmm4, xmm13 ;xmm4 = (r+m)*255 | (g+m)*255 | (b+m)*255 | 0
	movd   r10d, xmm3
	pinsrd xmm4, r10d, 0 ;xmm4 = (r+m)*255 | (g+m)*255 | (b+m)*255 | a
	cvttps2dq xmm4, xmm4

	movdqu xmm10, [shuf] 	; Shuffle para pasar dword int a byte int
	pshufb xmm4 , xmm10 	; xmm4 = |	0	| 	0	| 0 	|R|G|B|A|
	PEXTRD [r13], xmm4, 00b ; grabo a memoria
	.terminar:

	add rbp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret
