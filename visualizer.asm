; Copyright (C) 2018 FIX94
;
; This software may be modified and distributed under the terms
; of the MIT license.  See the LICENSE file for details.

include "charmap.asm"

;shared high variables
hGameOAMDMAFunc EQU $FF80
hGameButtonsPressed EQU $FFB3
hGameBGScrollX EQU $FFAE
hGameBGScrollY EQU $FFAF
hGameAutoBGCopy EQU $FFBA
hGameVBlankCopy1Addr EQU $FFC1
hGameVBlankCopy2Len EQU $FFC6
hGameVBlankCopy3Len EQU $FFCB
hGameRedrawBG EQU $FFD0
hGameTileAnimation EQU $FFD7

init:
	di
	;disable game oam dma
	ld a, $C9 ;ret
	ldh [hGameOAMDMAFunc], a
	ld a, $0
	;disable game background (re)draw
	ldh [hGameAutoBGCopy], a
	ldh [hGameVBlankCopy1Addr], a
	ldh [hGameVBlankCopy1Addr+1], a
	ldh [hGameVBlankCopy2Len], a
	ldh [hGameVBlankCopy3Len], a
	ldh [hGameRedrawBG], a
	ldh [hGameTileAnimation], a
	;disable game background scroll
	ldh [hGameBGScrollX], a
	ldh [hGameBGScrollY], a
	;disable game oam data prep
	ld [gameUpdateOAMData], a
	;disable game window scroll
	ld a, $1
	ld [gameDisableWindowScroll], a
	;clear screen and draw header
	call waitVBlank
	ld a, $0
	ldh [$FF40], a
	call clearScreen
	call drawHeader
	;draw black bars
	ld hl, $9940
	call drawVolbar
	ld hl, $9980
	call drawVolbar
	ld hl, $99C0
	call drawVolbar
	ld hl, $9A00
	call drawVolbar
	;make sure bars are actually visible
	ld hl, $9000
	ld a, $FF
	ld b, $10
bartileloop:
	ld [hl+], a
	dec b
	jr nz, bartileloop
	;draw channel names
	ld bc, $9921
	ld hl, sq1msg
	call drawLine
	ld c, $61
	ld hl, sq2msg
	call drawLine
	ld c, $A1
	ld hl, noisemsg
	call drawLine
	ld c, $E1
	ld hl, wavemsg
	call drawLine
	;turn on screen
	ld a, $E1
	ldh [$FF40], a
	;cover screen with window
	ld a, $00
	ldh [$FF4A], a
	;scroll window out of the way for now
	ld a, $A8
	ldh [$FF4B], a
	;set first lyc value
	ld a, $4F
	ldh [$FF45], a
	;enable vblank and lyc interrupt
	ld a, $40
	ldh [$FF41], a
	ld a, 3
	ldh [$FFFF], a
	ld a, 0
	ldh [$FF0F], a
	;call music function
	ei
	ld a, [songvar]
	call playsong
	;draw volume loop
tloop:
	halt
	;see if its our line interrupt
	ldh a, [$FF44]
	cp $4F
	jr z, dopcm1
	cp $57
	jr z, setlycpcm2
	cp $5F
	jr z, dopcm2
	cp $67
	jr z, setlycpcm3
	cp $6F
	jr z, dopcm3
	cp $77
	jr z, setlycpcm4
	cp $7F
	jr z, dopcm4
	cp $87
	jr nz, tloop
	;time to do volume update
prepframe:
	;clear window x scroll
	ld a, $A8
	ldh [$FF4B], a
	;set next lyc
	ld a, $4F
	ldh [$FF45], a
	;update controls
	call gameUpdateControls
	ldh a, [hGameButtonsPressed]
	ld b, a
	and $30
	jr z, newvol
	ld a, b
	call switchSong
	jr tloop
newvol:
	;fill up vol for next frame
	call fillVol
	jr tloop
dopcm1:
	;set next lyc
	ld a, $57
	ldh [$FF45], a
	;get pcm1
	ld a, [volvar]
	swap a
	jr setbar
setlycpcm2:
	;set next lyc
	ld a, $5F
	ldh [$FF45], a
	;waste some extra cycles
	;before setting new scroll
	call waitlycpcm2
	;clear scroll
	ld a, $A8
	jr dowindowscroll
dopcm2:
	;set next lyc
	ld a, $67
	ldh [$FF45], a
	;get pcm2
	ld a, [volvar]
	jr setbar
