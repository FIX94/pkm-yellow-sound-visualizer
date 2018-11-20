; Copyright (C) 2018 FIX94
;
; This software may be modified and distributed under the terms
; of the MIT license.  See the LICENSE file for details.

SECTION "WRAM",ROM0[$DA7F]

;some game functions used
gameUpdateControls EQU $01B9
gamePlaySong EQU $2211
;some game variables used
gameUpdateOAMData EQU $CFCA
gameDisableWindowScroll EQU $D09F
;include our actual code
include "visualizer.asm"
