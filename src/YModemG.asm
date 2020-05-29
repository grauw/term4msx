;
; YModem-G routines
;
YModemG_SOH: equ 1
YModemG_STX: equ 2
YModemG_EOT: equ 4
YModemG_ACK: equ 6
YModemG_NAK: equ 21
YModemG_CAN: equ 24
YModemG_C: equ "C"
YModemG_G: equ "G"

YModemG_StartDownload:
	ld hl,YModemG_download
	call Terminal_PrintString
	ld hl,(Fossil_RS_In + 1)
	ld (YModemG_ReceiveByte + 1),hl  ; small self-modifying code optimisation eliminating a jump
	ld hl,Terminal_buffer
	ld (Terminal_bufferPosition),hl
YModemG_ReceiveBatch:
	ld a,0FFH
	ld (YModemG_fileHandle),a
	ld a,YModemG_G
	call Fossil_RS_Out
	call YModemG_ReceiveByte
	cp YModemG_G
	jp z,YModemG_NotInDownloadMode
	cp YModemG_SOH
	jp nz,YModemG_Abort
	call YModemG_ReceiveByte
	cpl
	push af
	call YModemG_ReceiveByte
	pop bc
	cp b
	jp nz,YModemG_Abort
	ld b,80H
	ld hl,Terminal_buffer
YModemG_StartDownload_Packet0Loop:
	exx
	call YModemG_ReceiveByte
	exx
	ld (hl),a
	inc hl
	djnz YModemG_StartDownload_Packet0Loop
	call YModemG_ReceiveByte  ; skip CRC
	call YModemG_ReceiveByte
	ld a,(Terminal_buffer)
	and a
	jp z,YModemG_Exit
	ld hl,Terminal_buffer
	ld de,YModemG_file + 6
	ld b,12
YModemG_StartDownload_PathLoop:
	ld a,(hl)
	inc hl
	and a
	jp nz,YModemG_StartDownload_PathLoopEnd
	dec hl
	ld a," "
YModemG_StartDownload_PathLoopEnd:
	ld (de),a
	inc de
	djnz YModemG_StartDownload_PathLoop
	inc hl
	ld a,(hl)
	and a
	jp nz,YModemG_StartDownload_ReadFileSize
	ld a,0FFH
	ld (YModemG_remainingBytes),a
	ld (YModemG_remainingBytes + 1),a
	ld (YModemG_remainingBytes + 2),a
	ld (YModemG_remainingBytes + 3),a
	jp YModemG_StartDownload_NoFileSize
YModemG_StartDownload_ReadFileSize:
	inc hl
	ld a,(hl)
	cp " " + 1
	jp nc,YModemG_StartDownload_ReadFileSize
	dec hl
	push hl
	pop ix
	call YModemG_ReadFileSize
	ld (YModemG_remainingBytes),hl
	ld (YModemG_remainingBytes + 2),iy
YModemG_StartDownload_NoFileSize:
	ld hl,YModemG_file
	call Terminal_PrintString
	ld de,Terminal_buffer
	xor a
	ld b,a
	ld c,_CREATE
	call BDOS
	and a
	jp nz,Log_DiskError
	ld a,b
	ld (YModemG_fileHandle),a
	ld a,YModemG_G
	call Fossil_RS_Out
YModemG_ReceiveBlock:
	call YModemG_ReceiveByte
	cp YModemG_EOT
	jp z,YModemG_ReceiveEndOfTransmission
	cp YModemG_CAN
	jp z,YModemG_ReceiveAbort
	ex af,af'
	call YModemG_ReceiveByte
	cpl
	ld b,a
	exx
	call YModemG_ReceiveByte
	exx
	cp b
	jp nz,YModemG_Abort
	ex af,af'
	cp YModemG_SOH
	jp z,YModemG_ReceiveBlock128
	cp YModemG_STX
	jp z,YModemG_ReceiveBlock1024
	jp YModemG_Abort

YModemG_ReceiveBlock128:
	ld b,128
	ld hl,(Terminal_bufferPosition)
YModemG_ReceiveBlock128_Loop:
	exx
	call YModemG_ReceiveByte
	exx
	ld (hl),a
	inc hl
	djnz YModemG_ReceiveBlock128_Loop
	ld (Terminal_bufferPosition),hl
	call YModemG_ReceiveByte  ; skip crc
	call YModemG_ReceiveByte
	call YModemG_WriteBuffer
	jp YModemG_ReceiveBlock

YModemG_ReceiveBlock1024:
	ld bc,0 << 8 | 4
	ld hl,(Terminal_bufferPosition)
YModemG_ReceiveBlock1024_Loop:
	exx
	call YModemG_ReceiveByte
	exx
	ld (hl),a
	inc hl
	djnz YModemG_ReceiveBlock1024_Loop
	dec c
	jp nz,YModemG_ReceiveBlock1024_Loop
	ld (Terminal_bufferPosition),hl
	call YModemG_ReceiveByte
	call YModemG_ReceiveByte
	call YModemG_WriteBuffer
	jp YModemG_ReceiveBlock

YModemG_WriteBuffer:
	ld a,(Terminal_bufferPosition + 1)
	cp (Log_BUFFER - 1024 >> 8) + 1
	ret c
