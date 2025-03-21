DEF STATF_OAM EQU  %00000010 ; OAM-RAM is used by system
DEF FONT_SIZE EQU 16*41
DEF rSTAT EQU $FF41
DEF rBGP EQU $FF47
DEF rP1 EQU $FF00
DEF rAUDVOL EQU $FF24
DEF rAUDTERM EQU $FF25
DEF rAUDENA EQU $FF26

DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23

def TileDataLow EQU $8000
def FontDataVram EQU $8000
def LogoDataVram EQU $8300
def CHAR_OFFSET EQU $37
def REG_X_ALIGN EQU 2
def VALUE_X_ALIGN EQU 17
def Y_ALIGN EQU 6
def NUM_REGS EQU 9

def JoyPadData EQU $c100
def JoyPadNewPresses EQU $c101
def PointerIndexY EQU $c102
def CursorIndex EQU $c103 ; 0 -> length, 1 -> init volume, 2 -> envelope, 3 -> period, 4 -> lfsr, 5 -> shift, 6 -> divider, 7 -> length enable, 8 -> play
def PresetIndex EQU $c104

def RegBase EQU $c110
def RegLength EQU $c110 ; 0-63
def RegInitVolume EQU $c111 ; 0-15
def RegEnvelopeMode EQU $c112 ; 0 -> decrement, 1 -> increment
def RegEnvelopePeriod EQU $c113 ; 0-7
def RegLfsrWidth EQU $c114 ; 0 -> 15 bit, 1 -> 7 bit
def RegClockShift EQU $c115 ; 0-15
def RegDivisor EQU $c116 ; 0-7
def RegLengthEnable EQU $c117 ; 0 -> infinite sound, 1 -> length according to length register

def LimitBase EQU $c210
def LimitLength EQU $c210
def LimitInitVolume EQU $c211
def LimitEnvelopeMode EQU $c212
def LimitEnvelopePeriod EQU $c213
def LimitLfsrWidth EQU $c214
def LimitClockShift EQU $c215
def LimitDivisor EQU $c216
def LimitLengthEnable EQU $c217

def SIZE_FONT_DATA EQU 41 ; Size in tiles.
def SIZE_LOGO_DATA EQU 80 ; Size in tiles.
def NUM_PRESETS EQU 8

def MASK_BUTTON_A EQU %1
def MASK_BUTTON_B EQU %10
def MASK_BUTTON_SELECT EQU %100
def MASK_BUTTON_START EQU %1000
def MASK_BUTTON_RIGHT EQU %10000
def MASK_BUTTON_LEFT EQU %100000
def MASK_BUTTON_UP EQU %1000000
def MASK_BUTTON_DOWN EQU %10000000

charmap "0", $37
charmap "1", $38
charmap "2", $39
charmap "3", $3a
charmap "4", $3b
charmap "5", $3c
charmap "6", $3d
charmap "7", $3e
charmap "8", $3f
charmap "9", $40

; Return of address of lower tile map index.
; Args: register to be loaded with address, x coordinate, y coordinate
MACRO TilemapLow
    ld \1, $9800 + \3 * 32 + \2
ENDM

def POINTER_INDEX EQU $28

SECTION "ROM Bank 0 $100", ROM0[$100]

Entry::
  nop
  jp Start

; See: https://gbdev.gg8.se/wiki/articles/The_Cartridge_Header
 HeaderLogo::
  db $ce, $ed, $66, $66, $cc, $0d, $00, $0b, $03, $73, $00, $83, $00, $0c, $00, $0d
  db $00, $08, $11, $1f, $88, $89, $00, $0e, $dc, $cc, $6e, $e6, $dd, $dd, $d9, $99
  db $bb, $bb, $67, $63, $6e, $0e, $ec, $cc, $dd, $dc, $99, $9f, $bb, $b9, $33, $3e

HeaderTitle::
  db "NOISE TEST", $00, $00, $00, $00, $00, $00

HeaderNewLicenseeCode::
  db $00, $00

HeaderSGBFlag::
  db $00

HeaderCartridgeType::
  db $00

