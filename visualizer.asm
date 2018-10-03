; Copyright (C) 2018 FIX94
;
; This software may be modified and distributed under the terms
; of the MIT license.  See the LICENSE file for details.

;re-use character map game left in memory
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
	;disable interrupts for
	;game cleanup
	di
	;disable game oam dma
	ld a, $C9 ;ret
	ldh [hGameOAMDMAFunc], a
	xor a
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
	xor a
	ldh [$FF40], a
	call clearScreen
	call drawHeader
	;draw black bars
	ld hl, $9940
	call drawVolbar
	ld l, $80
	call drawVolbar
	ld l, $C0
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
	ld d, 8
	ld hl, chanmsg
	call drawLine
	ld c, $61
	ld d, 8
	call drawLine
	ld c, $A1
	ld d, 5
	call drawLine
	ld c, $E1
	ld d, 4
	call drawLine
	;turn on screen
	ld a, $E1
	ldh [$FF40], a
	;cover screen with window
	xor a
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
	;call music function,
	;enables interrupts for us
	xor a
	call playSong
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
	and $33
	jr z, newvol
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
	;check b press
	bit 1, b
	jr z, notb
	;stop play
	ld a, $80
	jr skipsaveandplay
notb:
	;used in a, left and right
	ld a, [songvar]
	;check a press
	bit 0, b
	jr z, checkleft
	;(re)start play
	jr skipsaveandplay
checkleft:
	bit 4, b
	jr z, goleft
goright: ;remaining bit is right
	inc a
	cp $32
	jr nz, savesongandplay
	xor a ;loop back to first
	jr savesongandplay
goleft:
	dec a
	cp $ff
	jr nz, savesongandplay
	ld a, $31 ;last song in list
savesongandplay:
	ld [songvar], a
skipsaveandplay:
	call playSong
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
	ld [bc], a
	inc c
	dec d
	ret z
	jr drawLine

drawHeader:
	ld bc, $9821
	ld d, 16
	ld hl, hdrmsg
	call drawLine
	ld c, $41
	ld d, 13
	call drawLine
	ld c, $81
	ld d, 16
	call drawLine
	ld c, $A1
	ld d, 16
	call drawLine
	ret

drawSongName:
	sla c
	sla c
	sla c
	ld b, 0
	jr nc, songnameadd
	inc b
songnameadd:
	ld hl, songnames
	add hl, bc
	ld bc, $98E3
	ld d, 8
	call drawLine
	ret

drawVolbar:
	xor a
	ld b, $14
volloop:
	ld [hl+], a
	dec b
	jr nz, volloop
	ret

playSong:
	;disable interrupts for vblank
	di
	;save song value
	ld c, a
	push bc
	;load vals for stop
	ld a, $FF
	ld c, $1F
	;first stop current song
	call gamePlaySong
	;wait for vblank so we can write to vram
	call waitVBlank
	;draw play/stop tile
	pop bc
	bit 7, c
	jr z, playtile
	;stop requested
	xor a ;black box for stop
	ld [$98E1], a
	jr playsongend
playtile: ;keep playing
	ld a, $ED ;arrow for play
	ld [$98E1], a
	;draw song name
	push bc
	call drawSongName
	pop bc
	;then load next from LUT
	ld hl, songlut
	ld b, 0
	sla c
	add hl, bc
	ld a, [hl+]
	ld c, a
	ld a, [hl]
	call gamePlaySong
playsongend:
	;clear interrupt flags
	xor a
	ldh [$FF0F], a
	;re-enable interrupts
	ei
	ret

dotlut:
	;window positions of the volume bar
	db $07, $12, $1C, $27, $32, $3C, $47, $52, $5C, $67, $72, $7C, $87, $92, $9C, $A7

songlut:
	;bank 02, 08, 1F songs ordered to match official soundtrack, ended by bank 20 songs, yellow exclusives
	db $1F, $DC, $1F, $C3, $02, $BA, $02, $DB, $1F, $CD, $02, $DE, $02, $EB, $08, $F0, $08, $F9, $02, $C3
	db $02, $BD, $02, $E8, $1F, $E3, $02, $E1, $1F, $F8, $08, $ED, $08, $F6, $1F, $E7, $02, $F3, $02, $C7
	db $02, $C0, $02, $EF, $1F, $D0, $02, $D0, $02, $D8, $02, $F7, $02, $B8, $1F, $FB, $08, $EA, $08, $FC
	db $1F, $D2, $02, $D4, $1F, $EF, $02, $CA, $1F, $D9, $1F, $F5, $1F, $DF, $1F, $F2, $1F, $D6, $02, $CD
	db $1F, $EB, $02, $E5, $02, $FB, $08, $F3, $1F, $CA, $1F, $C7, $20, $99, $20, $9C, $20, $9F, $20, $A3

songnames:
	;shortened track names sorted to match LUT above, all 8 characters in length to fit into ram
	db "Opening ", "Title   ", "Pallet  ", "Prof.Oak", "Oaks Lab", "Rival   ", "Routes 1", "Battle 1", "Victory1", "Pewter  "
	db "P.Center", "Healed  ", "V.Forest", "Guide   ", "Appear 1", "Battle 2", "Victory2", "Caves   ", "Routes 2", "Cerulean"
	db "Pkm.Gym ", "Routes 3", "Jig.Puff", "Vermill.", "S.S.Anne", "Routes 4", "Pk.Flute", "Appear 2", "Battle 3", "Victory3"
	db "Cycling ", "Lavender", "Pk.Tower", "Celadon ", "Game Co.", "Appear 3", "Hideout ", "SilphCo.", "Surfing ", "Cinnabar"
	db "Mansion ", "SafariZ.", "Routes 5", "Battle 4", "H.OfFame", "Ending  ", "SurfPika", "Appear 4", "Unused  ", "Printer "

hdrmsg:
	;header on top of image
	db "Sound Visualizer"
	db "v0.2 by FIX94"
	db "A: Play, B: Stop"
	db "L: Prev, R: Next"

chanmsg:
	;audio channel names
	db "Square 1"
	db "Square 2"
	db "Noise"
	db "Wave"

volvar:
	;volumes for current frame
	db $00, $00

songvar:
	;song currently selected
	db $00
