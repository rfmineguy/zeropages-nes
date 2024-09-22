; iNES header (for emulator)
.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02                     ; 2 * 16k PRG ROM
.byte $01                     ; 1 * 8k  CHR ROM
.byte %00000000               ; mapper and mirroring
.byte $00, $00, $00, $00      ; see nesdev wiki
.byte $00, $00, $00, $00, $00 ; filler bytes

; Vector segment
.segment "VECTORS"
.word nmi   ; when ppu begins vblank
.word reset ; when the reset button is pressed
.word 0     ; interrupt handler for mapper

.segment "ZEROPAGE"
.segment "STARTUP"
reset:
    sei                ; disable interrupts
    cld                ; disable decimal mode (not supported on the nes 6502)
    
    ldx #$40           ; disable sound IRQ
    stx $4017          ; 

    ldx #$ff           ; initialize stack register to ff
    txs                ;
    
    inx                ; put PPU in known state
    stx $2000          ;
    stx $2001          ;

    stx $4010          ;

:   bit $2002          ; check if vblank occured (look at bit 7 of addr 2002 to check if vblank is active)
    bpl :- 

    txa                ; clear out memory $0000-$0800
clearmem:
    sta $0000, X       ; zero $0000-$00ff
    sta $0100, X       ; zero $0100-$01ff
    ; sta $0200, X     ; zero $0200-$02ff
    sta $0300, X       ; zero $0300-$03ff
    sta $0400, X       ; zero $0400-$04ff
    sta $0500, X       ; zero $0500-$05ff
    sta $0600, X       ; zero $0600-$06ff
    sta $0700, X       ; zero $0700-$07ff
    lda #$ff
    sta $0200, X       ; $0200-$02ff used for sprite data
    lda #$00
    inx
    bne clearmem       ; if x == 0 then branch

:   bit $2002          ; wait for vblank
    bpl :-             

    lda #$02           ; set sprite memory addresss to $0200
    sta $4014          ;
    nop                ;

    lda #$3f           ; set ppu write address to $3f00
    sta $2006          ;
    lda #$00           ;
    sta $2006          ;

    ldx #$00           ; load pallete data
loadpallete:
    lda palletedata, x
    sta $2007          ; write a to ppu addr $3f00 (the address is automatically incremented here)
    inx                ; go to next pallete byte
    cpx #$20           ; 
    bne loadpallete    ; loop 32 times

    ldx #$00           ; load sprites
loadsprites:
    lda spritedata, x
    sta $0200, x
    inx
    cpx #$20
    bne loadsprites

    cli                ; enable interrupts
    lda #%10010000     ; vblank trigger nmi, background uses tile bank 2 (not tb1)
    sta $2000

    lda #%00011110     ; enable sprite and bkgd for left 8 pixels, enable sprite and background
    sta $2001

:   jmp :-

nmi:
    lda #$02           ; copy data from 0200 into ppu memory
    sta $4014          ;
    rti

palletedata:
    .byte $22, $29, $1A, $0F, $22, $36, $17, $0f, $22, $30, $21, $0f, $22, $27, $17, $0F ; background
    .byte $22, $16, $27, $1B, $22, $1A, $30, $27, $22, $16, $30, $27, $22, $0F, $36, $17 ; sprite
spritedata:
    .byte $08, $00, $00, $08
    .byte $08, $01, $00, $10
    .byte $10, $02, $00, $08
    .byte $10, $03, $00, $10
    .byte $18, $04, $00, $08
    .byte $18, $05, $00, $10
    .byte $20, $06, $00, $08
    .byte $20, $07, $00, $10
       
; CHR rom segment
.segment "CHARS"
.incbin  "hellomario.chr"