HeaderROMSize::
  db $00

HeaderRAMSize::
  db $00

HeaderDestinationCode::
  db $01

HeaderOldLicenseeCode::
  db $00

HeaderMaskROMVersion::
  db $00

SECTION "ROM Bank 0 $500", ROM0[$500]
Start::
  ld a, %10001111
  ldh [rAUDENA], a            ; Turn on sound.
  ld a, $ff
  ldh [rAUDVOL], a            ; Full volume, both channels on.
  ldh [rAUDTERM], a           ; All sounds to all terminal.
  xor a
  ld [JoyPadData], a
  ld [JoyPadNewPresses], a
  ld [CursorIndex], a
  ld [PresetIndex], a
  ld [RegInitVolume], a
  ld [RegEnvelopeMode], a
  ld [RegEnvelopePeriod], a
  ld [RegClockShift], a
  ld [RegLfsrWidth], a
  ld [RegDivisor], a
  ld [RegLengthEnable], a
  ld [RegLength], a
  ld a, 2
  ld [LimitEnvelopeMode], a
  ld [LimitLfsrWidth], a
  ld [LimitLengthEnable], a
  ld a, 64
  ld [LimitLength], a
  ld a, 16
  ld [LimitInitVolume], a
  ld [LimitClockShift], a
  ld a, 8
  ld [LimitEnvelopePeriod], a
  ld [LimitDivisor], a

  ld a, %11100100
  ldh [rBGP], a
  ld a, SIZE_FONT_DATA
  ld hl, FontData
  ld de, FontDataVram
  call CopyTilesToVram
  ld hl, NoiseTestLogoData
  ld de, LogoDataVram
  ld a, SIZE_LOGO_DATA
  call CopyTilesToVram
  ld hl, $9800
  ld a, $30
  ld c, 4
  ld d, 0
  ld e, 12
: ld b, 20
: ld [hl+], a
  inc a
  dec b
  jr nz, :-
  add hl, de
  dec c
  jr nz, :--
  call RedrawScreen

.Loop:
  call ReadJoyPad
  ld a, [JoyPadNewPresses]
  ld b, MASK_BUTTON_DOWN
  and b
  call nz, PressedDownButton

  ld a, [JoyPadNewPresses]
  ld b, MASK_BUTTON_UP
  and b
  call nz, PressedUpButton

  ld a, [JoyPadNewPresses]
  ld b, MASK_BUTTON_RIGHT
  and b
  call nz, PressedRightButton

  ld a, [JoyPadNewPresses]
  ld b, MASK_BUTTON_LEFT
  and b
  call nz, PressedLeftButton

  ld a, [JoyPadNewPresses]
  ld b, MASK_BUTTON_A
  and b
  call nz, PressedAButton

  ld a, [JoyPadNewPresses]
  ld b, MASK_BUTTON_SELECT
  and b
  call nz, PressedSelectButton

  jp .Loop

RedrawScreen:
  ld hl, $9880
  ld a, $ff

