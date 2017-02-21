JOY_LEFT  = %1011
JOY_RIGHT = %0111
JOY_UP    = %1110
JOY_DOWN  = %1101
JOY_NONE  = %1111

InputInit .PROC

	ldx #CURSOR_COUNT-1
@	lda #JOY_NONE
	sta prev_joy_state,x
	sta joy_state,x

	lda #1
	sta prev_button_state,x
	sta button_state,x
	dex
	bpl @-

	jsr InitMultiJoy
	
	rts
.ENDP

ReadNormalJoy .PROC
	lda porta
	and #%1111
	sta joy_state
	lda porta
	lsr
	lsr
	lsr
	lsr
	sta joy_state+1
	lda trig0
	sta button_state
	lda trig1
	sta button_state+1
	rts
.ENDP

InitMultiJoy .PROC
		lda joy_cfg
		beq normal_joy
		LDA #$30	   ; clear BIT 2 of PACTL (direction control register)
		STA $D302      ;PACTL, control read/write direction with PORTA		
		LDA #$00	   ; 4 upper bits=OUT (Joystick 1),4 lower bits=IN (Joystick 0)
		ldx joy_state
		beq normal_joy
		LDA #$F0
joy_state		
		STA $D300      ;PORTA, set directions
		mva #$34  $D302 ; restore OS default value for PACTL 
normal_joy
		rts
.ENDP

ReadMultiJoy .PROC

		ldx #CURSOR_COUNT-1
loop
		txa		  ;joystick number
		asl
		asl 
		asl 
		asl 
		sta porta  ;Select joystick
		ldy #$06   ;Here is a delay 30 cycles before reading of PORTA
@		dey
		bne @-
	    
	    lda trig0
		sta button_state,x
 
		lda porta
	    and #$0f
	    sta joy_state,x	    

	    lda #$ff   ;inicializace všech
	    sta porta  ;PORTA výstupů na 1
    
    	dex
    	bpl loop
    
		rts

.ENDP

;	.IF .DEF joy_cfg

ReadJoysticks .PROC
		lda joy_cfg
		beq normal_joy
		jmp ReadMultiJoy
normal_joy
		jmp ReadNormalJoy
	.ENDP
;	.ELSE
;	ReadJoysticks = ReadNormalJoy

;	.ENDIF
