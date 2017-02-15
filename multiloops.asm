; Multi Loops
;
; (c) 2017 Rudla Kudla

_SYS_PRINT_SIGNED = 0

SCR_WIDTH   =  40
SCR_HEIGHT  =  25

STATUS_LINE = 24

CURSOR_COUNT = 4
CURSOR_HEIGHT = 8

BOARD_WIDTH = 40
BOARD_HEIGHT = 25

timer = $14

b1 = 128
b2 = b1+1
w1 = b2+1
aux = w1+2
aux2 = aux+1
aux3 = aux2+1
var  = aux3+1

scr = var + 8
loose  = scr+2			;number of loose ends
board_w  = loose+2
board_h  = board_w+1
board_max_x = board_h+1
board_max_y = board_max_x+1

cursor_no = board_max_y+1

joy_cfg = cursor_no+1		;0 = normal joysticks, 1 = multijoy

;clock

TICKS_PER_SECOND = 50

clock = cursor_no + 1
seconds = clock+1
minutes = seconds+1
hours = minutes+1


;Direction flags
f_up = 1
f_right = 2
f_down = 4
f_left = 8


		icl "atari.hea"
		icl 'macros/init_nmi.mac'		

		org $2000
		
		mva #0 DMACTL
		init_nmi $14, nmi , $c0 

		mwa #DL_BUF DLPTR
		mva #%00111110 DMACTL

		ldx #3
@		lda cursor_color,x
		sta colpm0,x
		mva #0 sizep0,x
		dex
		bpl @-

		mva #1 joy_cfg

INTRO
		jsr ScrInit
		jsr InputInit
		jsr PmgInit

		lda #39
		ldy #24
		jsr SetBoardSize
		jsr ScrClear
		jsr GenerateBoard
		lda #<LoopsText
		ldy #>LoopsText
		jsr DrawText
		jsr WaitForKeyRelease

@		lda consol
		cmp #%110		;KEY_START
		bne @-
		
START
		jsr ScrInit
		jsr InputInit
		jsr PmgInit

		lda #39
		ldy #24
		jsr SetBoardSize
	
		jsr ScrClear
		jsr GenerateBoard

		jsr WaitForKeyRelease

		jsr ShuffleBoard

ResetCursors

		ldx #0
		mva #0 cursor_x,x
		mva #0 cursor_y,x				

		inx
		mva board_max_x cursor_x,x
		mva board_max_y cursor_y,x

		inx
		mva #0 cursor_x,x
		mva board_max_y cursor_y,x

		inx
		mva board_max_x cursor_x,x
		mva #0 cursor_y,x				

;---- show all cursors
		ldx #0
@
		jsr CursorShow
		inx
		cpx #CURSOR_COUNT
		bne @-

		jsr ClockReset
		jsr ClockWrite

GAME_LOOP
		lda timer
@		cmp timer
		beq @-
ret
		lda consol
		cmp #%110		;KEY_START
		bne no_start
		jmp START
no_start
;		cmp #%101		;KEY_SELECT
;		bne no_select
;		jsr ShuffleTile
;		jmp ret

no_select
		lda clock
		seq
		jsr ClockWrite
		jsr ReadJoysticks
		
		ldx #0
@		stx cursor_no
		jsr CursorMove
		ldx cursor_no
		inx
		cpx #CURSOR_COUNT
		bne @-

		jsr WriteLoose

		lda loose
		ora loose+1
		beq VICTORY

		jmp GAME_LOOP

VictoryText
	dta b(W_M, 10, 8)
	dta b(W_RECTANGLE, 20, 6)
	dta b(W_M, 4, 3)
	dta b(W_TEXT, 12, 'You have won')
	dta b(W_END)

VICTORY
		lda #<VictoryText
		ldy #>VictoryText
		jsr DrawText

wait_for_start
		sta wsync
		lda vcount
		adc timer
		sta colbak
		lda consol
		cmp #%110		;KEY_START
		bne wait_for_start
		jmp INTRO

DrawText  .PROC
		sta w1
		sty w1+1
		lda #0
		sta cursor_x
		sta cursor_y
;		mwa #LoopsText w1
;		mva #13 cursor_x
;		mva #8 cursor_y
;		mva #0 b1		;command
		mva #0 b2		;repeat

step
		ldx #0
		jsr CursorHide
		
		lda cursor_x
		sbc #1
		ldy cursor_y
		dey
		jsr TileAdr

		jsr read_byte
		cmp #W_END
		beq done
		cmp #W_M
		bne no_move
		jsr read_byte
		add cursor_x
		sta cursor_x
		jsr read_byte
		add cursor_y
		sta cursor_y
		jmp cursor_show
no_move
		cmp #W_TEXT
		bne no_text
		lda cursor_x
		ldy cursor_y
		jsr TileAdr
		jsr read_byte
		sta b1
@		jsr read_byte				
		jsr PrintChar
		dec b1
		bne @-
		jmp cursor_show

