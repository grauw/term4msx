;
; VDP routines
;
VDP_PORT: equ 98H
VDP_REGISTER: equ 80H
VDP_VRAM_WRITE: equ 40H

VDP_PAGE_0: equ 00000H
VDP_PAGE_1: equ 10000H
VDP_SPRITE_COLOR_TABLE: equ 1F400H
VDP_SPRITE_ATTRIBUTE_TABLE: equ VDP_SPRITE_COLOR_TABLE | 200H
VDP_SPRITE_PATTERN_TABLE: equ 1F800H

VDP_InitGraphic6Mode:
	ld a,(VDP_registers + 0)
	and 0F1H
	or 0AH    ; set M5, M3, clear M4  (screen 7)
	ld (VDP_registers + 0),a
	di
	out (VDP_PORT + 1),a
	ld a,0 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,(VDP_registers + 1)
	and 0E4H  ; clear M1, M2, SI, MAG
	ld (VDP_registers + 1),a
	and 0BFH  ; clear BL
	out (VDP_PORT + 1),a
	ld a,1 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,1FH  ; page 0
	ld (VDP_registers + 2),a
	out (VDP_PORT + 1),a
	ld a,2 | VDP_REGISTER
	out (VDP_PORT + 1),a
	xor a  ; backdrop colour 0
	ld (VDP_registers + 7),a
	out (VDP_PORT + 1),a
	ld a,7 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,(VDP_registers + 8)
	and 0FDH  ; clear SPD
	ld (VDP_registers + 8),a
	out (VDP_PORT + 1),a
	ld a,8 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,(VDP_registers + 9)
	or 80H  ; set LN
	ld (VDP_registers + 9),a
	out (VDP_PORT + 1),a
	ld a,9 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,0  ; vertical offset 0
	out (VDP_PORT + 1),a
	ld a,23 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ld hl,Terminal_initScreenCommand
	call VDP_ExecuteCommand
	call VDP_WaitCommandReady
	ld a,(VDP_registers + 1)  ; set BL
	di
	out (VDP_PORT + 1),a
	ld a,1 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ret

VDP_InitTextMode:
	ld iy,(EXPTBL - 1)
	ld ix,INITXT
	call CALSLT
	ret

VDP_InitSprites:
	di
	ld a,VDP_SPRITE_PATTERN_TABLE >> 11
	ld (VDP_registers + 6),a
	out (VDP_PORT + 1),a
	ld a,6 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE >> 7 | 07H
	ld (VDP_registers + 5),a
	out (VDP_PORT + 1),a
	ld a,5 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE >> 15
	ld (VDP_registers + 11),a
	out (VDP_PORT + 1),a
	ld a,11 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,VDP_SPRITE_PATTERN_TABLE >> 16
	ld hl,VDP_SPRITE_PATTERN_TABLE
	call VDP_SetVRAMWrite
	ld bc,16 << 8 | VDP_PORT + 0
	ld hl,VDP_cursorSpritePatterns
	otir
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE >> 16
	ld hl,VDP_SPRITE_ATTRIBUTE_TABLE
	call VDP_SetVRAMWrite
	ld b,32
VDP_InitSprites_SATLoop:
	ld a,216
	out (VDP_PORT + 0),a
	ld a,0
	out (VDP_PORT + 0),a
	ld a,0
	out (VDP_PORT + 0),a
	ld a,0
	out (VDP_PORT + 0),a
	djnz VDP_InitSprites_SATLoop
	ld a,VDP_SPRITE_COLOR_TABLE >> 16
	ld hl,VDP_SPRITE_COLOR_TABLE
	call VDP_SetVRAMWrite
	ld b,256
VDP_InitSprites_SCTLoop:
	ld a,0FH
	out (VDP_PORT + 0),a
	ld a,0FH
	out (VDP_PORT + 0),a
	djnz VDP_InitSprites_SCTLoop
	ei
	ret

; ahl = address
VDP_SetVRAMWrite:
	rlc h
	rla
	rlc h
	rla
	srl h
	srl h
	out (VDP_PORT + 1),a
	ld a,14 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,l
	nop
	out (VDP_PORT + 1),a
	ld a,h
	or VDP_VRAM_WRITE
	out (VDP_PORT + 1),a
	ret

VDP_InitRegisterMirror:
	ld hl,RG0SAV
	ld de,VDP_registers
	ld bc,8
	ldir
	ld hl,RG8SAV
	ld de,VDP_registers + 8
	ld bc,17
	ldir
	ld a,1
	di
	out (VDP_PORT + 1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,(de)
	in a,(VDP_PORT + 1)
	push af
	xor a
	out (VDP_PORT + 1),a
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	pop af
	and 00011100B
	ld (VDP_identification),a
	ret z  ; z: V9938
	ld hl,RG25SAV
	ld de,VDP_registers + 25
	ld bc,3
	ldir
	ret

VDP_RestoreRegisters:
	ld bc,0 << 8 | 8
	ld hl,RG0SAV
	call VDP_RestoreRegisters_Loop
	ld bc,8 << 8 | 17
	ld hl,RG8SAV
	call VDP_RestoreRegisters_Loop
	ld bc,25 << 8 | 3
	ld hl,RG25SAV
VDP_RestoreRegisters_Loop:
	ld a,(hl)
	inc hl
	di
	out (VDP_PORT + 1),a
	ld a,b
	or VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	inc b
	ld a,b
	dec c
	jp nz,VDP_RestoreRegisters_Loop
	ret

VDP_EnableSprites:
	ld a,(VDP_registers + 8)
	and ~2
	ld (VDP_registers + 8),a
	di
	out (VDP_PORT + 1),a
	ld a,8 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ret

VDP_DisableSprites:
	ld a,(VDP_registers + 8)
	or 2
	ld (VDP_registers + 8),a
	di
	out (VDP_PORT + 1),a
	ld a,8 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ret

; hl = palette
VDP_SetPalette:
	xor a
	di
	out (VDP_PORT + 1),a
	ld a,16 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ld b,16
VDP_SetPalette_Loop:
	ld a,(hl)
	inc hl
	inc hl
	add a,a
	add a,a
	add a,a
	add a,a
	or (hl)
	dec hl
	out (VDP_PORT + 2),a
	ld a,(hl)
	inc hl
	inc hl
	out (VDP_PORT + 2),a
	djnz VDP_SetPalette_Loop
	ret

; hl = command
VDP_ExecuteCommand:
	ld a,32
	di
	out (VDP_PORT + 1),a
	ld a,17 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	ld c,VDP_PORT + 3
VDP_ExecuteCommand_Loop:
	di
	ld a,2
	out (VDP_PORT + 1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT + 1),a
	in a,(VDP_PORT + 1)
	rra
	ld a,0
	out (VDP_PORT + 1),a
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	jr c,VDP_ExecuteCommand_Loop
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	ret

VDP_WaitCommandReady:
	ld a,2
	di
	out (VDP_PORT + 1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,(de)
	in a,(VDP_PORT + 1)
	rra
	ld a,0
	out (VDP_PORT + 1),a
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT + 1),a
	jp c,VDP_WaitCommandReady
	ret
