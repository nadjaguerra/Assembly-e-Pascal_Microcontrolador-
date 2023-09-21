	PROCESSOR   16F877A
	RADIX		DEC

#INCLUDE <p16F877A.inc>
	__config	0x3F32

	org 0X00
	goto inicio
	
	org 0x04
	goto inter

	org 0X20


temp	res 2			;registrador temporário
segu	res 1			;registrador da unidade de segundo
segd	res 1			;registrador da dezena de segundo	
min_u	res	1
min_d	res	1
w_temp	res 1 			;salva W
s_temp	res 1 			;salva STATUS
flags	res 1			;controle do ponto 
inicio

	banksel	TRISD
	movlw	00000000b
	movwf	TRISD
	movwf	TRISA
	movlw	11111111b
	movwf 	TRISB
	movlw 	6
	movwf	ADCON1
	bsf		PIE1,TMR1IE			;seta interrupção do timer1
	bsf		INTCON,PEIE			;seta interrupção do periferico
	bsf		INTCON,GIE			;seta interrupção geral

	banksel PORTD
	movlw	00000000b
	movwf	PORTD
	movwf	PORTA
	clrf	T1CON	

	bsf		T1CON,TMR1ON		;irá ligar o TMR1, que é o contador 	
	bsf		T1CON,T1CKPS1
	bsf		T1CON,T1CKPS0


	clrf	segu				;inicializa a variável em 0
	clrf	segd
	clrf	min_u
	clrf	min_d
	clrf	TMR1L
	clrf	TMR1H
	
loop

	btfsc	PORTB,0				;zerar em RB0
	goto	$+3
	clrf	segu
	clrf	segd

	movlw	00000001b			;mascara TMR1ON
	btfsc	PORTB,1				;parar
	goto	$+4
	btfss	PORTB,1
	goto	$-1
	xorwf	T1CON,f	
	
	rrf		segu,w				;rotaciona segu para direita com carry out
	xorlw	10					;compara se é igual a 10
	btfss	STATUS,Z			; se for igual a 10, salta e continua o programa, se não for, execulta o goto
	goto	$+3	
	clrf	segu
	incf	segd	
	
	movf	segd,w				;copia o valor para w
	xorlw	6					;compara com 6
	btfsc	STATUS,Z			;testa, se não for 6, não irá execultar o proximo clrf
	clrf	segd
	incf	min_u				;se for 6, reinicia

	movf	min_u,w				;copia o valor para w
	xorlw	10					;compara com 6
	btfss	STATUS,Z			;testa, se não for 6, não irá execultar o proximo clrf
	goto	$+3
	clrf	min_u
	incf	min_d				;se for 6, reinicia

	movf	min_d,w				;copia o valor para w
	xorlw	6					;compara com 6
	btfsc	STATUS,Z			;testa, se não for 6, não irá execultar o proximo clrf
	clrf	min_d
	


	bcf		PORTA, 4			;desabilita o RA4 para ativar o RA5 - dig1
	rrf		segu,w 				;rotaciona segu para direita com carry out
	call	hex7seg				;decodificao valor recebido
	movwf	PORTD				; saída
	bsf		PORTA, 5
			
	btfsc	flags,0				; se o flag estiver em 0, ele irá setar o próximo comando
	bsf		PORTD,7	
	btfss	flags,0
	bcf		PORTD,7		
	call 	atraso2

	bcf		PORTA, 5			;desabilita o RA5 para ativar o RA4 - dig2
	movf	segd,w 				;muda o valor do registrador seg para w
	call	hex7seg
	movwf	PORTD
	bsf		PORTA, 4
	call	atraso2

	bcf		PORTA, 1			;desabilita o RA4 para ativar o RA5 - dig1
	rrf		min_u,w 				;rotaciona segu para direita com carry out
	call	hex7seg				;decodificao valor recebido
	movwf	PORTD				; saída
	bsf		PORTA, 2	

	btfsc	flags,0				; se o flag estiver em 0, ele irá setar o próximo comando
	bsf		PORTD,6	
	btfss	flags,0
	bcf		PORTD,6		
	

	bcf		PORTA, 2			;desabilita o RA5 para ativar o RA4 - dig2
	movf	min_d,w 				;muda o valor do registrador seg para w
	call	hex7seg
	movwf	PORTD
	bsf		PORTA, 1
	


	goto	loop
atraso 
	movlw 	255
	movwf 	temp

@1	decf	 temp,f
	btfss	 STATUS,Z
	goto	 @1 

atraso2 ; X*10+7
	movlw 	1000/256+1
	movwf	temp
	movlw	1000%256
	movwf	temp+1

	nop
	nop
	nop
	nop
	nop

	decf	temp+1,f
	btfsc	STATUS, Z


	decfsz	temp,f
	goto	$-8
	
	return

atraso3 ; X*10+7
	movlw 	499/256+1
	movwf	temp
	movlw	499%256
	movwf	temp+1


	decf	temp+1,f
	btfsc	STATUS, Z


	decfsz	temp,f
	goto	$-1
	
	return


inter
	movwf	w_temp				;move de w para f a variável w_temp
	swapf	STATUS, w			;troca os nibbles alto e baixo do registrador
	movwf	s_temp

	
	bcf		PIR1,TMR1IF
	incf	segu,f


	movlw	3041/256
	movwf	TMR1H
	movlw	3041%256
	movwf	TMR1L

	movlw	00000001b		; 
	xorwf	flags,f

	swapf	s_temp,w
	movwf	STATUS
	swapf	w_temp,f
	swapf	w_temp,w
	retfie


hex7seg
	andlw	01101111b			; o valor de w está limitado a chegar a 9
	addwf	PCL,f
	
	retlw 	00111111b    		;digito  0	
	retlw	00000110b			;digito  1
    retlw 	01011011b   		;digito  2
    retlw 	01001111b    		;digito  3
    retlw 	01100110b	 	    ;digito  4
    retlw 	01101101b		    ;digito  5
    retlw 	01111101b	  	  	;digito  6
    retlw 	00000111b	    	;digito  7
    retlw 	01111111b	    	;digito  8
    retlw 	01101111b	    	;digito  9

	end 
