	PROCESSOR       16F877A
	RADIX           DEC

#INCLUDE <p16F877A.inc>

	org 0X00
	goto inicio

inicio

	banksel	TRISD
	movlw	00000000b
	movwf	TRISD

loop
	goto	loop

	end 