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
		mwa #EMPTY_TOP scr
		ldx #0
line	
		ldy #39
		lda #0
@		sta (scr),y
		dey
		bpl @-
		adw scr #40
		inx
		cpx #SCR_HEIGHT+3
		bne line
		rts
.ENDP

TBL_HEIGHT = SCR_HEIGHT+3

;Table of multiplication by 40 for screen
scr_line_adr_l
	:TBL_HEIGHT	dta l(#*SCR_WIDTH + SCREEN_BUF)
scr_line_adr_h
	:TBL_HEIGHT	dta h(#*SCR_WIDTH + SCREEN_BUF)
