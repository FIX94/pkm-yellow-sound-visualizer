; Copyright (C) 2018 FIX94
;
; This software may be modified and distributed under the terms
; of the MIT license.  See the LICENSE file for details.

SECTION "WRAM",ROM0[$DA84]

;some game functions used
gameUpdateControls EQU $01B9
gamePlaySong EQU $2216
;some game variables used
gameUpdateOAMData EQU $CFCF
gameDisableWindowScroll EQU $D0A4
;include our actual code
include "visualizer.asm"
