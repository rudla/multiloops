; Multi Loops
;
; (c) 2017 Rudla Kudla

DMA_MISSILES = 1
DMA_PLAYERS = 2

_SYS_PRINT_SIGNED = 0

SCR_WIDTH   =  40
SCR_HEIGHT  =  25

STATUS_LINE = 26
OWNERHIP_TOP_LINE = 27
OWNERSHIP_BASE = 64
BOARD_WIDTH = 40
BOARD_HEIGHT = 25

PAPER_COLOR = 10
CURSOR0_COLOR = $1c
CURSOR4_COLOR = $0F
STATUS_PAPER_COLOR = 8

timer = $14

b1 = 128
b2 = b1+1
w1 = b2+1
aux = w1+2
aux2 = aux+1
aux3 = aux2+1
var  = aux3+1

scr = var + 8

;Board state (position, size, number of loose ends)

board_size = scr+2			;0-n
loose  = board_size + 1		;number of loose ends
board_w  = loose+2
board_h  = board_w+1
board_max_x = board_h+1
board_max_y = board_max_x+1
board_x = board_max_y+1
board_y = board_x+1

cursor_no = board_y+1

joy_cfg = cursor_no+1		;0 = normal joysticks, 1 = multijoy
gfx_mode = joy_cfg+1
;clock

TICKS_PER_SECOND = 50

clock = gfx_mode + 1
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

		mwa #DLIST DLPTR
		mva #%00111110 DMACTL		;playfield_width_40+missile_dma+player_dma+pm_resolution_1+dl_dma

		jsr SetColors

		mva #1 joy_cfg
		mva #0 board_size

		jmp START		
INTRO
		ldx #BOARD_SIZE_MAX
		jsr InitBoardSize		;this actually sets the biggest board size (full screen)

		jsr ScrInit
		jsr InputInit
		jsr PmgInit
		
		jsr ScrClear
		jsr GenerateBoard
		lda #<LoopsText
		ldy #>LoopsText
		jsr DrawText
		jsr DrawConfig
;		jsr WaitForKeyRelease

@		jsr WaitForKey
		cmp #KEY_SELECT	;%101		;KEY_SELECT
		bne no_joy_sel
		lda joy_cfg
		eor #1
		sta joy_cfg
		jsr DrawConfig
		jsr WaitForKeyRelease
		jmp @-
no_joy_sel

		cmp #KEY_START	;%110		;KEY_START
		bne @-
		
START
		jsr ScrInit
		jsr InputInit
		jsr PmgInit	

		jsr ScrClear
		ldx board_size
		jsr InitBoardSize
		jsr GenerateBoard
		jsr WaitForKeyRelease
		jsr ShuffleBoard
;		jsr ShuffleTile
		jsr InitCursors

	;Initilaize clock
		jsr ClockReset
		jsr ClockWrite

GAME_LOOP
		lda timer
@		cmp timer
		beq @-
ret
		jsr GetKeyPressed
		cmp #KEY_START
		bne no_start
		jmp START
no_start
		cmp #KEY_SELECT
		bne no_select
		jsr NextBoardSize
		jmp START
no_select
		cmp #KEY_HELP
		bne no_help
		jsr HiliteLooseEnds
		jsr WaitForKeyRelease
		jsr HiliteLooseEnds
no_help
		cmp #KEY_OPTION
		bne no_option
		jsr ShowOwnership		
no_option

		lda clock
		seq
		jsr ClockWrite
		jsr ReadJoysticks
		
		ldx #0
@		stx cursor_no
		jsr PlayerMove
		ldx cursor_no
		inx
		cpx #CURSOR_COUNT
		bne @-

		jsr WriteLoose

		lda loose
		ora loose+1
		beq VICTORY

		jmp GAME_LOOP

ShowOwnership .PROC
		mwa #ownership DL_SCR_ADR
		mva #%10110001 gfx_mode		;switch mode to 9 color display and modify some color registers to propertly show the color map
		mva #PAPER_COLOR colpm0
		mva #CURSOR0_COLOR colpf0
		jsr HideCursors
		jsr WaitForKeyRelease
		lda #1
		jsr Pause
		mwa #SCREEN_BUF DL_SCR_ADR
		jsr SetColors
		jmp ShowCursors
.ENDP

VictoryText
		dta b(W_M, 0, STATUS_LINE)
;		dta b(W_RECTANGLE, 20, 6)
;		dta b(W_M, 4, 3)
		dta b(W_TEXT, 12, 'You have won')
		dta b(W_END)

VICTORY
		lda #<VictoryText
		ldy #>VictoryText
		jsr DrawText
		jsr HideCursors

wait_for_start
		sta wsync
		lda vcount
		adc timer
		sta colbak
		jsr GetKeyPressed
		;cmp #%110		;KEY_START
		beq wait_for_start
		jmp INTRO

DrawText  .PROC
		sta w1
		sty w1+1
		lda #0
		sta cursor_x
		sta cursor_y
		mva #0 b2		;repeat

step
		ldx #0
		jsr CursorHide
		
		lda cursor_x
		sbc #1
		ldy cursor_y
		dey
		jsr ScreenAdr

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
		jsr ScreenAdr
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
		jsr GetKeyPressed
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
	dta b(W_M, 0, 8)
	dta b(W_TEXT, 14, 'by Rudla Kudla')	
	
	dta b(W_END)

