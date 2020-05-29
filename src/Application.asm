;
; Main application
;
Application_Main:
	ld (Application_returnStack),sp
	call Fossil_Detect
	ld de,Application_fossilNotFoundError
	ld c,_STROUT
	jp nz,BDOS
	ld de,Application_fossilVersionError
	ld a,h
	cp 01H
	jp nz,BDOS
	ld a,l
	cp 40H
	jp nz,BDOS
	call Fossil_Init
	ld hl,0B0BH  ; Tx / Rx 115200 baud
	call Fossil_SetBaud
	ld hl,0700H  ; 8 data bits, 1 stop bit, no parity
	call Fossil_Protocol
	call Terminal_Initialize
	ld a,(Application_logEnabled)
	and a
	call nz,Log_Create
	ld hl,Application_welcome
	call Terminal_PrintString
	ld hl,Application_resetModemCommand
	call Fossil_SendString
Application_ReceiveLoop:
	call Fossil_RS_In_Stat
	and a
	jp z,Application_ReceiveContinue
	call Fossil_RS_In
	ld hl,Application_logEnabled
	bit 0,(hl)
	call nz,Log_Write
	call Terminal_PrintCharacter
Application_ReceiveContinue:
	ld a,(NEWKEY + 6)
	bit 5,a  ; F1
	jp z,Application_DialTotallyChaos
	bit 6,a  ; F2
	jp z,Application_DialMSXVeendam
	bit 7,a  ; F3
	jp z,YModemG_StartDownload
	ld a,(NEWKEY + 7)
	bit 1,a  ; F5
	jp z,Application_Quit
	call Terminal_ReadKey
	and a
	jp z,Application_ReceiveLoop
	call Fossil_RS_Out
	jp Application_ReceiveLoop
Application_Quit:
	call Terminal_Deinitialize
	ld a,(Application_logEnabled)
	and a
	call nz,Log_Close
	call Fossil_DeInit
	ld iy,(EXPTBL - 1)
	ld ix,KILBUF
	call CALSLT
	ld sp,(Application_returnStack)
	ret

Application_DialTotallyChaos:
	ld hl,Application_dialTotallyChaosCommand
	call Fossil_SendString
Application_DialTotallyChaos_ReleaseLoop:
	ld a,(NEWKEY + 6)
	bit 5,a  ; F1
	jp z,Application_DialTotallyChaos_ReleaseLoop
	jp Application_ReceiveLoop

Application_DialMSXVeendam:
	ld hl,Application_dialMSXVeendamCommand
	call Fossil_SendString
Application_DialMSXVeendam_ReleaseLoop:
	ld a,(NEWKEY + 6)
	bit 6,a  ; F2
	jp z,Application_DialMSXVeendam_ReleaseLoop
	jp Application_ReceiveLoop
