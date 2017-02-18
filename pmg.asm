;Initialize PMG
PmgInit		.PROC

		mva #>PMG_BUF PMBASE
		mva #%00000011 PMCNTL			;players + missiles
		mva #%00110001 GTICTL			;multicolor_player + fifth_player
		mva #%01010101 SIZEM			;quadruple size of missiles

        ;Erase PMG
		mwa #PMG_BUF scr
		ldx #8
@t		ldy #0
@		lda #$0
		sta (scr),y
		iny
		lda #$0
		sta (scr),y
		iny		
		bne @-
		inc scr+1
		dex
		bne @t            

		rts

		.ENDP
