SetBoardSize .PROC
		;board size

		sty board_h
		dey
		sty board_max_y

		tay
		sty board_w
		dey
		sty board_max_x
		rts
.ENDP

GenerateBoard .PROC
		mva #20 b2
@		jsr AddToBoard
		dec b2
		bne @-
		lda #0
		sta loose
		sta loose+1
		rts
		.ENDP

AddToBoard  .PROC

		lda board_w
;		adc board_w
		sta b1
gen_hor

@		;y pos
		lda RANDOM
		and #31
		cmp board_h
		bcs @-
		tay

@		;x pos
		lda RANDOM
		and #63
		cmp board_max_x
		bcs @-

		jsr ScreenAdr

		ldy #0
		lda (scr),y
		ora #f_right
		sta (scr),y
		iny
		lda (scr),y
		ora #f_left
		sta (scr),y

		dec b1
		bne gen_hor

;------------------------
		lda board_w
;		adc board_w
		sta b1
gen_vert

@		;y pos
		lda RANDOM
		and #31
		cmp board_max_y
		bcs @-
		tay

@		;x pos
		lda RANDOM
		and #63
		cmp board_w
		bcs @-

		jsr ScreenAdr

		ldy #0
		lda (scr),y
		ora #f_down
		sta (scr),y

;		ldy #40
;		lda (scr),y
;		ora #f_up+f_down
;		sta (scr),y
		
		ldy #40
		lda (scr),y
		ora #f_up
		sta (scr),y

		dec b1
		bne gen_vert

		rts
		.ENDP

TileAdr  .PROC
		jmp ScreenAdr
.ENDP

ShuffleBoard .PROC
		mva #4 aux
a1		mva #255 b2
@		jsr ShuffleTile
		dec b2
		bne @-
		dec aux
		bne a1
		rts		
.ENDP

ShuffleTile .PROC
@		;y pos
		lda RANDOM
		and #31
		cmp board_h
		bcs @-
		tay

@		;x pos
		lda RANDOM
		and #63
		cmp board_w
		bcs @-

		jsr RotateTile

		rts
.ENDP

RotateTile  .PROC
;In:
;	a   x
;   y   y

		jsr TileAdr
		lda scr
		sec
		sbc #BOARD_WIDTH+1
		sta scr
		scs
		dec scr+1

		jsr LooseEnds

		stx b1			;loose = loose - x
		lda loose
		sec
		sbc b1
		sta loose
		scs
		dec loose+1

		ldy #BOARD_WIDTH+1
		lda (scr),y
		tax
		lda rot,x
		sta (scr),y		
		jsr LooseEnds

		txa			;loose =loose + x
		clc
		adc loose
		sta loose
		scc
		inc loose+1

		rts

;
;              +-------+
;         0    |  1    |
;              |       |
;      +-------+-------+-------+
;      |  BW   | BW+1  | BW+2  |
;      |       |       |       |
;      +-------+-------+-------+
;              | 2*BW+1|
;              |       |
;              +-------+

LooseEnds

		ldy #BOARD_WIDTH+1
		lda (scr),y
		sta b1

		ldx #0			;number of loose ends

		;DOWN
		ldy #1
		lda (scr),y		;down = 4
		and #f_down
		lsr
		lsr
		eor b1
		and #1
		beq no_up
		inx
no_up

		lsr b1
		;RIGHT
		ldy #BOARD_WIDTH+2
		lda (scr),y		;left = 8
		lsr
		lsr
		lsr
		eor b1
		and #1
		beq no_right
		inx
no_right		

		lsr b1
		;DOWN
		ldy #2*BOARD_WIDTH+1
		lda (scr),y		;up = 1
		eor b1
		and #1
		beq no_down
		inx
no_down		

		lsr b1
		;LEFT
		ldy #BOARD_WIDTH
		lda (scr),y		;right = 2
		lsr
		eor b1
		and #1
		beq no_left
		inx
no_left

		rts
.ENDP

rot
		dta b(%0000)  ;%0000
		dta b(%1000)  ;%0001
		dta b(%0001)  ;%0010
		dta b(%1001)  ;%0011

		dta b(%0010)  ;%0100
		dta b(%1010)  ;%0101
		dta b(%0011)  ;%0110
		dta b(%1011)  ;%0111

		dta b(%0100)  ;%1000
		dta b(%1100)  ;%1001
		dta b(%0101)  ;%1010
		dta b(%1101)  ;%1011

		dta b(%0110)  ;%1100
		dta b(%1110)  ;%1101
		dta b(%0111)  ;%1110
		dta b(%1111)  ;%1111
/*
		dta b(%0000)  ;%0000
		dta b(%0001)  ;%0001
		dta b(%0010)  ;%0010
		dta b(%0011)  ;%0011

		dta b(%0100)  ;%0100
		dta b(%0101)  ;%0101
		dta b(%0110)  ;%0110
		dta b(%0111)  ;%0111

		dta b(%1000)  ;%1000
		dta b(%1001)  ;%1001
		dta b(%1010)  ;%1010
		dta b(%1011)  ;%1011

		dta b(%1100)  ;%1100
		dta b(%1101)  ;%1101
		dta b(%1110)  ;%1110
		dta b(%1111)  ;%1111
*/		