YModemG_FlushBuffer:
	and a
	ld hl,(Terminal_bufferPosition)
	ld de,Terminal_buffer
	sbc hl,de
	ret z
	ex de,hl
	ld h,0
	call Fossil_RTS
	ld hl,Terminal_buffer
	ld (Terminal_bufferPosition),hl
	call YModemG_ReduceRemainingBytes
	ex de,hl
	ld a,h
	or l
	ret z
	ld de,Terminal_buffer
	ld a,(YModemG_fileHandle)
	ld b,a
	ld c,_WRITE
	call BDOS
	ld h,0FFH
	jp Fossil_RTS

YModemG_ReceiveEndOfTransmission:
	call YModemG_FlushBuffer
	ld a,(YModemG_fileHandle)
	ld b,a
	ld c,_CLOSE
	call BDOS
	ld a,YModemG_ACK
	call Fossil_RS_Out
	ld hl,YModemG_complete
	call Terminal_PrintString
	jp YModemG_ReceiveBatch

YModemG_Exit:
	jp Application_ReceiveLoop

YModemG_ReceiveAbort:
	ld a,(YModemG_fileHandle)
	ld b,a
	inc a
	jp z,YModemG_ReceiveAbort_NoOpenFile
	ld c,_CLOSE
	call BDOS
YModemG_ReceiveAbort_NoOpenFile:
	ld hl,YModemG_downloadAborted
	call Terminal_PrintString
	jp YModemG_Exit

YModemG_Abort:
	ld bc,8 << 8 | YModemG_CAN
YModemG_Abort_CancelLoop:
	ld a,c
	exx
	call Fossil_RS_Out
	exx
	djnz YModemG_Abort_CancelLoop
	ld bc,8 << 8 | 8
YModemG_Abort_BackspaceLoop:
	ld a,c
	exx
	call Fossil_RS_Out
	exx
	djnz YModemG_Abort_BackspaceLoop
	ld a,(YModemG_fileHandle)
	ld b,a
	inc a
	jp z,YModemG_Abort_NoOpenFile
	ld c,_CLOSE
	call BDOS
YModemG_Abort_NoOpenFile:
	ld hl,YModemG_downloadAborted
	call Terminal_PrintString
	jp YModemG_Exit

YModemG_NotInDownloadMode:
	ld a,(NEWKEY + 6)
	bit 7,a  ; F3
	jp z,YModemG_NotInDownloadMode
	ld hl,YModemG_peerNotInDownloadMode
	call Terminal_PrintString
	ld a,8  ; backspace
	call Fossil_RS_Out
	call YModemG_ReceiveByte
	jp YModemG_Exit

; a <- received byte
YModemG_ReceiveByte:
	call Fossil_RS_In
	ret nz
	ld a,(NEWKEY + 7)
	bit 2,a  ; F5
	jp nz,YModemG_ReceiveByte
	call Terminal_ReadKey
	cp 27
	jp nz,YModemG_ReceiveByte
	pop af
	jp YModemG_Abort

; de = received bytes
; de <- bytes that can be written
YModemG_ReduceRemainingBytes:
	and a
	ld hl,(YModemG_remainingBytes)
	sbc hl,de
	ld (YModemG_remainingBytes),hl
	ret nc
	ld hl,(YModemG_remainingBytes + 2)
	sbc hl,de
	ld (YModemG_remainingBytes + 2),hl
	ret nc
	ld hl,(YModemG_remainingBytes)
	add hl,de
	ex de,hl
	ret

; ix = string
; hliy <- size
YModemG_ReadFileSize:
	ld iy,0
	ld hl,0
	ld a,(ix)
	dec ix
	sub "0"
	ld l,a
	ld de,0
	ld bc,10
	call YModemG_ReadFileSize_AddMultiple
	ld bc,100
	call YModemG_ReadFileSize_AddMultiple
	ld bc,1000
	call YModemG_ReadFileSize_AddMultiple
	ld bc,10000
	call YModemG_ReadFileSize_AddMultiple
	ld de,100000 >> 16
	ld bc,100000
	call YModemG_ReadFileSize_AddMultiple
	ld de,1000000 >> 16
	ld bc,1000000
	call YModemG_ReadFileSize_AddMultiple
	ld de,10000000 >> 16
	ld bc,10000000
	call YModemG_ReadFileSize_AddMultiple
	ld de,100000000 >> 16
	ld bc,100000000
	call YModemG_ReadFileSize_AddMultiple
	ld de,1000000000 >> 16
	ld bc,1000000000
	call YModemG_ReadFileSize_AddMultiple
	ld a,(ix)
	cp "0"
	ret c
	ld de,YModemG_fileSizeOverflow
	call Terminal_PrintString
	pop af
	jp YModemG_Exit
YModemG_ReadFileSize_AddMultiple:
	ld a,(ix)
	dec ix
	sub "0"
	jp c,YModemG_ReadFileSize_Done
	ret z
YModemG_ReadFileSize_AddLoop:
	add hl,bc
	jp nc,YModemG_ReadFileSize_AddNoCarry
	inc iy
YModemG_ReadFileSize_AddNoCarry:
	add iy,de
	dec a
	jp nz,YModemG_ReadFileSize_AddLoop
	ret
YModemG_ReadFileSize_Done:
	pop af
	ret