ZeroInitTileMap::
  ld [hl+], a
  ld a, h
  cp $9b
  jr nz, ZeroInitTileMap

  TilemapLow de, REG_X_ALIGN, Y_ALIGN
  ld hl, LengthString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 1)
  ld hl, InitVolumeString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 2)
  ld hl, EnvelopeModeString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 3)
  ld hl, EnvelopePeriodString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 4)
  ld hl, LfsrString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 5)
  ld hl, ShiftString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 6)
  ld hl, DividerString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 7)
  ld hl, LengthEnableString
  call DrawString

  TilemapLow de, REG_X_ALIGN, (Y_ALIGN + 8)
  ld hl, PlayString
  call DrawString

  TilemapLow de, 7, 16
  ld hl, PresetString
  call DrawString
  ld a, [PresetIndex]
  ld [de], a

  TilemapLow hl, VALUE_X_ALIGN, Y_ALIGN
  ld a, [RegLength]
  call BinToBcd6Bit
  ld c, a
  and a, $0f
  ld [hl-], a
  ld a, c
  swap a
  and a, $0f
  ld [hl], a

  TilemapLow hl, VALUE_X_ALIGN, (Y_ALIGN + 1)
  ld a, [RegInitVolume]
  call BinToBcd6Bit
  ld c, a
  and a, $0f
  ld [hl-], a
  ld a, c
  swap a
  and a, $0f
  ld [hl], a

  TilemapLow hl, VALUE_X_ALIGN, (Y_ALIGN + 2)
  ld a, [RegEnvelopeMode]
  call BinToBcd6Bit
  ld [hl], a

  TilemapLow de, VALUE_X_ALIGN, (Y_ALIGN + 3)
  ld a, [RegEnvelopePeriod]
  call BinToBcd6Bit
  ld [de], a

  TilemapLow de, VALUE_X_ALIGN, (Y_ALIGN + 4)
  ld a, [RegLfsrWidth]
  call BinToBcd6Bit
  ld [de], a

  TilemapLow hl, VALUE_X_ALIGN, (Y_ALIGN + 5)
  ld a, [RegClockShift]
  call BinToBcd6Bit
  ld c, a
  and a, $0f
  ld [hl-], a
  swap a
  and a, $0f
  ld [hl], a

  TilemapLow de, VALUE_X_ALIGN, (Y_ALIGN + 6)
  ld a, [RegDivisor]
  call BinToBcd6Bit
  ld [de], a

  TilemapLow de, VALUE_X_ALIGN, (Y_ALIGN + 7)
  ld a, [RegLengthEnable]
  call BinToBcd6Bit
  ld [de], a

  ld a, [CursorIndex]
  add a, Y_ALIGN
  ld d, a
  ld c, REG_X_ALIGN - 1
  call TileMapLowFunc
  ld a, POINTER_INDEX
  ld [bc], a
  ret

; Select next lower option.
PressedDownButton::
  ld a, [CursorIndex]
  ld b, a
  sub a, NUM_REGS - 1
  jr nz, :+
  ld b, -1
: inc b
  ld a, b
  ld [CursorIndex], a
  call RedrawScreen
  ret

; Select next upper option.
PressedUpButton::
  ld a, [CursorIndex]
  or a
  jr nz, :+
  ld a, NUM_REGS
: dec a
  ld [CursorIndex], a
  call RedrawScreen
  ret

; Increase value of currently selected option.
PressedRightButton::
  ld a, [CursorIndex]
  ld d, 0
  ld e, a
  ld hl, RegBase
  add hl, de
  ld a, [hl]
  push hl
  inc a
  ld b, a
  ld hl, LimitBase
  add hl, de
  ld a, [hl]
  cp b
  jr nz, :+
  ld b, 0
: ld a, b
  pop hl
  ld [hl], a
  call RedrawScreen
  call ValueToReg
  ret

; Decrease value of currently selected option.
PressedLeftButton::
  ld a, [CursorIndex]
  ld d, 0
  ld e, a
  ld hl, RegBase
  add hl, de
  ld a, [hl]
  push hl
  cp 0
  jr nz, :+
  ld b, a
  ld hl, LimitBase
  add hl, de
  ld a, [hl]
: dec a
  pop hl
  ld [hl], a
  call RedrawScreen
  call ValueToReg
  ret

; If "PLAY" is currently selected, the sound registers are updated and the noise channel is triggered.
PressedAButton::
  call RedrawScreen
  ld a, [CursorIndex]
  cp NUM_REGS - 1
  ret nz
  ld a, [RegLength]
  ldh [rNR41], a
  ld a, [RegInitVolume]
  swap a
  ld b, a
  ld a, [RegEnvelopeMode]
  sla a
  sla a
  sla a
  or b
  ld b, a
  ld a, [RegEnvelopePeriod]
  or b
  ldh [rNR42], a
  ld a, [RegClockShift]
  swap a
  ld b, a
  ld a, [RegLfsrWidth]
  sla a
  sla a
  sla a
  or b
  ld b, a
  ld a, [RegDivisor]
  or b
  ldh [rNR43], a
  ld a, [RegLengthEnable]
  sla a
  sla a
  or %1000
  swap a
  ldh [rNR44], a
  ret

