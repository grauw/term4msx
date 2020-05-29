;
; Terminal routines
;
Terminal_PENDING_GRAPHIC: equ -1     ; ^A
Terminal_PENDING_ESCAPE: equ -2      ; ESC
Terminal_PENDING_ESCAPE_CSI: equ -3  ; ESC [  Control Sequence Introducer
Terminal_PENDING_ESCAPE_X: equ -4    ; ESC x
Terminal_PENDING_ESCAPE_Y: equ -5    ; ESC y
Terminal_PENDING_ESCAPE_VT100_Y: equ -6    ; ESC Y
Terminal_PENDING_ESCAPE_VT100_Y2: equ -7    ; ESC Y<x>

; a = character
Terminal_PrintCharacter:
	cp 20H
	jp c,Terminal_ControlCharacter
	cp 7FH
	jp z,Terminal_Backspace
	ld d,a
	ld a,(Terminal_pendingEscape)
	and a
	jp nz,Terminal_PendingEscapeContinue
; a = glyph
; d = glyph
Terminal_PrintGlyph:
	ld a,(Terminal_cursorX)
	ld b,a
	add a,a
	add a,b
	add a,9
	add a,a
	ld (Terminal_glyphCommand + 4),a  ; dx
	ld a,0
	rla
	ld (Terminal_glyphCommand + 5),a  ; dx
	ld a,(Terminal_scroll)
	ld b,a
	ld a,(Terminal_cursorY)
	add a,a
	add a,a
	add a,a
	add a,b
	ld (Terminal_glyphCommand + 6),a  ; dy
	ld a,0C0H  ; HMMV
	ld (Terminal_glyphCommand + 14),a  ; command
	ld a,(Terminal_backgroundColor)
	ld (Terminal_glyphCommand + 12),a  ; color
	ld hl,Terminal_glyphCommand
	call VDP_ExecuteCommand
	ld a,d
	cp " "
	jr z,Terminal_AdvanceCursor
	and 3FH
	add a,a
	add a,a
	add a,a
	ld (Terminal_glyphCommand + 0),a  ; sx
	ld a,0
	rla
	ld (Terminal_glyphCommand + 1),a  ; sx
	ld a,(Terminal_foregroundColor)
	ld b,a
	cp 9
	jp c,Terminal_PrintGlyph_Bright
	ld a,d
	and 0C0H
	ld e,a
	ld a,15
	sub b
	or e
	rrca
	rrca
	rrca
	ld (Terminal_glyphCommand + 2),a  ; sy
Terminal_PrintGlyph_BrightContinue:
	ld a,(Terminal_backgroundColor)
	dec a
	ld a,0D0H  ; HMMM
	jr z,Terminal_PrintGlyph_OnBlack
	ld a,98H  ; LMMM TIMP
Terminal_PrintGlyph_OnBlack:
	ld (Terminal_glyphCommand + 14),a  ; command
	ld hl,Terminal_glyphCommand
	call VDP_ExecuteCommand
Terminal_AdvanceCursor:
	ld a,(Terminal_cursorX)
	inc a
	ld (Terminal_cursorX),a
	cp 80
	ret c
	xor a
	ld (Terminal_cursorX),a
	jp Terminal_LineFeed

; a = foreground color
; d = glyph
Terminal_PrintGlyph_Bright:
	push bc
	push de
	ld e,a
	ld a,(Terminal_backgroundColor)
	dec a
	jp z,Terminal_PrintGlyph_BrightOnBlack
	ld hl,(Terminal_glyphCommand + 0)  ; sx
	ld (Terminal_brightGlyphCommand + 0),hl  ; sx
	ld a,d
	and 0C0H
	rrca
	rrca
	rrca
	ld (Terminal_brightGlyphCommand + 2),a  ; sy
	ld a,0D0H  ; HMMM
	ld (Terminal_brightGlyphCommand + 14),a
	ld hl,Terminal_brightGlyphCommand
	call VDP_ExecuteCommand
	ld d,0
	ld hl,Terminal_ansiPaletteMapping
	add hl,de
	ld a,(hl)
	ld (Terminal_brightGlyphCommand + 12),a  ; color
	ld a,81H  ; LMMV AND
	ld (Terminal_brightGlyphCommand + 14),a  ; command
	ld hl,Terminal_brightGlyphCommand
	call VDP_ExecuteCommand
	xor a
	ld (Terminal_glyphCommand + 0),a  ; sx
	ld (Terminal_glyphCommand + 1),a  ; sx
	ld a,0E0H
	ld (Terminal_glyphCommand + 2),a  ; sy
	pop de
	pop bc
	jp Terminal_PrintGlyph_BrightContinue
Terminal_PrintGlyph_BrightOnBlack:
	ld a,d
	and 0C0H
	rrca
	rrca
	rrca
	ld (Terminal_glyphCommand + 2),a  ; sy
	ld a,0D0H  ; HMMM
	ld (Terminal_glyphCommand + 14),a  ; command
	ld hl,Terminal_glyphCommand
	call VDP_ExecuteCommand
	ld d,0
	ld hl,Terminal_ansiPaletteMapping
	add hl,de
	ld a,(hl)
	ld (Terminal_glyphCommand + 12),a  ; color
	ld a,81H  ; LMMV AND
	ld (Terminal_glyphCommand + 14),a  ; command
	ld hl,Terminal_glyphCommand
	call VDP_ExecuteCommand
	pop de
	pop bc
	jp Terminal_AdvanceCursor

; a = character
Terminal_ControlCharacter:
	cp 1
	jp z,Terminal_Graphic
	cp 5
	jp z,Terminal_ClearLineFromCursor
	cp 7
	jp z,Terminal_Bell
	cp 8
	jp z,Terminal_Backspace
	cp 9
	jp z,Terminal_Tab
	cp 10
	jp z,Terminal_LineFeed
	cp 11
	jp z,Terminal_Home
	cp 12
	jp z,Terminal_ClearScreen
	cp 13
	jp z,Terminal_Return
	cp 27
	jp z,Terminal_Escape
	ret

; a = pending type
; d = character
Terminal_PendingEscapeContinue:
	inc a
	jp z,Terminal_GraphicContinue
	inc a
	jp z,Terminal_EscapeContinue
	inc a
	jp z,Terminal_ControlSequenceContinue
	inc a
	jp z,Terminal_EscapeXContinue
	inc a
	jp z,Terminal_EscapeYContinue
	inc a
	jp z,Terminal_VT100_SetCursorPositionContinue
	inc a
	jp z,Terminal_VT100_SetCursorPositionContinue2

Terminal_Graphic:
	ld a,Terminal_PENDING_GRAPHIC
	ld (Terminal_pendingEscape),a
	ret

Terminal_Escape:
	ld a,Terminal_PENDING_ESCAPE
	ld (Terminal_pendingEscape),a
	ret

; d = character
Terminal_GraphicContinue:
	xor a
	ld (Terminal_pendingEscape),a
	ld a,d
	sub "@"
	ld d,a
	jp Terminal_PrintGlyph

; d = character
Terminal_EscapeContinue:
	ld a,d
	cp "x"
	jp z,Terminal_EscapeX
	cp "y"
	jp z,Terminal_EscapeY
	cp "Y"
	jp z,Terminal_VT100_SetCursorPosition
	cp "["
	jp z,Terminal_ControlSequence
	call Terminal_ControlSequence
	jp Terminal_ControlSequenceContinue

Terminal_ControlSequence:
	ld a,Terminal_PENDING_ESCAPE_CSI
	ld (Terminal_pendingEscape),a
	ld hl,Terminal_buffer
	ld (Terminal_bufferPosition),hl
	ret

; d = character
Terminal_ControlSequenceContinue:
	ld hl,(Terminal_bufferPosition)
	ld (hl),d
	inc hl
	ld (Terminal_bufferPosition),hl
	ld a,d
	cp "@"
	ret c
	xor a
	ld (Terminal_pendingEscape),a
	ld hl,Terminal_buffer
	ld a,d
	cp "A"
	jp z,Terminal_ANSI_MoveCursor
	cp "B"
	jp z,Terminal_ANSI_MoveCursor
	cp "C"
	jp z,Terminal_ANSI_MoveCursor
	cp "D"
	jp z,Terminal_ANSI_MoveCursor
	cp "H"
	jp z,Terminal_ANSI_SetCursorPosition
	cp "f"
	jp z,Terminal_ANSI_SetCursorPosition
	cp "s"
	jp z,Terminal_ANSI_SaveCursorPosition
	cp "n"
	cp "u"
	jp z,Terminal_ANSI_RestoreCursorPosition
	cp "`"
	cp "a"
	cp "d"
	cp "e"
	cp "F"
	cp "E"
	jp z,Terminal_ClearScreen
	cp "Z"
	cp "L"
	jp z,Terminal_ANSI_InsertLine
	cp "@"
	cp "M"
	jp z,Terminal_ANSI_DeleteLine
	cp "P"
	cp "J"
	jp z,Terminal_ANSI_ClearScreen
	cp "K"
	jp z,Terminal_ANSI_ClearLine
	cp "X"
	cp "S"
	jp z,Terminal_ANSI_Scroll
	cp "T"
	jp z,Terminal_ANSI_Scroll
	cp "m"
	jp z,Terminal_SGR_SetAttributes
	ret

Terminal_Backspace:
	ld a,(Terminal_cursorX)
	sub 1
	ld (Terminal_cursorX),a
	ret nc
	ld a,80 - 1
	ld (Terminal_cursorX),a
	ld a,(Terminal_cursorY)
	sub 1
	ld (Terminal_cursorY),a
	ret nc
	xor a
	ld (Terminal_cursorY),a
	ld (Terminal_cursorX),a
	ret

Terminal_Tab:
	ld a,(Terminal_cursorX)
	ld b,a
	add a,8
	and ~7
	sub b
	ld b,a
Terminal_Tab_Loop:
	push bc
	ld a," "
	call Terminal_PrintCharacter
	pop bc
	djnz Terminal_Tab_Loop
	ret

Terminal_LineFeed:
	ld a,(Terminal_cursorY)
	inc a
	ld (Terminal_cursorY),a
	cp 24
	ret c
	dec a
	ld (Terminal_cursorY),a
Terminal_ScrollLine:
	ld a,(Terminal_scroll)
	add a,8
	ld (Terminal_scroll),a
	add a,26 * 8
	ld (Terminal_clearLinesCommand + 6),a  ; dy
	ld a,8
	ld (Terminal_clearLinesCommand + 10),a  ; ny
	ld a,(Terminal_scrollSpeed)
	ld (Terminal_scrollStep),a
	ld hl,Terminal_clearLinesCommand
	jp VDP_ExecuteCommand

Terminal_Bell:
	ld iy,(EXPTBL - 1)
	ld ix,BEEP
	jp CALSLT

Terminal_Home:
	xor a
	ld (Terminal_cursorX),a
	ld (Terminal_cursorY),a
	ret

Terminal_ClearScreen:
	xor a
	ld (Terminal_cursorX),a
	ld (Terminal_cursorY),a
	ld (Terminal_scroll),a
	ld (Interrupt_currentScroll),a
	di
	out (VDP_PORT + 1),a
	ld a,23 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,(VDP_registers + 1)
	and ~40H  ; clear BL
	out (VDP_PORT + 1),a
	ld a,1 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ld hl,Terminal_clearScreenCommand
	call VDP_ExecuteCommand
	call VDP_WaitCommandReady
	ld a,(VDP_registers + 1)
	di
	out (VDP_PORT + 1),a
	ld a,1 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ret

Terminal_Return:
	xor a
	ld (Terminal_cursorX),a
	ret

; hl = control sequence buffer
Terminal_ANSI_Scroll:
	ld a,(hl)
	cp "A"
	ld b,1
	jp nc,Terminal_ANSI_Scroll_Continue
	inc hl
	sub "0"
	ld b,a
	ld a,(hl)
	cp "A"
	jp nc,Terminal_ANSI_Scroll_Continue
	inc hl
	sub "0"
	ld c,a
	ld a,b
	add a,a
	ld b,a
	add a,a
	add a,a
	add a,b
	add a,c
	ld b,a
Terminal_ANSI_Scroll_Continue:
	ld a,(hl)
	inc hl
	cp "S"
	jp z,Terminal_ANSI_ScrollUp
	jp Terminal_ANSI_ScrollDown
Terminal_ANSI_ScrollUp:
	push bc
	call Terminal_ScrollLine
	pop bc
	djnz Terminal_ANSI_ScrollUp
	ret
Terminal_ANSI_ScrollDown:
	push bc
	call Terminal_ScrollLineDown
	pop bc
	djnz Terminal_ANSI_ScrollDown
	ret

Terminal_ScrollLineDown:
	ld a,(Terminal_scroll)
	sub 8
	ld (Terminal_scroll),a
	ld (Terminal_clearLinesCommand + 6),a  ; dy
	ld a,8
	ld (Terminal_clearLinesCommand + 10),a  ; ny
	ld a,(Terminal_scrollSpeed)
	cpl
	inc a
	ld (Terminal_scrollStep),a
	ld hl,Terminal_clearLinesCommand
	call VDP_ExecuteCommand
	ld a,(Terminal_scroll)
	add a,24 * 8
	ld (Terminal_clearLinesCommand + 6),a
	ld a,8
	ld (Terminal_clearLinesCommand + 10),a
	ld hl,Terminal_clearLinesCommand
	jp VDP_ExecuteCommand

; hl = control sequence buffer
Terminal_ANSI_MoveCursor:
	ld a,(hl)
	cp "A"
	ld b,1
	jp nc,Terminal_ANSI_MoveCursor_Continue
	inc hl
	sub "0"
	ld b,a
	ld a,(hl)
	cp "A"
	jp nc,Terminal_ANSI_MoveCursor_Continue
	inc hl
	sub "0"
	ld c,a
	ld a,b
	add a,a
	ld b,a
	add a,a
	add a,a
	add a,b
	add a,c
	ld b,a
Terminal_ANSI_MoveCursor_Continue:
	ld a,(hl)
	inc hl
	cp "B"
	jp c,Terminal_MoveCursorUp
	jp z,Terminal_MoveCursorDown
	cp "C"
	jp z,Terminal_MoveCursorRight
	jp Terminal_MoveCursorLeft

; b = amount
Terminal_MoveCursorUp:
	ld a,(Terminal_cursorY)
	sub b
	ld (Terminal_cursorY),a
	ret nc
	xor a
	ld (Terminal_cursorY),a
	ret

; b = amount
Terminal_MoveCursorDown:
	ld a,(Terminal_cursorY)
	add a,b
	ld (Terminal_cursorY),a
	cp 24
	ret c
	ld a,23
	ld (Terminal_cursorY),a
	ret

; b = amount
Terminal_MoveCursorRight:
	ld a,(Terminal_cursorX)
	add a,b
	ld (Terminal_cursorX),a
	cp 80
	ret c
	ld a,79
	ld (Terminal_cursorX),a
	ret

; b = amount
Terminal_MoveCursorLeft:
	ld a,(Terminal_cursorX)
	sub b
	ld (Terminal_cursorX),a
	ret nc
	xor a
	ld (Terminal_cursorX),a
	ret

; hl = control sequence buffer
Terminal_ANSI_SaveCursorPosition:
	ld a,(Terminal_cursorX)
	ld (Terminal_cursorXSaved),a
	ld a,(Terminal_cursorY)
	ld (Terminal_cursorYSaved),a
	ret

; hl = control sequence buffer
Terminal_ANSI_RestoreCursorPosition:
	ld a,(Terminal_cursorXSaved)
	ld (Terminal_cursorX),a
	ld a,(Terminal_cursorYSaved)
	ld (Terminal_cursorY),a
	ret

; hl = control sequence buffer
Terminal_ANSI_SetCursorPosition:
	xor a
	ld (Terminal_cursorX),a
	ld (Terminal_cursorY),a
	ld b,a
Terminal_ANSI_SetCursorPosition_Loop:
	ld a,(hl)
	inc hl
	cp "@"
	ret nc
	cp ";"
	jp z,Terminal_ANSI_SetCursorPosition_Separator
	bit 0,b
	jp z,Terminal_ANSI_SetCursorPosition_X
	jp Terminal_ANSI_SetCursorPosition_Y
Terminal_ANSI_SetCursorPosition_Separator:
	inc b
	jp Terminal_ANSI_SetCursorPosition_Loop
Terminal_ANSI_SetCursorPosition_X:
	sub "0"
	ld (Terminal_cursorY),a
	ld a,(hl)
	cp ";"
	jp nc,Terminal_ANSI_SetCursorPosition_X_Done
	inc hl
	sub "0"
	ld c,a
	ld a,(Terminal_cursorY)
	add a,a
	ld e,a
	add a,a
	add a,a
	add a,e
	add a,c
	ld (Terminal_cursorY),a
Terminal_ANSI_SetCursorPosition_X_Done:
	ld a,(Terminal_cursorY)
	dec a
	ld (Terminal_cursorY),a
	cp 24
	jp c,Terminal_ANSI_SetCursorPosition_Loop
	ld a,24  ; XXX should be 23?
	ld (Terminal_cursorX),a
	jp Terminal_ANSI_SetCursorPosition_Loop
Terminal_ANSI_SetCursorPosition_Y:
	sub "0"
	ld (Terminal_cursorX),a
	ld a,(hl)
	cp ";"
	jp nc,Terminal_ANSI_SetCursorPosition_Y_Done
	inc hl
	sub "0"
	ld c,a
	ld a,(Terminal_cursorX)
	add a,a
	ld e,a
	add a,a
	add a,a
	add a,e
	add a,c
	ld (Terminal_cursorX),a
Terminal_ANSI_SetCursorPosition_Y_Done:
	ld a,(Terminal_cursorX)
	dec a
	ld (Terminal_cursorX),a
	cp 80
	jp c,Terminal_ANSI_SetCursorPosition_Loop
	ld a,80  ; XXX should be 79?
	ld (Terminal_cursorX),a
	jp Terminal_ANSI_SetCursorPosition_Loop

; hl = control sequence buffer
Terminal_ANSI_ClearLine:
	ld a,(hl)
	cp "K"
	jp z,Terminal_ClearLineFromCursor
Terminal_ANSI_ClearLine_Loop:
	ld a,(hl)
	inc hl
	cp "K"
	ret z
	cp "0"
	jp z,Terminal_ClearLineFromCursor
	cp "1"
	jp z,Terminal_ClearLineToCursor
	cp "2"
	jp z,Terminal_ClearLine
	jp Terminal_ANSI_ClearLine_Loop

Terminal_ClearLine:
	ld a,(Terminal_cursorY)
	add a,a
	add a,a
	add a,a
	ld b,a
	ld a,(Terminal_scroll)
	add a,b
	ld (Terminal_clearLinesCommand + 6),a  ; dy
	ld a,8
	ld (Terminal_clearLinesCommand + 10),a  ; ny
	ld hl,Terminal_clearLinesCommand
	jp VDP_ExecuteCommand

Terminal_ClearLineFromCursor:
	ld a,(Terminal_cursorY)
	add a,a
	add a,a
	add a,a
	ld b,a
	ld a,(Terminal_scroll)
	add a,b
	ld (Terminal_clearPartialLineCommand + 6),a  ; dy
	ld a,(Terminal_cursorX)
	ld b,a
	add a,a
	add a,b
	add a,9
	add a,a
	ld c,a
	ld (Terminal_clearPartialLineCommand + 4),a  ; dx
	ld a,0
	rla
	ld b,a
	ld (Terminal_clearPartialLineCommand + 5),a  ; dx
	ld hl,80 * 6 + 18
	sbc hl,bc
	ld a,l
	ld (Terminal_clearPartialLineCommand + 8),a  ; nx
	ld a,h
	ld (Terminal_clearPartialLineCommand + 9),a  ; nx
	ld hl,Terminal_clearPartialLineCommand
	jp VDP_ExecuteCommand

Terminal_ClearLineToCursor:
	ld a,(Terminal_cursorX)
	and a
	ret z
	ld b,a
	add a,a
	add a,b
	add a,a
	ld (Terminal_clearPartialLineCommand + 8),a  ; nx
	ld a,0
	ld (Terminal_clearPartialLineCommand + 5),a  ; dx
	rla
	ld (Terminal_clearPartialLineCommand + 9),a  ; nx
	ld a,18
	ld (Terminal_clearPartialLineCommand + 4),a  ; dx
	ld a,(Terminal_cursorY)
	add a,a
	add a,a
	add a,a
	ld b,a
	ld a,(Terminal_scroll)
	add a,b
	ld (Terminal_clearPartialLineCommand + 6),a  ; dy
	ld hl,Terminal_clearPartialLineCommand
	jp VDP_ExecuteCommand

; hl = control sequence buffer
Terminal_ANSI_ClearScreen:
	ld a,(hl)
	cp "J"
	jp z,Terminal_ClearScreen  ; XXX should be Terminal_ClearScreenFromCursor?
Terminal_ANSI_ClearScreen_Loop:
	ld a,(hl)
	inc hl
	cp "K"  ; XXX should be "J"?
	ret z
	cp "0"
	jp z,Terminal_ClearScreenFromCursor
	cp "1"
	jp z,Terminal_ClearScreenToCursor
	cp "2"
	jp z,Terminal_ClearScreen
	jp Terminal_ANSI_ClearScreen_Loop

Terminal_ClearScreenFromCursor:
	call Terminal_ClearLineFromCursor
	ld a,(Terminal_cursorY)
	inc a
; a = line
Terminal_ClearScreenFromLine:
	cp 24
	ret nc
	ld b,a
	ld a,(Terminal_scroll)
	add a,b
	add a,a
	add a,a
	add a,a
	ld (Terminal_clearLinesCommand + 6),a  ; dy
	ld a,24
	sub b
	add a,a
	add a,a
	add a,a
	ld (Terminal_clearLinesCommand + 10),a  ; ny
	ld hl,Terminal_clearLinesCommand
	jp VDP_ExecuteCommand

Terminal_ClearScreenToCursor:
	call Terminal_ClearLineToCursor
	ld a,(Terminal_cursorY)
	sub 1
	ret c
	add a,a
	add a,a
	add a,a
	ld (Terminal_clearLinesCommand + 10),a  ; ny
	ld a,(Terminal_scroll)
	ld (Terminal_clearLinesCommand + 6),a  ; dy
	ld hl,Terminal_clearLinesCommand
	jp VDP_ExecuteCommand

; hl = control sequence buffer
Terminal_ANSI_DeleteLine:
	ld a,(hl)
	inc hl
	ld b,1
	cp "M"
	jp z,Terminal_ANSI_DeleteLine_Continue
	sub "0"
	ld b,a
	ld a,(hl)
	inc hl
	cp "M"
	jp z,Terminal_ANSI_DeleteLine_Continue
	sub "0"
	ld c,a
	ld a,b
	add a,a
	ld b,a
	add a,a
	add a,a
	add a,b
	add a,c
	ld b,a
	inc hl
Terminal_ANSI_DeleteLine_Continue:
	xor a
	ld (Terminal_cursorX),a
	ld a,(Terminal_cursorY)
	add a,b
	cp 24
	jp nc,Terminal_ClearScreenFromCursor
	ld c,a
	add a,a
	add a,a
	add a,a
	ld (Terminal_moveLinesCommand + 2),a  ; sy
	ld a,(Terminal_cursorY)
	add a,a
	add a,a
	add a,a
	ld (Terminal_moveLinesCommand + 6),a  ; dy
	ld a,24
	sub c
	ld e,a
	add a,a
	add a,a
	add a,a
	ld (Terminal_moveLinesCommand + 10),a  ; ny
	ld hl,Terminal_moveLinesCommand
	call VDP_ExecuteCommand
	ld a,(Terminal_cursorY)
	add a,e
	jp Terminal_ClearScreenFromLine

; hl = control sequence buffer
Terminal_ANSI_InsertLine:
	ld a,(hl)
	inc hl
	ld e,1
	cp "L"
	jp z,Terminal_ANSI_InsertLine_Continue
	sub "0"
	ld e,a
	ld a,(hl)
	inc hl
	cp "M"  ; XXX should be "L"?
	jp z,Terminal_ANSI_InsertLine_Continue
	sub "0"
	ld c,a
	ld a,e
	add a,a
	ld b,a
	add a,a
	add a,a
	add a,b
	add a,c
	ld e,a
	inc hl
Terminal_ANSI_InsertLine_Continue:
	xor a
	ld (Terminal_cursorX),a
	ld a,(Terminal_cursorY)
	add a,e
	cp 24
	jp nc,Terminal_ClearScreenFromCursor
	ld c,a
	ld a,e
	add a,a
	add a,a
	add a,a
	ld b,a
	ld a,24 * 8 - 1
	ld (Terminal_moveLinesCommand + 6),a  ; dy
	sub b
	ld (Terminal_moveLinesCommand + 2),a  ; sy
	ld a,24
	sub c
	add a,a
	add a,a
	add a,a
	ld (Terminal_moveLinesCommand + 10),a  ; ny
	ld a,00001000B
	ld (Terminal_moveLinesCommand + 13),a  ; argument
	ld hl,Terminal_moveLinesCommand
	call VDP_ExecuteCommand
	xor a
	ld (Terminal_moveLinesCommand + 13),a  ; argument
	ld a,(Terminal_cursorY)
	ld b,a
	ld a,(Terminal_scroll)
	add a,b
	add a,a
	add a,a
	add a,a
	ld (Terminal_clearLinesCommand + 6),a
	ld a,e
	add a,a
	add a,a
	add a,a
	ld (Terminal_clearLinesCommand + 10),a
	ld hl,Terminal_clearLinesCommand
	jp VDP_ExecuteCommand

; ECMA-48 SGR Select Graphic Rendition
; hl = control sequence buffer
Terminal_SGR_SetAttributes:
	ld a,(hl)
	cp "m"
	jp z,Terminal_SGR_ResetAttributes
Terminal_SGR_SetAttributes_Continue:
	ld a,(hl)
	inc hl
	cp "m"
	ret z
	cp ";"
	jp z,Terminal_SGR_SetAttributes_Continue
	cp "1"
	jp z,Terminal_SGR_EnableBold
	cp "2"
	jp z,Terminal_SGR_DisableBold
	cp "3"
	jp z,Terminal_SGR_ForegroundColor
	cp "4"
	jp z,Terminal_SGR_BackgroundColor
	cp "0"
	jp z,Terminal_SGR_ResetAttributes
	jp Terminal_SGR_SetAttributes_Continue

; hl = control sequence buffer
Terminal_SGR_EnableBold:
	ld a,(Terminal_foregroundColor)
	set 3,a
	ld (Terminal_foregroundColor),a
	jp Terminal_SGR_SetAttributes_Continue

; hl = control sequence buffer
Terminal_SGR_DisableBold:
	ld a,(Terminal_foregroundColor)
	res 3,a
	ld (Terminal_foregroundColor),a
	jp Terminal_SGR_SetAttributes_Continue

; hl = control sequence buffer
Terminal_SGR_ForegroundColor:
	ld a,(hl)
	inc hl
	sub "0"
	ld c,a
	ld a,(Terminal_foregroundColor)
	and ~7
	or c
	ld (Terminal_foregroundColor),a
	jp Terminal_SGR_SetAttributes_Continue

; hl = control sequence buffer
Terminal_SGR_BackgroundColor:
	ld a,(hl)
	inc hl
	sub "0"
	ld c,a
	ld b,0
	push hl
	ld hl,Terminal_ansiPaletteMapping
	add hl,bc
	ld a,(hl)
	pop hl
	ld b,a
	add a,a
	add a,a
	add a,a
	add a,a
	or b
	ld (Terminal_backgroundColor),a
	jp Terminal_SGR_SetAttributes_Continue

; hl = control sequence buffer
Terminal_SGR_ResetAttributes:
	xor a
	ld (Terminal_backgroundColor),a
	ld (Terminal_underline),a
	ld a,7
	ld (Terminal_foregroundColor),a
	jp Terminal_SGR_SetAttributes_Continue

Terminal_EscapeX:
	ld a,Terminal_PENDING_ESCAPE_X
	ld (Terminal_pendingEscape),a
	ret

; d = character
Terminal_EscapeXContinue:
	xor a
	ld (Terminal_pendingEscape),a
	ld a,d
	cp "4"
	jp z,Terminal_BigCursor
	cp "5"
	jp z,Terminal_DisableCursor
	ret

Terminal_EscapeY:
	ld a,Terminal_PENDING_ESCAPE_Y
	ld (Terminal_pendingEscape),a
	ret

; d = character
Terminal_EscapeYContinue:
	xor a
	ld (Terminal_pendingEscape),a
	ld a,d
	cp "4"
	jp z,Terminal_SmallCursor
	cp "5"
	jp z,Terminal_EnableCursor
	ret

Terminal_BigCursor:
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE >> 16
	ld hl,VDP_SPRITE_ATTRIBUTE_TABLE + 2
	di
	call VDP_SetVRAMWrite
	xor a
	ei
	out (VDP_PORT + 0),a
	ret

Terminal_SmallCursor:
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE >> 16
	ld hl,VDP_SPRITE_ATTRIBUTE_TABLE + 2
	di
	call VDP_SetVRAMWrite
	ld a,1
	ei
	out (VDP_PORT + 0),a
	ret

Terminal_EnableCursor: equ VDP_EnableSprites
Terminal_DisableCursor: equ VDP_DisableSprites

Terminal_VT100_SetCursorPosition:
	ld a,Terminal_PENDING_ESCAPE_VT100_Y
	ld (Terminal_pendingEscape),a
	ret

; d = character
Terminal_VT100_SetCursorPositionContinue:
	ld a,d
	sub " "
	ld (Terminal_cursorY),a
	ld a,Terminal_PENDING_ESCAPE_VT100_Y2
	ld (Terminal_pendingEscape),a
	ret

; d = character
Terminal_VT100_SetCursorPositionContinue2:
	ld a,d
	sub " "
	ld (Terminal_cursorX),a
	xor a
	ld (Terminal_pendingEscape),a
	ret

; a <- ASCII code (0: none)
Terminal_ReadKey:
	di
	ld hl,NEWKEY
	ld de,Terminal_newKey
	ld bc,11
	ldir
	ei
	ld hl,Terminal_newKey
	ld ix,Terminal_oldKey
	ld b,11
Terminal_ReadKey_FlagPressLoop:
	ld a,(hl)
	xor (ix)
	cpl
	or (hl)
	cpl
	ld (ix),a  ; oldKey = key press transition flags
	inc ix
	inc hl
	djnz Terminal_ReadKey_FlagPressLoop
	ld b,11
	ld hl,Terminal_oldKey
Terminal_ReadKey_FindPressLoop:
	ld a,(hl)
	inc hl
	and a
	jp nz,Terminal_ReadKey_HandlePress
	djnz Terminal_ReadKey_FindPressLoop
	xor a
	jp Terminal_ReadKey_Done
Terminal_ReadKey_HandlePress:
	ld c,a
	ld a,11
	sub b
	rlca
	rlca
	rlca
	ld e,a
	ld d,0
	ld a,(NEWKEY + 6)
	ld hl,Terminal_keyMapShift
	bit 0,a  ; SHIFT
	jp z,Terminal_ReadKey_MapKey
	ld hl,Terminal_keyMapCtrl
	bit 1,a  ; CTRL
	jp z,Terminal_ReadKey_MapKey
	ld hl,Terminal_keyMap
	ld a,(Interrupt_capsEnabled)
	and a
	jp z,Terminal_ReadKey_MapKey
	ld hl,Terminal_keyMapCaps
Terminal_ReadKey_MapKey:
	add hl,de
	ld a,c
Terminal_ReadKey_MapKeyLoop:
	rra
	jp c,Terminal_ReadKey_MapKeyFound
	inc hl
	jp Terminal_ReadKey_MapKeyLoop
Terminal_ReadKey_MapKeyFound:
	ld a,(hl)
Terminal_ReadKey_Done:
	ld hl,Terminal_newKey
	ld de,Terminal_oldKey
	ld bc,11
	ldir
	ret

Terminal_Initialize:
	ld a,-1
	ld (Terminal_initialized),a
	call VDP_InitRegisterMirror
	call VDP_InitGraphic6Mode
	ld hl,Terminal_ansiPalette
	call VDP_SetPalette
	call VDP_InitSprites
	call Interrupt_Install
	ld h,Fossil_FASTINT_INSTALL
	call Fossil_Fastint
	ld hl,(CGPNT + 1)
	exx
	ld hl,Terminal_buffer
	ld bc,0 << 8 | 8  ; 2048 bytes
Terminal_Initialize_FontBitmapLoop:
	exx
	ld a,(CGPNT)
	call RDSLT
	inc hl
	exx
	ld (hl),a
	inc hl
	djnz Terminal_Initialize_FontBitmapLoop
	dec c
	jp nz,Terminal_Initialize_FontBitmapLoop
	xor a
	di
	out (VDP_PORT + 1),a
	ld a,VDP_PAGE_1 >> 8 & 3FH | VDP_VRAM_WRITE
	out (VDP_PORT + 1),a
	ld a,VDP_PAGE_1 >> 14
	out (VDP_PORT + 1),a
	ld a,14 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld hl,Terminal_buffer
	ld c,32
Terminal_Initialize_FontRowLoop:
	ld b,64
Terminal_Initialize_FontColumnLoop:
	ld a,(hl)
	ld de,8
	add hl,de
	exx
	ld d,a
	ld b,4
Terminal_Initialize_FontLineLoop:
	xor a
	rl d
	sbc a,0
	and 0F0H
	ld e,a
	xor a
	rl d
	sbc a,0
	and 0FH
	or e
	out (VDP_PORT + 0),a
	djnz Terminal_Initialize_FontLineLoop
	exx
	djnz Terminal_Initialize_FontColumnLoop
	ld a,c
	and 7
	cp 1
	jr z,Terminal_Initialize_NextRow
	ld de,-63 * 8
	add hl,de
Terminal_Initialize_NextRow:
	ld de,-7
	add hl,de
	dec c
	jp nz,Terminal_Initialize_FontRowLoop
	ei
	ld hl,Terminal_fontDuplicateCommand
	call VDP_ExecuteCommand
	ld b,6
	ld hl,Terminal_ansiPaletteMapping + 14
Terminal_Initialize_ColorLoop:
	ld a,(hl)
	dec hl
	ld (Terminal_fontColorCommand + 12),a  ; color
	ld a,(Terminal_fontColorCommand + 6)   ; dy
	add a,32
	ld (Terminal_fontColorCommand + 6),a   ; dy
	exx
	ld hl,Terminal_fontColorCommand
	call VDP_ExecuteCommand
	exx
	djnz Terminal_Initialize_ColorLoop
	ret

Terminal_Deinitialize:
	ld a,(Terminal_initialized)
	and a
	ret z
	xor a
	ld (Terminal_initialized),a
	ld h,Fossil_FASTINT_UNINSTALL
	call Fossil_Fastint
	call Interrupt_Uninstall
	call VDP_RestoreRegisters
	ld hl,Terminal_msxPalette
	call VDP_SetPalette
	call VDP_InitTextMode
	ret

; hl = string (zero terminated)
Terminal_PrintString:
	ld a,(Terminal_initialized)
	and a
	jp z,Terminal_PrintStringDOS_Loop
Terminal_PrintStringANSI_Loop:
	ld a,(hl)
	and a
	ret z
	push hl
	call Terminal_PrintCharacter
	pop hl
	inc hl
	jp Terminal_PrintStringANSI_Loop
Terminal_PrintStringDOS_Loop:
	ld a,(hl)
	and a
	ret z
	ld e,a
	ld c,_CONOUT
	push hl
	call BDOS
	pop hl
	inc hl
	jp Terminal_PrintStringDOS_Loop

Terminal_PrintHex:
	push af
	push bc
	push de
	push hl
	push af
	and 0F0H
	rrca
	rrca
	rrca
	rrca
	ld c,a
	ld b,0
	ld hl,Terminal_hexDigits
	add hl,bc
	ld a,(hl)
	call Terminal_PrintCharacter
	pop af
	and 0FH
	ld c,a
	ld b,0
	ld hl,Terminal_hexDigits
	add hl,bc
	ld a,(hl)
	call Terminal_PrintCharacter
	pop hl
	pop de
	pop bc
	pop af
	ret

Terminal_hexDigits:
	db "0123456789ABCDEF"
