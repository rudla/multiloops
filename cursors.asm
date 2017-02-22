;Visualize player cursors using PMG.
;Every cursor uses one playser graphics.

CURSOR_TIMEOUT = 32		;measured in cca. 1/3 of a second
CURSOR_COUNT = 5
CURSOR_HEIGHT = 8+4


InitCursors .PROC
;Cursors are positioned into corners

		mva #0 cursor_x
		mva #0 cursor_y				

		mva board_max_x cursor_x+1
		mva board_max_y cursor_y+1
		
		mva #0 cursor_x+2
		mva board_max_y cursor_y+2

		mva board_max_x cursor_x+3
		mva #0 cursor_y+3

		;cursor no 4 is in the middle
		lda board_w 
		lsr
		sta cursor_x+4

		lda board_h
		lsr
		sta cursor_y+4

;---- show all cursors
		ldx #0
@
		mva #CURSOR_TIMEOUT cursor_status,x
		jsr CursorShow
		inx
		cpx #CURSOR_COUNT
		bne @-

		rts
		.ENDP

ShowCursors .PROC
		ldx #CURSOR_COUNT-1
@
		lda cursor_status,x
		beq skip
		jsr CursorShow
skip	dex
		bpl @-
		rts
		.ENDP

HideCursors .PROC
		ldx #CURSOR_COUNT-1
@		jsr CursorHide
		dex
		bpl @-
		rts
.ENDP

CursorAdr .PROC
		lda #>PMG_BUF+3
		cpx #4
		beq @+
		txa
		clc
		adc #>PMG_BUF+4		;Y position in sprite
@		sta scr+1
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
		adc #47
		cpx #4
		bne mis
		add #1
mis
		sta hposp0,x

		jsr CursorAdr
		
		ldy #0
@		lda curs_data,x
		eor (scr),y
		sta (scr),y
		iny
		cpy #CURSOR_HEIGHT
		bne @-		
		rts

curs_data	dta b(%11111100, %11111100,%11111100,%11111100,%00000011)
.ENDP