no_text
		cmp #W_RECTANGLE
		beq rect

		tax
		ldy #BOARD_WIDTH+1
		lda (scr),y
		ora DIR_BIT,x
		sta (scr),y
		ldy D_OFFSET,x
		lda (scr),y
		ora OPPOSITE_DIR,x
		sta (scr),y
		lda cursor_x
		add x_offset,x
		sta cursor_x
		lda cursor_y
		add y_offset,x
		sta cursor_y

cursor_show
		ldx #0
		jsr CursorShow
		lda consol
		and #%111
		cmp #%111
		bne @+
		lda #2
		jsr Pause
@		jmp step

done
		rts
read_2bytes
		jsr read_byte
		tax
read_byte
		ldy #0
		lda (w1),y
		inc w1
		sne
		inc w1+1
		rts
rect
		mva cursor_x b1
		mva cursor_y b2
		jsr read_2bytes
		stx aux
		sta aux2
		jsr Rectangle
		jmp step

.ENDP

Pause  .PROC
;Purpose:
;	Wait specified number of ticks.
;Input:
;	a	Number of ticks to wait

		add timer
@		cmp timer
		bne @-
		rts		
.ENDP


X_OFFSET
		dta b(0,1,0,-1)
Y_OFFSET
		dta b(-1,0,1,0)
D_OFFSET
		dta b(1, BOARD_WIDTH+2, 2*BOARD_WIDTH+1, BOARD_WIDTH)
DIR_BIT		
		dta b(f_up, f_right, f_down, f_left)
OPPOSITE_DIR
		dta b(f_down, f_left, f_up, f_right)

U = 0
R = 1
D = 2
L = 3
W_M = 4	;move x_off, y_off
W_END = 5
W_TEXT = 6
W_RECTANGLE = 7

LoopsText
	dta b(W_M, 3, 3)
	dta b(W_RECTANGLE, 20, 10)
	dta b(W_M, 4, 2)
	dta b(D,D,D,D,D,R,R,R,R)
	dta b(W_M, -1, -3)
	dta b(L,L,D,D,R,R,U,U,R)
	dta b(R,R,L,L,D,D,R,R,U,U,R)
	dta b(D,D,D,D,W_M,0,-4,R,R,D,D,L,L)
	dta b(R,R,R,R,R,U,L,L,U,R,R,R)

	dta b(W_M, -11, -2)
	dta b(W_TEXT, 5, 'multi')	
	dta b(W_END)

CursorMove .PROC
;In:
;		x cursor number

		lda button_state,x
		cmp prev_button_state,x
		beq no_button

		sta prev_button_state,x
		cmp #0
		beq no_button

		lda cursor_y,x
		tay
		lda cursor_x,x
		jsr RotateTile
		rts 

no_button
		lda joy_state,x
		cmp prev_joy_state,x
		beq no_move

		jsr CursorHide

		lda joy_state,x

		cmp #JOY_LEFT
		bne no_left
		lda cursor_x,x
		beq done
		dec cursor_x,x
		bpl done
no_left

		cmp #JOY_RIGHT
		bne no_right
		lda cursor_x,x		
		cmp board_max_x
		beq done
		inc cursor_x,x
		bpl done
no_right

		cmp #JOY_UP
		bne no_up
		lda cursor_y,x
		beq done
		dec cursor_y,x
		bpl done
no_up

		cmp #JOY_DOWN
		bne no_down
		lda cursor_y,x
		cmp board_max_y
		beq done
		inc cursor_y,x
		bpl done
no_down


done
		mva joy_state,x prev_joy_state,x
		jsr CursorShow
no_move
		rts		

.ENDP

CursorAdr .PROC
		txa
		clc
		adc #>PMG_BUF+4		;Y position in sprite
		sta scr+1
		lda cursor_y,x
		asl
		asl
		asl
		clc
		adc #48-20
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
		asl
		asl
		clc
		adc #48
		sta hposp0,x

		jsr CursorAdr
		lda #%11110000
		ldy #0
@		sta (scr),y
		iny
		cpy #CURSOR_HEIGHT
		bne @-		

;		lda cursor_y,x
;		tay
;		lda cursor_x,x
;		jsr ScreenAdr
;		ldy #0
;		lda (scr),y
;		eor #128
;		sta (scr),y
		rts
.ENDP

WriteLoose .PROC

		mwa loose var
		ldy #2
		jsr BinToBCD
		mwa #SCREEN_BUF+(STATUS_LINE*SCR_WIDTH) scr
		lda #4
		ldx #' '
		jsr PrintHex
		rts
.ENDP

Rectangle  .PROC
;Purpose:
;	Draw rectangle on board, connecting it outside with the maze.
;Input:
;	b1 - x
;	b2 - y
;	aux  - width
;	aux2 - heigh

		ldx #0
		jsr line

@		ldx #1
		jsr line
		dec aux2
		bne @-

		ldx #2
		;----- draw one line
