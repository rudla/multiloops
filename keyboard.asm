;Keyboard support.
;
;Keyboard codes are generally returned as ascii values of coresponding keys.
;Letters are returned as upper case.

MODULE_KEYBOARD

KEY_NONE  = 0		;returned when no key is pressed

BACKSPACE = $7e
ESC       = 27
SPACE     = 32
ENTER     = 10
TAB       = 9

KEY_CAPS_LOCK = $7f
KEY_INV   = $7e

KEY_START  = 1
KEY_SELECT = 2
KEY_OPTION = 3
KEY_HELP   = 4

;Special keys
KEY_F1 = 5
KEY_F2 = 6
KEY_F3 = 7
KEY_F4 = 8

;Shift keys
KEY_SHIFT     = 1
KEY_CTRL      = 2

GetKeyPressed  .PROC
;Purpose:
;	Return currently pressed key and state of shift keys (SHIFT, CTRL).
;	The key is returned as ascii code.
;	If no key is pressed 
;   START,SELECT,OPTION and HELP are returned as 1,2,3,4 respectively.
;   
;Result:
;	a  pushed key
;	X  shift state (shift may be returned as pushed even if no key is pressed)
;	Z  set if no key (not even shift) is currently pushed

		lda skstat			;test, if any key is pressed
		and #4
		bne consol_key

		lda kbcode			;yes, convert it
		and #%00111111		;ignore ctrl and shift state for now
		tax
		lda key_to_ascii,x

		ldx kbcode			;[CTRL]
		bpl no_ctrl
		ldx #KEY_CTRL
		bne shift
consol_key
		ldx consol			;[OPTION], [SELECT], [START]
		lda consol_tbl,x
no_ctrl
		ldx #KEY_NONE
shift
		pha
		lda skstat			;[SHIFT] - we read it from skstat to be able to get it even without any other key pressed
		and #8
		bne @+
		inx
@		pla
		sne					;if no key, test if shift is empty
		cpx #0
		rts

consol_tbl
	         ;%000       %001        %010        %011        %100       %101       %110        %111
		dta b(KEY_START, KEY_SELECT, KEY_START,  KEY_OPTION, KEY_START, KEY_SELECT, KEY_START, KEY_NONE)

.ENDP

WaitForKeyRelease .PROC
@		jsr GetKeyPressed
		bne @-
		rts
.ENDP


WaitForKey  .PROC
;Purpose:
;	Wait until user presses a key.
;Result:
;	a  pushed key
;	x  shift state

		jsr WaitForKeyRelease
rep
		ldy #2
@		jsr GetKeyPressed
		beq rep
		pha
		lda timer
wait	cmp timer
		beq wait
		pla
		dey
		bne @-
		rts
.ENDP
/*
GetKey .PROC
;Purpose:
;	Return currently pressed key.
;Result:
;	a  pushed key (0 if no key is pushed)
;	X  shift state
;	Z  set if no key is currently pushed

;Test START, OPTION, SELECT

		lda $d01f
		eor #$07
		beq no_consol
		tax
		lda CONSOL_TBL-1,x

;We want to support SHIFT for these keys 
shift		
		pha
		ldx #0
		lda $d20f
		and #8
		sne
		inx
		pla
		rts

CONSOL_TBL 
	         ;%000       %001        %010        %011        %100       %101        %110        %111
		dta b(KEY_START, KEY_SELECT, KEY_START,  KEY_OPTION, KEY_START, KEY_SELECT, KEY_START, KEY_NONE)

no_consol
		lda 764
		cmp #$FF
		bne key
		lda #0
		jsr shift
		cpx #0
		rts

key		
		and #63
		tax
		lda key_to_ascii,x
		pha
		lda 764		;get shift state into X
		ldx #$FF
		stx 764
		rol
		rol
		rol
		and #3
		tax
		pla		 
		rts
.ENDP
*/
key_to_ascii

	dta	'L'    ;$00 - l
	dta	'J'	   ;$01 - j
	dta	';'	   ;$02 - semicolon
	dta	KEY_F1 ;$03 - F1
	dta	KEY_F2 ;$04 - F2
	dta	'K'	   ;$05 - k
	dta	'+'	   ;$06 - +
	dta	'*'	   ;$07 - *
	dta	'O'	   ;$08 - o
	dta	0	   ;$09 - (invalid)
	dta	'P'	   ;$0A - p
	dta	'U'	   ;$0B - u
	dta	ENTER  ;$0C - return
	dta	'I'	   ;$0D - i
	dta	'-'	   ;$0E - -
	dta	'='	   ;$0F - =

	dta	'V'	   ;$10 - v
	dta	KEY_HELP ;$11 - HELP
	dta	'C'	   ;$12 - c
	dta	KEY_F3 ;$13 - F3
	dta	KEY_F4 ;$14 - F4
	dta	'B'	   ;$15 - b
	dta	'X'	   ;$16 - x
	dta	'Z'	   ;$17 - z
	dta	'4'	   ;$18 - 4
	dta	0	   ;$19 - (invalid)
	dta	'3'	   ;$1A - 3
	dta	'6'	   ;$1B - 6
	dta	ESC	   ;$1C - escape
	dta	'5'	   ;$1D - 5
	dta	'2'	   ;$1E - 2
	dta	'1'	   ;$1F - 1
   
	dta	','	   ;$20 - comma
	dta	SPACE  ;$21 - space
	dta	'.'	   ;$22 - period
	dta	'N'	   ;$23 - n
	dta	0	   ;$24 - (invalid)
	dta	'M'	   ;$25 - m
	dta	'/'	   ;$26 -    /
	dta	KEY_INV	;$27 - inverse
	dta	'R'	   ;$28 - r
	dta	0	   ;$29 - (invalid)
	dta	'E'	   ;$2A - e
	dta	'Y'	   ;$2B - y
	dta	TAB	   ;$2C - tab
	dta	'T'	   ;$2D - t
	dta	'W'	   ;$2E - w
	dta	'Q'	   ;$2F -    q

	dta	'9'	   ;$30 - 9
	dta	0	   ;$31 - (invalid)
	dta	'0'	   ;$32 - 0
	dta	'7'	   ;$33 - 7
	dta	BACKSPACE	;$34 - backspace
	dta	'8'	   ;$35 - 8
	dta	'<'	   ;$36 - <
	dta	'>'	   ;$37 - >
	dta	'F'	   ;$38 - f
	dta	'H'	   ;$39 - h
	dta	'D'	   ;$3A - d
	dta	0	   ;$3B - (invalid)
	dta	KEY_CAPS_LOCK	;$3C - CAPS
	dta	'G'	   ;$3D - g
	dta	'S'	   ;$3E - s
	dta	'A'	   ;$3F - a
   
   .print "Keyboard:", *-MODULE_KEYBOARD