PlayerMove .PROC
;In:
;		x cursor number

		lda button_state,x
		cmp prev_button_state,x
		beq no_button

		sta prev_button_state,x
		cmp #0
		beq no_button

		lda cursor_status,x
		beq show_cursor

		mva #CURSOR_TIMEOUT  cursor_status,x

		lda cursor_y,x
		tay
		lda cursor_x,x
		jsr RotateTile

;record owhership of the tile

		ldx cursor_no
		lda #OWNERHIP_TOP_LINE
		add cursor_y,x
		tay
		lda cursor_x,x
		jsr TileAdr
		lda cursor_no
		add #OWNERSHIP_BASE
		ldy #0
		sta (scr),y
		rts
		;---- 

no_button
		lda joy_state,x
		cmp prev_joy_state,x
		beq no_move

		lda cursor_status,x	;if cursor is hidden, first show it (without any aother action)
		beq done

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
show_cursor
		mva #CURSOR_TIMEOUT  cursor_status,x
		jsr CursorShow
		rts		

no_move
		lda timer
		and #%00001111
		bne no_time
		lda cursor_status,x
		beq no_time
		dec cursor_status,x
		sne
		jsr CursorHide
no_time	rts
.ENDP


WriteLoose .PROC

		mwa loose var
		ldy #2
		jsr BinToBCD
		mwa #STATUS_BAR scr
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
		jsr ScreenAdr

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

ConfigText

	dta b(W_M, 10, 16)
	dta b(W_RECTANGLE, 22, 4)
	dta b(W_M, 1, 1)
	dta b(W_TEXT, 20, 'Joysticks:  Standard')
	dta b(W_M, 12, 1)
	dta b(W_TEXT, 8, 'Multijoy')
	dta b(W_END)

DrawConfig  .PROC
		lda #<ConfigText
		ldy #>ConfigText
		jsr DrawText

		ldx #1
		jsr CursorHide

		lda #17
		clc
		adc joy_cfg
		sta cursor_y+1

		lda #22
		sta cursor_x+1
		ldx #1
		jsr CursorShow

;		jsr ScreenAdr
;		lda #'*'
;		ldy #0
;		sta (scr),y
		

		rts
.ENDP

ScrInit .PROC

		mva #>FONT CHBASE		
		
;		lda #DL_CHR_HIRES
;		jmp InitDL
		rts
		.ENDP

		icl 'draw.asm'
		icl 'pmg.asm'
		icl 'input.asm'
		icl 'keyboard.asm'
		icl 'print.asm'
		icl 'clock.asm'
		icl 'board.asm'
		icl 'cursors.asm'

.PROC nmi
		bit NMIST		; if this is VBI, jump to VBI code
		bmi dli
vbl

		pha
		txa
		pha
		mva #PAPER_COLOR colpf2
		mva gfx_mode GTICTL
		inc timer
		jsr ClockTick
		pla
		tax
		pla
		rti 

dli
		pha
		mva #%00110001 GTICTL
		mva #STATUS_PAPER_COLOR colpf2
		pla
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

SetColors	.PROC

		mva #%00110001 gfx_mode
		sta GTICTL

		mva #0 colpf1
		mva #PAPER_COLOR  colpf2
		mva #PAPER_COLOR  colbak

		ldx #3
@		lda cursor_color,x
		sta colpm0,x
		mva #0 sizep0,x
		dex
		bpl @-
		mva cursor_color+4 colpf3
		rts
		.ENDP

cursor_color
		dta b(CURSOR0_COLOR, $b6, $47, $77, CURSOR4_COLOR)

DLIST
		dta b(DL_BLANK8,DL_BLANK8,DL_BLANK4)
		dta b(DL_CHR_HIRES+DL_LMS)
DL_SCR_ADR
		dta a(SCREEN_BUF)
		:23 dta b(DL_CHR_HIRES)
		dta b(DL_BLANK1+DL_DLI)
		dta b(DL_CHR_HIRES+DL_LMS)		;status bar
		dta a(STATUS_BAR)
		dta b(DL_END)
		dta a(DLIST)

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

		org FONT+OWNERSHIP_BASE*8

		:8 dta b(%01000100)			;cursor 0
		:8 dta b(%00010001)			;cursor 1
		:8 dta b(%00100010)			;cursor 2
		:8 dta b(%00110011)			;cursor 3
		:8 dta b(%01110111)			;cursor 4	colpf3

		org FONT+1024

		.align 4096

PMG_BUF	.ds 2048

EMPTY_TOP
		.ds SCR_WIDTH
SCREEN_BUF
		.ds SCR_WIDTH * SCR_HEIGHT
SCREEN_BUF_END
		.ds SCR_WIDTH

STATUS_BAR .ds SCR_WIDTH

ownership	.ds SCR_WIDTH * SCR_HEIGHT		;1-8 is number of a player that owns this tile

;Backup of zero page variables.
;This will be initialized when switching the OS off.
;
zp_vars_backup  .ds 128

cursor_x	.ds CURSOR_COUNT
cursor_y	.ds CURSOR_COUNT
cursor_status .ds CURSOR_COUNT		;when not zero, this value decrements every second

joy_state	.ds CURSOR_COUNT
prev_joy_state	.ds CURSOR_COUNT
button_state	.ds CURSOR_COUNT
prev_button_state	.ds CURSOR_COUNT


board		.ds (BOARD_WIDTH+1)*(BOARD_HEIGHT+2)
done_board	.ds (BOARD_WIDTH+1)*(BOARD_HEIGHT+2)
buf     .ds 128