; Update all sound registers according to the new preset.
PressedSelectButton:
  ld a, [PresetIndex]
  inc a
  cp NUM_PRESETS
  jr nz, :+
  ld a, 0
: ld [PresetIndex], a
  ld hl, PresetPtrs
  ld b, 0
  add a
  ld c, a
  add hl, bc
  ld a, [hl+]
  ld c, a
  ld a, [hl]
  ld b, a
  ld h, b
  ld l, c
  ld a, [hl+]
  ld [RegInitVolume], a
  ld a, [hl+]
  ld [RegEnvelopeMode], a
  ld a, [hl+]
  ld [RegEnvelopePeriod], a
  ld a, [hl+]
  ld [RegClockShift], a
  ld a, [hl+]
  ld [RegLfsrWidth], a
  ld a, [hl+]
  ld [RegDivisor], a
  ld a, [hl+]
  ld [RegLengthEnable], a
  ld a, [hl+]
  ld [RegLength], a
  call RedrawScreen
  ret

; Updates currently changed sound register except for length enable and trigger.
ValueToReg::
  ld a, [CursorIndex]
  cp 0
  jr nz, :+
  ld a, [RegLength]
  ldh [rNR41], a
  ret
: cp 4
  jr nc, :+
  ld a, [RegInitVolume]
  swap a
  ld b, a
  ld a, [RegEnvelopeMode]
  sla a
  sla a
  sla a
  or b
  ld b, a
  ld a, [RegEnvelopePeriod]
  or b
  ldh [rNR42], a
  ret
: cp 7
  jr nc, :+
  ld a, [RegClockShift]
  swap a
  ld b, a
  ld a, [RegLfsrWidth]
  sla a
  sla a
  sla a
  or b
  ld b, a
  ld a, [RegDivisor]
  or b
  ldh [rNR43], a
: ret

; Like TileMapLow but as a function. X coord in "c", Y coord in "d". Result in "bc"
TileMapLowFunc::
  ld b, $98
  ld a, 5
.Loop:
  sla d
  jr nc, .SkipCarry
  inc b
.SkipCarry:
  dec a
  jr nz, .Loop
  ld a, d
  add a, c
jr nc, .SkipCarry2
  inc b
.SkipCarry2:
  ld c, a
  ret

; String address has to be in "hl". Tile map pointer in "de".
DrawString::
  ld b, CHAR_OFFSET
  ld a, [hl+]
  or a
  ret z
  sub a, b
  ld [de], a
  inc de
  jr DrawString

; Copies "a" tiles (each 16 byte) from [hl] to [de] with respect to the OAM flag.
CopyTilesToVram::
.Loop:
  push af
  ld a, 16
  call CopyBytesToVram
  pop af
  dec a
  jr nz, .Loop
  ret

; Copies "a" byte from [hl] to [de] with respect to the OAM flag.
CopyBytesToVram::
  ld b, STATF_OAM
.Loop:
  or a
  ret z
  ld c, a
: ldh a, [rSTAT]
  and b
  jr nz, :-                       ; Wait for OAM.
  ld a, [hl+]
  ld [de], a
  ld a, c
  inc de
  dec a
  jr .Loop

; $b2: Read joy pad and save result in JoyPadData and JoyNewPressess.
; From MSB to LSB: down, up, left, right, start, select, B, A.
ReadJoyPad:
  ld a, $20
  ldh [rP1], a              ; Select direction keys.
  ldh a, [rP1]              ; Wait.
  ldh a, [rP1]              ; Read keys.
  cpl                       ; Invert, so a button press becomes 1.
  and $0f                   ; Select lower 4 bits.
  swap a
  ld b, a                   ; Direction key buttons now in upper nibble of b.
  ld a, $10
  ldh [rP1], a              ; Select button keys.
  ldh a, [rP1]              ; Wait.
  ldh a, [rP1]              ; Wait.
  ldh a, [rP1]              ; Wait.
  ldh a, [rP1]              ; Wait.
  ldh a, [rP1]              ; Wait.
  ldh a, [rP1]              ; Read keys.
  cpl                       ; Same procedure as before...
  and $0f
  or b                      ; Button keys now in lower nibble of a.
  ld c, a
  ld a, [JoyPadData]        ; Read old joy pad data.
  xor c                     ; Get changes from old to new.
  and c                     ; Only keep new buttons pressed.
  ld [JoyPadNewPresses], a  ; Save new joy pad data.
  ld a, c
  ld [JoyPadData], a        ; Save newly pressed buttons.
  ld a, $30
  ldh [rP1], a              ; Disable selection.
  ret

