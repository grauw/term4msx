;
; Data
;
Application_welcome:
	db 27,"x5",27,"[37;44m"
	db 9,"      TERM4MSX v0.9",0E0H," - a VT100 terminal for MSX and RS232",9
	db 9,9,9,"      (c) 2000 Laurens \"Grauw\" Holst / TNI",9,9,9
	db 27,"[0;1;33m",13,10
	db "This program is free. However, if you use this program a lot I would really ",13,10
	db "appreciate a small 'donation'. Please transfer an amount like for example ",27,"[35m","5 euro",27,"[33m"
	db "to my Rabobank account, nr. ",27,"[36m","343753065",27,"[33m"," in the Netherlands.",13,10
	db "An alternative (if you live in a foreign country for example) is to ",27,"[31m","send",27,"[33m me some"
	db "money. My adress: ",27,"[36m","Laurens Holst, Lijsterlaan 60, 1403 BB Bussum, The Netherlands",27,"[33m"
	db "I am also present at all big Dutch fairs.",13,10
	db 27,"[32m",13,10
	db "Press F5 to quit the program.",13,10
	db "Press F1 to connect to Totally Chaos BBS, press F2 to connect to MSX-Veendam.",13,10
	db "You can call another BBS by typing ATD, followed by the number you want to call."
	db 27,"[31m","--------------------------------------------------------------------------------",27,"[m"
	db 27,"y5",0

Application_fossilNotFoundError:
	db 12,"*** No Fossil-driver found...",13,10,"$"

Application_fossilVersionError:
	db 12,"*** Fossil version < 1.40...",13,10,"$"

Log_diskError:
	db 12,"*** Disk Error...",13,10,"$"

YModemG_download:
	db "YMODEM G download...",13,10,0

YModemG_file:
	db "File:             ",0

YModemG_complete:
	db " complete.",13,10,0

YModemG_downloadAborted:
	db "Download aborted.",13,10,0

YModemG_peerNotInDownloadMode:
	db "Peer not in download-mode!!!",13,10,0

YModemG_fileSizeOverflow:
	db "File-size overflow!!! (quite impossible size)",13,10,0

Application_resetModemCommand:
	db "ATZ",13,0
	db "OK"

Application_dialTotallyChaosCommand:
	db "ATD00455708763",13,0

Application_dialMSXVeendamCommand:
	db "ATD00598617502",13,0

Terminal_keyMap:
	db "0", "1", "2", "3", "4", "5", "6", "7"
	db "8", "9", "-", "=","\\", "[", "]", ";"
	db "'", "`", ",", ".", "/",   0, "a", "b"
	db "c", "d", "e", "f", "g", "h", "i", "j"
	db "k", "l", "m", "n", "o", "p", "q", "r"
	db "s", "t", "u", "v", "w", "x", "y", "z"
	db   0,   0,   0,   0,   0,   0,   0,   0
	db   0,   0,  27,   9,   0,   8,  24,  13
	db " ",  11,  18, 127,  29,  30,  31,  28
	db "*", "+", "/", "0", "1", "2", "3", "4"
	db "5", "6", "7", "8", "9", "-", ",", "."

Terminal_keyMapCaps:
	db "0", "1", "2", "3", "4", "5", "6", "7"
	db "8", "9", "-", "=","\\", "[", "]", ";"
	db "'", "`", ",", ".", "/",   0, "A", "B"
	db "C", "D", "E", "F", "G", "H", "I", "J"
	db "K", "L", "M", "N", "O", "P", "Q", "R"
	db "S", "T", "U", "V", "W", "X", "Y", "Z"
	db   0,   0,   0,   0,   0,   0,   0,   0
	db   0,   0,  27,   9,   0,   8,  24,  13
	db " ",  11,  18, 127,  29,  30,  31,  28
	db "*", "+", "/", "0", "1", "2", "3", "4"
	db "5", "6", "7", "8", "9", "-", ",", "."

Terminal_keyMapShift:
	db ")", "!", "@", "#", "$", "%", "^", "&"
	db "*", "(", "_", "+", "|", "{", "}", ":"
	db "\"","~", "<", ">", "?",   0, "A", "B"
	db "C", "D", "E", "F", "G", "H", "I", "J"
	db "K", "L", "M", "N", "O", "P", "Q", "R"
	db "S", "T", "U", "V", "W", "X", "Y", "Z"
	db   0,   0,   0,   0,   0,   0,   0,   0
	db   0,   0,  27,   9,   0,   8,  24,  13
	db " ",  11,  18, 127,  29,  30,  31,  28
	db "*", "+", "/", "0", "1", "2", "3", "4"
	db "5", "6", "7", "8", "9", "-", ",", "."

