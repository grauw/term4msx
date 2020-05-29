;
; Fossil driver routines
;
; See Fossil documentation
;

; hl = string (zero terminated)
Fossil_SendString:
	ld a,(hl)
	and a
	ret z
	push hl
	call Fossil_RS_Out
	pop hl
	inc hl
	jp Fossil_SendString

; XXX not used
Fossil_ReceiveAndEchoLine:
	ld a,(NEWKEY + 7)
	bit 2,a  ; ESC
	ret z
	call Fossil_RS_In_Stat
	and a
	jp z,Fossil_ReceiveAndEchoLine
	call Fossil_RS_In
	call Terminal_PrintCharacter
	cp 10
	jp nz,Fossil_ReceiveAndEchoLine
	dec a
	ret

; hl <- version H.L (packed BCD)
; f <- z: found
Fossil_Detect:
	ld a,(Fossil_ID)
	cp "R"
	ret nz
	ld a,(Fossil_ID + 1)
	cp "S"
	ret nz
	ld hl,(Fossil_JUMPTABLE)
	ld de,Fossil_GetVersion
	ld bc,21 * 3
	ldir
	call Fossil_GetVersion
	xor a
	ret

Fossil_ID: equ 0F3FCH
Fossil_JUMPTABLE: equ 0F3FEH
Fossil_FASTINT_INSTALL: equ 0
Fossil_FASTINT_UNINSTALL: equ 1

Fossil_GetVersion:
	jp 0
Fossil_Init:
	jp 0
Fossil_DeInit:
	jp 0
Fossil_SetBaud:
	jp 0
Fossil_Protocol:
	jp 0
Fossil_Channel:
	jp 0
Fossil_RS_In:
	jp 0
Fossil_RS_Out:
	jp 0
Fossil_RS_In_Stat:
	jp 0
Fossil_RS_Out_Stat:
	jp 0
Fossil_DTR:
	jp 0
Fossil_RTS:
	jp 0
Fossil_Carrier:
	jp 0
Fossil_Chars_In_Buf:
	jp 0
Fossil_Size_Of_Buf:
	jp 0
Fossil_Flush_Buf:
	jp 0
Fossil_Fastint:
	jp 0
Fossil_Hook38Stat:
	jp 0
Fossil_Chput_Hook:
	jp 0
Fossil_Keyb_Hook:
	jp 0
Fossil_Get_Info:
	jp 0
