;Visualize player cursors using PMG.
;Every cursor uses one playser graphics.

InitCursors
;Cursors are positioned into corners

		mva #0 cursor_x
		mva #0 cursor_y				

		mva board_max_x cursor_x+1
		mva board_max_y cursor_y+1
		
		mva #0 cursor_x+2
		mva board_max_y cursor_y+2

		mva board_max_x cursor_x+3
		mva #0 cursor_y+3

;---- show all cursors
		ldx #0
@
		jsr CursorShow
		inx
		cpx #CURSOR_COUNT
		bne @-

		rts

HideCursors .PROC
		ldx #CURSOR_COUNT-1
@		jsr CursorHide
		dex
		bpl @-
		rts
.ENDP

CursorAdr .PROC
		txa
		clc
		adc #>PMG_BUF+4		;Y position in sprite
		sta scr+1
		lda cursor_y,x
		add board_y
		asl
		asl
		asl
		clc
		adc #28-(CURSOR_HEIGHT-8)/2
		sta scr
		rts
.ENDP


CursorHide  .PROC

		jsr CursorAdr
		lda #0
		ldy #0
@		sta (scr),y
		iny
		cpy #CURSOR_HEIGHT
		bne @-		
		rts
.ENDP

CursorShow  .PROC
;In:
;	x	cursor number

		lda cursor_x,x		;x position = x*4 + left_margin
		add board_x
		asl
		asl
		clc
		adc #48-1
		sta hposp0,x

		jsr CursorAdr
		lda #%11111100
		ldy #0
@		sta (scr),y
		iny
		cpy #CURSOR_HEIGHT
		bne @-		
		rts
.ENDP
