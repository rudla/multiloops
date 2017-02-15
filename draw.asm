/*****************************************************************************
 
 Screen drawing 
 
*****************************************************************************/

DL_BLANK1  = $00
DL_BLANK2  = $10
DL_BLANK3  = $20
DL_BLANK4  = $30
DL_BLANK5  = $40
DL_BLANK6  = $50
DL_BLANK7  = $60
DL_BLANK8  = $70
DL_GR0     equ $2
DL_GR8     equ $e		;$f

DL_CHR_HIRES       = $2
DL_CHR_HIRES_10    = $3
DL_CHR_COLOR       = $4
DL_CHR_COLOR_TALL  = $5
DL_CHR_WIDE        = $6
DL_CHR_TALL_WIDE   = $7
    
DL_LMS     equ $40
DL_HSCROLL equ $10
DL_VSCROLL equ $20
DL_DLI     equ $80

DL_GOTO    =  $01
DL_END     =  $41


OVERLAY_X = (SCR_WIDTH-2)/2
OVERLAY_Y = (SCR_HEIGHT-2)/2
 
InitDL .PROC
;In:
;	a  graphics mode

		sta b1
		mwa #DL_BUF w1
		ldy #0
		
		lda #DL_BLANK8
		jsr PushByte
		jsr PushByte
		lda #DL_BLANK4
		jsr PushByte		
			
		lda b1
		ora #DL_LMS			;with address
		jsr PushByte
		lda #<SCREEN_BUF
		ldx #>SCREEN_BUF
		jsr Push2
		ldx #24
		lda b1
@		jsr PushByte					
    	dex
    	bne @-
		lda #DL_END
		jsr PushByte
		lda #<DL_BUF
		ldx #>DL_BUF
		jsr Push2	    	
		rts

Push2
		jsr PushByte
		txa
PushByte
		sta (w1),y
		iny
		rts				

.ENDP

ScreenAdr  .PROC
;a: x pos
;y: y pos

		clc
		adc scr_line_adr_l,y
		sta scr
		lda #0
		adc scr_line_adr_h,y
		sta scr+1
		rts		
.ENDP

ScrClear .PROC
		ldx #0
line	
		txa
		tay
		lda #0
		jsr ScreenAdr
		lda #0
		ldy #39
@		sta (scr),y
		dey
		bpl @-
		inx
		cpx #SCR_HEIGHT
		bne line
		rts
.ENDP

;Table of multiplication by 40 for screen
scr_line_adr_l
	:SCR_HEIGHT	dta l(#*SCR_WIDTH + SCREEN_BUF)
scr_line_adr_h
	:SCR_HEIGHT	dta h(#*SCR_WIDTH + SCREEN_BUF)