; Input in "a". Result in "a". Maximum of 6 bits.
BinToBcd6Bit:
    and $3f
    ld c, a
    ld b, 0
.LoopSubtractTen:
    cp 10
    jr c, .Done
    sub 10
    inc b
    jr .LoopSubtractTen
.Done:
    swap b
    add b
    ret

FontData::
  INCBIN "font.2bpp"

NoiseTestLogoData::
  INCBIN "noise_test_logo.2bpp"

NoiseString::
  db "NOISE",0

SquareString::
  db "SQUARE",0

LengthString::
  db "LENGTH",0

InitVolumeString::
  db "INIT VOLUME",0

EnvelopeModeString::
  db "ENVELOPE",0

EnvelopePeriodString::
  db "PERIOD", 0

LfsrString::
  db "LFSR",0

ShiftString::
  db "SHIFT",0

DividerString::
  db "DIVIDER",0

LengthEnableString::
  db "LENGTH ENABLE",0

PlayString::
  db "PLAY",0

PresetString::
  db "PRESET",0

PresetPtrs:
  dw Preset0
  dw Preset1
  dw Preset2
  dw Preset3
  dw Preset4
  dw Preset5
  dw Preset6
  dw Preset7

Preset0::
  db 0  ; init volume
  db 0  ; envelope mode
  db 0  ; envelope period
  db 0  ; clock shift
  db 0  ; LFSR width
  db 0  ; divisor
  db 0  ; length enable
  db 0  ; length

; Snare from Tetris.
Preset1::
  db 10  ; init volume
  db 0   ; envelope mode
  db 1   ; envelope period
  db 0   ; clock shift
  db 0   ; LFSR width
  db 0   ; divisor
  db 1   ; length enable
  db 58  ; length

; Another snare from Tetris.
Preset2::
  db 11  ; init volume
  db 0   ; envelope mode
  db 1   ; envelope period
  db 0   ; clock shift
  db 0   ; LFSR width
  db 1   ; divisor
  db 1   ; length enable
  db 41  ; length

; Fade-in snare.
Preset3::
  db 0   ; init volume
  db 1   ; envelope mode
  db 1   ; envelope period
  db 0   ; clock shift
  db 0   ; LFSR width
  db 1   ; divisor
  db 1   ; length enable
  db 1   ; length

; Bombshell Koopas (Nokobon) explosion from Super Mario Land.
Preset4::
  db 15  ; init volume
  db 0   ; envelope mode
  db 4   ; envelope period
  db 5   ; clock shift
  db 0   ; LFSR width
  db 7   ; divisor
  db 0   ; length enable
  db 0   ; length

; Explosion.
Preset5::
  db 15  ; init volume
  db 0   ; envelope mode
  db 3   ; envelope period
  db 5   ; clock shift
  db 0   ; LFSR width
  db 3   ; divisor
  db 0   ; length enable
  db 1   ; length

; Chiptune-like Explosion.
Preset6::
  db 15   ; init volume
  db 0   ; envelope mode
  db 5   ; envelope period
  db 8   ; clock shift
  db 0   ; LFSR width
  db 1   ; divisor
  db 0   ; length enable
  db 1   ; length

; First noise part of defeating a fight fly from Super Mario Land.
Preset7::
  db 2   ; init volume
  db 1   ; envelope mode
  db 4   ; envelope period
  db 1   ; clock shift
  db 1   ; LFSR width
  db 6   ; divisor
  db 1   ; length enable
  db 0   ; length