setlycpcm3:
	;set next lyc
	ld a, $6F
	ldh [$FF45], a
	;waste some extra cycles
	;before setting new scroll
	call waitlycpcm2
	;clear scroll
	ld a, $A8
	jr dowindowscroll
dopcm3:
	;set next lyc
	ld a, $77
	ldh [$FF45], a
	;get pcm3
	ld a, [volvar+1]
	swap a
	jr setbar
setlycpcm4:
	;set next lyc
	ld a, $7F
	ldh [$FF45], a
	;clear scroll
	ld a, $A8
	jr dowindowscroll
dopcm4:
	;set next lyc
	ld a, $87
	ldh [$FF45], a
	;get pcm4
	ld a, [volvar+1]
	jr setbar
setbar:
	;add pcm to dotlut
	ld hl, dotlut
	ld b, 0
	and $F
	ld c, a
	;load from lut
	add hl, bc
	ld a, [hl]
dowindowscroll:
	;write window x scroll
	ldh [$FF4B], a
	jp tloop

switchSong:
	and $10
	jr nz, goright
goleft:
	ld a, [songvar]
	dec a
	cp $ff
	jr nz, savesongandplay
	ld a, $30
	jr savesongandplay
goright:
	ld a, [songvar]
	inc a
	cp $31
	jr nz, savesongandplay
	ld a, 0
	jr savesongandplay
savesongandplay:
	ld [songvar], a
	call playsong
	ret

fillVol:
	;poll squares a lot
	ld c, 0
	ld hl, $FF76
	call fillVolPoll
	ld [volvar], a
	;poll noise and wave far less
	ld c, $40
	inc hl
	call fillVolPoll
	ld [volvar+1], a
	ret

fillVolPoll:
	ld b, 0
fillvolloop:
	ld a, [hl]
	or b
	ld b, a
	dec c
	jr nz, fillvolloop
	ld a, b
	ret

waitlycpcm2:
	;without this little wait
	;it would reset the window
	;x scroll too early
	dec hl
	inc hl
	ret

; video stuff
waitVBlank:
	ldh a,[$FF44]
	cp 145
	jr nz, waitVBlank
	ret

clearScreen:
	ld hl, $9800
	ld a, $7F
clrloop:
	ld [hl+], a
	bit 3, h
	jr nz, clrloop
	ret

drawLine:
	ld a, [hl+]
	cp 0
	ret z
	ld [bc], a
	inc c
	jr drawLine

drawHeader:
	ld bc, $9821
	ld hl, hdrmsg
	call drawLine
	ld c, $41
	call drawLine
	ret

drawVolbar:
	ld a, 0
	ld b, $14
volloop:
	ld [hl+], a
	dec b
	jr nz, volloop
	ret

dotlut:
	db $0A, $14, $1E, $28, $32, $3C, $46, $50, $5A, $64, $6E, $78, $82, $8C, $96, $A0

volvar:
	db $00, $00

playsong:
	ld hl, songlut
	ld b, 0
	ld c, a
	sla c
	add hl, bc
	ld a, [hl+]
	ld c, a
	ld a, [hl]
	call gamePlaySong
	ret

songlut:
	;bank 02 songs
	db $02, $BA, $02, $BD, $02, $C0, $02, $C3, $02, $C7, $02, $CA, $02, $CD, $02, $D0, $02, $D4, $02, $D8
	db $02, $DB, $02, $DE, $02, $E1, $02, $E5, $02, $E8, $02, $EB, $02, $EF, $02, $F3, $02, $F7, $02, $FB
	;bank 08 songs
	db $08, $EA, $08, $ED, $08, $F0, $08, $F3, $08, $F6, $08, $F9, $08, $FC
	;bank 1F songs
	db $1F, $C3, $1F, $C7, $1F, $CA, $1F, $CD, $1F, $D0, $1F, $D2, $1F, $D6, $1F, $D9, $1F, $DC, $1F, $DF
	db $1F, $E3, $1F, $E7, $1F, $EB, $1F, $EF, $1F, $F2, $1F, $F5, $1F, $F8, $1F, $FB
	;bank 20 songs
	db $20, $99, $20, $9C, $20, $9F, $20, $A3

songvar:
	db $00

hdrmsg:
	db "Sound Visualizer ", $00
	db "v0.1 by FIX94", $00

sq1msg:
	db "Square 1", $00

sq2msg:
	db "Square 2", $00

noisemsg:
	db "Noise", $00

wavemsg:
	db "Wave", $00
