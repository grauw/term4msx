;
; Communication log
;
Log_BUFFER: equ 8000H

Log_Create:
	ld de,Log_path
	xor a
	ld b,a
	ld c,_CREATE
	call BDOS
	and a
	jp nz,Log_DiskError
	ld a,b
	ld (Log_fileHandle),a
	ld hl,Log_BUFFER
	ld (Log_position),hl
	ret

; a = byte
Log_Write:
	ld hl,(Log_position)
	ex af,af'
	ld a,h
	cp 82H
	call z,Log_Flush
	ex af,af'
	ld (hl),a
	inc hl
	ld (Log_position),hl
	ret

; hl = log position
Log_Flush:
	push hl
	ld h,0
	call Fossil_RTS
	pop hl
	ld bc,Log_BUFFER
	and a
	sbc hl,bc
	ld a,(Log_fileHandle)
	ld b,a
	ld de,Log_BUFFER
	ld c,_WRITE
	call BDOS
	and a
	jp nz,Log_DiskError
	ld h,-1
	call Fossil_RTS
	ld hl,Log_BUFFER
	ld (Log_position),hl
	ret

Log_Close:
	ld hl,(Log_position)
	ld a,h
	or l
	call nz,Log_Flush
	ld a,(Log_fileHandle)
	ld b,a
	ld c,_CLOSE
	call BDOS
	and a
	jp nz,Log_DiskError
	ret

Log_DiskError:
	call Terminal_Deinitialize
	ld de,Log_diskError
	ld c,_STROUT
	call BDOS
	jp Application_Quit
