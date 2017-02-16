ClockReset .PROC
;Purpose:
;	Initialize the clock.
;	Set time to 0.
		lda #0
		sta clock
		sta seconds
		sta minutes
		sta hours
		rts
		.ENDP

ClockTick  .PROC
;Purpose:
;	Call every tick to increment the clock.

		ldx #0
		inc clock
		lda clock
		cmp #TICKS_PER_SECOND
		bne clock_done		
		stx clock
		lda #60
		inc seconds
		cmp seconds
		bne clock_done
		stx seconds
		inc minutes
		cmp minutes
		bne clock_done
		stx minutes
		inc hours		
clock_done
		rts
		.ENDP

ClockWrite .PROC
;Purpose:
;	Write clock to screen.

		mwa #STATUS_BAR+20 scr

		lda hours
		jsr print_t
		lda #':'
		jsr PrintChar		
		lda minutes
		jsr print_t
		lda #':'
		jsr PrintChar
		lda seconds		
print_t
		sta var
		ldy #1
		jsr BinToBCD
		lda #2
		ldx #'0'
		jsr PrintHex
		rts
.ENDP