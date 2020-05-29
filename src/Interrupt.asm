;
; Interrupt routines
;
PPI_PORT: equ 0A8H

Interrupt_Install:
	ld h,Fossil_FASTINT_UNINSTALL
	call Fossil_Fastint
	in a,(PPI_PORT + 2)
	ld (Interrupt_oldPPIC),a
	di
	ld a,(KEYINT)
	ld (Interrupt_oldHook),a
	ld hl,(KEYINT + 1)
	ld (Interrupt_oldHook + 1),hl
	ld a,0C3H  ; jp
	ld (KEYINT),a
	ld hl,Interrupt_Handler
	ld (KEYINT + 1),hl
	ei
	ld h,Fossil_FASTINT_INSTALL
	call Fossil_Fastint
	ret

Interrupt_Uninstall:
	ld h,Fossil_FASTINT_UNINSTALL
	call Fossil_Fastint
	di
	ld a,(Interrupt_oldHook)
	ld (KEYINT),a
	ld hl,(Interrupt_oldHook + 1)
	ld (KEYINT + 1),hl
	ei
	ld a,(Interrupt_oldPPIC)
	out (PPI_PORT + 2),a
	ld h,Fossil_FASTINT_INSTALL
	call Fossil_Fastint
	ret

Interrupt_Handler:
	push af
	push bc
	push hl
	ei
	in a,(VDP_PORT + 1)
	and a
	jp p,Interrupt_Handler_Return
	ld hl,(JIFFY)
	inc hl
	ld (JIFFY),hl
	in a,(PPI_PORT + 2)
	and 0F0H
	ld c,a
	ld b,11
	ld hl,NEWKEY
Interrupt_Handler_KeyLoop:
	ld a,c
	inc c
	out (PPI_PORT + 2),a
	in a,(PPI_PORT + 1)
	ld (hl),a
	inc hl
	djnz Interrupt_Handler_KeyLoop
	ld a,(NEWKEY + 6)
	bit 3,a  ; CAPS
	jp nz,Interrupt_Handler_NoCaps
	ld a,(Interrupt_capsPressed)
	and a
	jp nz,Interrupt_Handler_Scroll
	dec a
	ld (Interrupt_capsPressed),a
	ld a,(Interrupt_capsEnabled)
	cpl
	ld (Interrupt_capsEnabled),a
	cpl
	and 40H  ; caps LED
	ld b,a
	in a,(PPI_PORT + 2)
	and ~40H
	or b
	out (PPI_PORT + 2),a
	jp Interrupt_Handler_Scroll
Interrupt_Handler_NoCaps:
	xor a
	ld (Interrupt_capsPressed),a
Interrupt_Handler_Scroll:
	ld a,(Terminal_scrollStep)
	and a
	jp z,Interrupt_Handler_Cursor
	ld b,a
	ld a,(Interrupt_currentScroll)
	add a,b
	ld (Interrupt_currentScroll),a
	ld b,a
	out (VDP_PORT + 1),a
	ld a,23 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,(Terminal_scroll)
	cp b
	jp nz,Interrupt_Handler_Cursor
	xor a
	ld (Terminal_scrollStep),a
Interrupt_Handler_Cursor:
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE >> 14
	out (VDP_PORT + 1),a
	ld a,14 | VDP_REGISTER
	out (VDP_PORT + 1),a
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE & 0FFH
	out (VDP_PORT + 1),a
	ld a,VDP_SPRITE_ATTRIBUTE_TABLE >> 8 & 3FH | VDP_VRAM_WRITE
	out (VDP_PORT + 1),a
	ld a,(Terminal_scroll)
	ld b,a
	ld a,(Terminal_cursorY)
	add a,a
	add a,a
	add a,a
	add a,b
	dec a
	out (VDP_PORT + 0),a
	ld a,(Terminal_cursorX)
	ld b,a
	add a,a
	add a,b
	add a,9
	out (VDP_PORT + 0),a
Interrupt_Handler_Return:
	pop hl
	pop bc
	pop af
	ret