Terminal_keyMapCtrl:
	db   0,   0,   0,   0,   0,   0,  30,   0
	db   0,   0,  31,   0,  28,  27,  29,   0
	db   0,   0,   0,   0,   0,   0,   1,   2
	db   3,   4,   5,   6,   7,   8,   9,  10
	db  11,  12,  13,  14,  15,  16,  17,  18
	db  19,  20,  21,  22,  23,  24,  25,  26
	db   0,   0,   0,   0,   0,   0,   0,   0
	db   0,   0,   0,   0,   0,   0,   0,   0
	db   0,   0,   0,   0,   0,   0,   0,   0
	db   0,   0,   0,   0,   0,   0,   0,   0
	db   0,   0,   0,   0,   0,   0,   0,   0

Terminal_newKey:
	ds 11,0FFH

Terminal_oldKey:
	ds 11,0FFH

Interrupt_oldHook:
	ds 5,0C9H  ; ret

Application_returnStack:
	dw 0

Terminal_pendingEscape:
	db 0

Terminal_cursorX:
	db 0

Terminal_cursorY:
	db 0

Terminal_backgroundColor:
	db 0

Terminal_foregroundColor:
	db 7

Terminal_underline:
	db 0

Terminal_scroll:
	db 0

Terminal_scrollStep:
	db 0

Interrupt_currentScroll:
	db 0

Terminal_cursorXSaved:
	db 0

Terminal_cursorYSaved:
	db 0

Terminal_scrollSpeed:
	db 8

Interrupt_capsEnabled:
	db 0

Interrupt_capsPressed:
	db 0

Interrupt_oldPPIC:
	db 0

Application_logEnabled:
	db 0

Terminal_initialized:
	db 0

VDP_identification:
	db 0

VDP_registers:
	ds 28

Terminal_ansiPaletteMapping:
	db 1, 3, 5, 7, 9, 11, 13, 15
	db 2, 4, 6, 8, 10, 12, 14, 15

Terminal_msxPalette:
	db 0, 0, 0
	db 0, 0, 0
	db 1, 6, 1
	db 3, 7, 3
	db 1, 1, 7
	db 2, 3, 7
	db 5, 1, 1
	db 2, 6, 7
	db 7, 1, 1
	db 7, 3, 3
	db 6, 6, 1
	db 6, 6, 4
	db 1, 4, 1
	db 6, 2, 5
	db 5, 5, 5
	db 7, 7, 7

Terminal_ansiPalette:
	db 0, 0, 0
	db 0, 0, 0
	db 4, 4, 4
	db 4, 0, 0
	db 7, 0, 0
	db 0, 4, 0
	db 0, 7, 0
	db 4, 3, 0
	db 7, 7, 0
	db 0, 0, 4
	db 0, 0, 7
	db 5, 0, 5
	db 7, 0, 7
	db 0, 4, 4
	db 0, 7, 7
	db 7, 7, 7

YModemG_fileHandle:
	db 0

Log_fileHandle:
	db 0

Log_path:
	db "TERMINAL.LOG",0

Log_position:
	dw Log_BUFFER

YModemG_remainingBytes:
	dw 0, 0

Terminal_initScreenCommand:
	dw 0, 0
	dw 0, 0
	dw 200H, 100H
	db 0, 0, 0C0H  ; HMMV

Terminal_fontDuplicateCommand:
	dw 0, 100H
	dw 0, 120H
	dw 200H, 0C0H
	db 0, 0, 0D0H  ; HMMM

Terminal_fontColorCommand:
	dw 0, 0
	dw 0, 100H
	dw 200H, 20H
	db 0, 0, 81H  ; LMMV AND

Terminal_glyphCommand:
	dw 0, 100H
	dw 0, 0
	dw 6, 8
	db 0, 0, 0FFH

Terminal_brightGlyphCommand:
	dw 0, 100H
	dw 0, 1E0H
	dw 6, 8
	db 0, 0, 0FFH

Terminal_clearScreenCommand:
	dw 0, 0
	dw 12H, 0
	dw 1E0H, 100H
	db 0, 0, 0C0H  ; HMMV

Terminal_clearLinesCommand:
	dw 0, 0
	dw 12H, 0
	dw 1E0H, 0
	db 0, 0, 0C0H  ; HMMV

Terminal_clearPartialLineCommand:
	dw 0, 0
	dw 0, 0
	dw 0, 8
	db 0, 0, 0C0H  ; HMMV

Terminal_moveLinesCommand:
	dw 0, 0
	dw 12H, 0
	dw 1E0H, 8
	db 0, 0, 0E0H  ; YMMM

VDP_cursorSpritePatterns:
	db 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H, 0E0H
	db 0, 0, 0, 0, 0, 0E0H, 0E0H, 0E0H

Terminal_bufferPosition:
	dw Terminal_buffer

Terminal_buffer:
