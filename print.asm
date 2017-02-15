PRINTING_START

;putchr_proc_adr		Address of current output routine.

PrintChar .proc
;Purpose:
;	Print character in register A.

		pha
		rol
		rol
		rol
		rol
		and #3
		tay
		pla
		eor taic,y
		
		ldy #0		
		sta (scr),y
		inw scr
		rts
TAIC	dta b(%01000000, %00100000, %01100000, %00000000)
.endp

PrintText .proc
;Purpose:
;	Print text in w1.
;In:
;	a,y  adr
;	x    len

		sta w1
		sty w1+1
		stx b1
		mva #0 b2
@		ldy b2
		lda (w1),y
		jsr PrintChar
		inc b2
		dec b1
		bne @-
		rts
		.endp


PrintHex	.PROC
;Print hexadecimal number of arbitrary length (?size). 
;Leading zeroes are not printed.
;In:
;	BUF		Hexadecimal number
;	a		Number of characters to print
;	x       What to use instead of 0 char (0 nothing)
;Uses:
;	aux
;	aux2

		stx aux3
		sta aux
		lda #0
		sta aux2		; number of non-zero digits on output
		beq _loop
_outbyte
		lda aux			;read byte
		lsr
		tay
		lda BUF,y
		pha

		lsr				;print low 4-bit digit
		lsr
		lsr
		lsr
		jsr _write_digit
		
		pla
		dec aux			;print high 4-bit digit
		bmi _last_dig
		and #$0f
		jsr _write_digit
_loop	
		dec aux
		bpl _outbyte
_last_dig		
		;If no character has been written, write at least one 0		
;		lda aux2
;		bne _no_empty
;		lda #48
;		jsr PrintChar
;_no_empty
 
		rts
	
_write_digit
;In: a 4 bit digit

		tax
		bne _non_zero
		lda aux2
		bne _non_zero		;this is zero and there has been no char before - no output
		lda aux				;this is last char, print the zero
		beq _non_zero
		lda aux3
		bne prn
		rts
_non_zero
		lda hex,x
		inc aux2
prn
		jsr PrintChar
_done
		rts

hex     dta c"0123456789ABCDEF"
.endp
	
BinToBCD	.PROC
;Convert binary number to BCD. 
;Arbitrary size (up to 127 bytes) are supported.
;In:
;	?varptr	pointer to binary number
; a   0 means unsigned number
;     $ff means signed number
;	?size	number of bytes
;Out:
;	?size	on output, returns size of resulting bcd number
;   ?varptr	on output, containg pointer to converted BCD
;Uses:
;	system__buf
;	aux
;	aux2

size   =  aux3

		;Compute size of resulting number 
		sty aux		; used to count later
		iny				;add space to result
		sty size
		
		;Zero the destination buffer
		lda #0
@		sta BUF-1,y
		dey
		bne @-
		
		;**** We convert the number byte a time
		sed
		
		;aux = varptr(aux)
bytes
		dec aux
		ldy aux
		lda VAR,y	
		.IF _SYS_PRINT_SIGNED = 1 
		eor ?sign
		.ENDIF	
		sta aux2
		sec				;set top bit to 1
		bcs loop		

shift_byte			
		ldx #0
		ldy size
@
		lda BUF,x
		adc	BUF,x			;buf2(x) = buf2(x) * 2 + carry
		sta BUF,x
		inx
		dey								;TODO: cpx ?size
		bne @-
			
		clc
loop	rol aux2		;divide by two, if result is 0, end
		bne shift_byte		
		
		lda aux
		bne bytes
	
		.IF _SYS_PRINT_SIGNED = 1 
		;If this is negative number, add 1
		;In case sign is $ff, asl will set the C to 1, otherwise to 0	
		lda ?sign
		asl
		ldx #0
@
		lda BUF,x
		adc #0
		sta BUF,x
		inx
		bcs @-
		.ENDIF
					
		cld		
		rts

.endp

.print "Print Size:", * - PRINTING_START
