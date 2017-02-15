;Initialize PMG
PmgInit		.PROC

		mva #>PMG_BUF PMBASE
		mva #3 PMCNTL			;players + missiles
		mva #%00110001 GTICTL

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