line
		lda b1
		ldy b2
		jsr TileAdr

		ldy #0
		lda (scr),y
		and l_and,x
		ora l_or,x
		sta (scr),y
		iny
@		lda (scr),y
		and m_and,x
		ora m_or,x
		sta (scr),y
		iny
		cpy aux
		bne @-

		lda (scr),y
		and r_and,x
		ora r_or,x
		sta (scr),y

		inc b2
		rts

           ;top,            normal,     bottom

l_or  dta b(f_right+f_down, f_up+f_down, f_right+f_up)
l_and dta b($ff           , $ff-f_right, $ff)

m_or  dta b(f_left+f_right, 0          , f_left+f_right)
m_and dta b($ff-f_down,     0          , $ff-f_up)

r_or  dta b(f_left+f_down,  f_up+f_down, f_left+f_up)
r_and dta b($ff,            $ff-f_left,  $ff)


.ENDP


ScrInit .PROC

		mva #0 colpf1
		mva #10  colpf2
		mva #10  colbak
		mva #>FONT CHBASE		
		
		lda #DL_CHR_HIRES
		jmp InitDL
		.ENDP

		icl 'draw.asm'
		icl 'pmg.asm'
		icl 'input.asm'
		icl 'print.asm'
		icl 'clock.asm'
		icl 'board.asm'

.PROC nmi
		bit NMIST		; if this is VBI, jump to VBI code
		bmi dli
vbl

		pha
		txa
		pha
/*	
		lda joy_pause
		beq @+
		dec joy_pause
		bpl done
@		
		lda porta			;read joystick direction and button
		and #%1111
		eor #%1111
		ldx trig0
		ora trig_num,x
		ora joy_state
		sta joy_state
		
done

		lda skstat
		and #4
		beq has_key

		lda #KEY_NONE
		sta prev_key_state
		jmp key_done
has_key
		lda kbcode
		cmp prev_key_state
		beq key_done
	    sta key_state
		sta prev_key_state 
key_done
*/			    
		inc timer
		jsr ClockTick
	
		pla
		tax
		pla
		rti 

dli
;	pha
;	pla
		rti

;trig_num	.byte %00010000, %00000000
		
.ENDP

RomOff    .PROC
.ENDP

RomOn   .PROC

.ENDP

RomSwitchVars .PROC
;Purpose:
;	Exchange data between first 128 bytes of ZP (Variables used by ROM) and buffer.
;
		ldx #0
@       lda 0,x
		ldy zp_vars_backup,x
		sta zp_vars_backup,x
		tya
		sta 0,x		
		inx
		bpl @-
		rts
.ENDP

cursor_color
		dta b($1c, $b6, $47, $75)

		.align 1024		
FONT
		ins 'block.fnt'

		org FONT+8
							    ;    L D R U
							    ;0   0 0 0 0
		ins 'gfx/cu.bin'		;1   0 0 0 1  up
		ins 'gfx/cr.bin'		;2   0 0 1 0  right
		ins 'gfx/au.bin'		;3   0 0 1 1  up+right
		ins 'gfx/cd.bin'		;4   0 1 0 0  down

		ins 'gfx/vert.bin'		;5   0 1 0 1  down+up
		ins 'gfx/ar.bin'		;6   0 1 1 0  down+right
		ins 'gfx/tr.bin'		;7   0 1 1 1  down+up+right
		ins 'gfx/cl.bin'		;8   1 0 0 0  left
		ins 'gfx/al.bin'		;9   1 0 0 1  left+up
		ins 'gfx/horiz.bin'		;10  1 0 1 0  left+right
		ins 'gfx/tu.bin'		;11  1 0 1 1  left+up+right
		ins 'gfx/ad.bin'		;12  1 1 0 0  down+left
		ins 'gfx/tl.bin'		;13  1 1 0 1  up+down+left
		ins 'gfx/td.bin'		;14  1 1 1 0  right+down+left
		ins 'gfx/g.bin'			;15  1 1 1 1  all

		org FONT+1024

		.align 4096

PMG_BUF	.ds 2048


DL_BUF   .ds 50

		.ds SCR_WIDTH
SCREEN_BUF
		.ds SCR_WIDTH * SCR_HEIGHT
SCREEN_BUF_END
		.ds SCR_WIDTH

;Backup of zero page variables.
;This will be initialized when switching the OS off.
;
zp_vars_backup  .ds 128

cursor_x	.ds CURSOR_COUNT
cursor_y	.ds CURSOR_COUNT
joy_state	.ds CURSOR_COUNT
prev_joy_state	.ds CURSOR_COUNT
button_state	.ds CURSOR_COUNT
prev_button_state	.ds CURSOR_COUNT


board		.ds (BOARD_WIDTH+1)*(BOARD_HEIGHT+2)
done_board	.ds (BOARD_WIDTH+1)*(BOARD_HEIGHT+2)
ownership	.ds (BOARD_WIDTH+1)*(BOARD_HEIGHT+2)
buf     .ds 128
