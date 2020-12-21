                mc68000
LINEBYTES       EQU     168
NBLOCKW         EQU     17                               ; nb horizontal blocks 17 / 6 for measure
NBLOCKH         EQU     12                               ; nb vertical blocks. 12 is hardcoded in display
DEBUG           EQU     0
SCENWIDTH       EQU     1936
SCENHEIGHT      EQU     496


;            video base adr:
; $ff8201    0 0 X X X X X X   High Byte      yes    yes
; $ff8203    X X X X X X X X   Mid Byte       yes    yes
; $ff820d    X X X X X X X 0   Low Byte       no     yes    Write AFTER high/mid
; $ff820f    X X X X X X X X                  no     yes    Line-Offset Register
; $ff8265    0 0 0 0 X X X X                                Pixel shift
;           video base counter
; $ff8205    0 0 X X X X X X   High Byte      ro     rw
; $ff8207    X X X X X X X X   Mid Byte       ro     rw
; $ff8209    X X X X X X X 0   Low Byte       ro     rw



main:           bsr preTilemap

SYSINIT:
                clr.l   -(sp)       ;SUP_SET
                move.w  #$20,-(sp)  ;Super()
                trap    #1
                addq.l  #6,sp
                move.l  d0,userstack

                lea     $ff8240,a6
                lea     oldpal,a5
                lea     palette,a4
                moveq   #16-1,d0
.savpal:        move.w  (a6),(a5)+
                move.w  (a4)+,(a6)+
                dbra    d0,.savpal
                move.w  #$0fff,$ffff8242.w              ; color 1 is white
                move.w  (a6),(a5)+                      ; save resolution
                movep.w $ff8201-$ff8260(a6),d0
                move.w  d0,(a5)+                        ; save old screen adr
                move.l  $fffffa06.w,d0
                move.l  d0,(a5)+                        ; save old iera ierbb
                move.l  $68.w,(a5)+                     ; save $68
                move.l  $70.w,(a5)+                     ; save $70

                clr.w   (a6)                            ; set low resolution
                move.b  #4,$ffff820f.w                  ; line width = 168 bytes

                ; init switch data
                IF DEBUG==0
                lea     screen1,a0
                lea     screen2,a1
                ELSE
                lea     $3f8000,a0
                move.l  a0,a1
                ENDIF
                lea     switchdata,a2
                move.l  a0,(a2)+                        ; set current screen adr
                clr.w   (a2)+                           ; next not ready
                move.l  a1,(a2)+                        ; next adr
                clr.l   (a2)+                           ; next line width offset, pixel shift, missed switch

                IF      DEBUG==0
                clr.l   $fffffa06.w
                lea     new70(pc),a0
                move.l  a0,$70.w
                lea     new68(pc),a0
                move.l  a0,$68.w
                ENDIF

; MAIN LOOP
mainloopInit:   lea     statusdata,a0
                ; init
                clr.l   (a0)+
                clr.l   (a0)+
                clr.l   (a0)+
                clr.l   (a0)+

                move.l  $4ba.w,d1                       ; measure start
mainloop:
                lea     statusdata,a0

.keyloop:       move.b  #1,d2                           ; d2: default 1 for key pressed, 0 if key is depressed
                btst    #7,$fffffc00.w
                beq.s   .endkey
.readkey:       move.b  $fffffc02.w,d0
                move.b  d0,d1
                and.b   #$7f,d1                         ; d1: key code without pressed/depressed
                cmp.b   #$39+$80,d0                     ; space depressed ?
                beq     mainloopexit
                lea     $8(a0),a1                       ; up
                cmp.b   #$48,d1
                beq.s   .arrowkey
                lea     $a(a0),a1                       ; bottom
                cmp.b   #$50,d1
                beq.s   .arrowkey
                lea     $c(a0),a1                       ; left
                cmp.b   #$4b,d1
                beq.s   .arrowkey
                lea     $e(a0),a1                       ; right
                cmp.b   #$4d,d1
                beq.s   .arrowkey
                bra.s   .keyloop

.arrowkey:
                cmp.b   d0,d1
                beq.s   .keyupdown
                moveq   #0,d2                           ; key is up
.keyupdown:     move.w  d2,(a1)
                bra.s   .keyloop

.endkey:
applydirection:
; apply top / bottom / left / right directions
;a0: statusdata
                ; handle left / right
                move.w  (a0),d7                         ; d7: viewpointTL_x
                move.w  4(a0),d6                        ; d6: pointerTL_x
                move.w  $c(a0),d5                       ; d5: left
                move.w  $e(a0),d4                       ; d4: right
                add.w   d4,d4                           ; d4: right double speed
                add.w   d5,d5                           ; d5: left double speed
                ; viewpointTL_x
                sub.w   d5,d7
                add.w   d4,d7
                bge.s   .vpxposi
                add.w   #SCENWIDTH,d7
.vpxposi:       cmp.w   #SCENWIDTH,d7
                blt.s   .vpxok
                sub.w   #SCENWIDTH,d7
.vpxok:         ; pointerTL_x
                sub.w   d5,d6
                sub.w   d5,d6
                add.w   d4,d6
                add.w   d4,d6
                bge.s   .pxposi
                clr.w   d6
.pxposi:        cmp.w   #(NBLOCKW-1)*16-32+4,d6
                ble.s   .pxok
                move.w  #(NBLOCKW-1)*16-32+4,d6
.pxok:          move.w  d7,(a0)
                move.w  d6,4(a0)

                ; handle top / bottom
                move.w  2(a0),d7                        ; d7: viewpointTL_y
                move.w  6(a0),d6                        ; d6: pointerTL_y
                move.w  $8(a0),d5                       ; d5: top
                move.w  $a(a0),d4                       ; d4: bottom
                add.w   d4,d4                           ; d4: bottom double speed
                add.w   d5,d5                           ; d5: top double speed
                ; viewpointTL_y
                sub.w   d5,d7
                add.w   d4,d7
                ;bge.s   .vpyposi
                ;add.w   #SCENWIDTH,d7
.vpyposi:       ;cmp.w   #SCENWIDTH,d7
                ;blt.s   .vpyok
                ;sub.w   #SCENWIDTH,d7
.vpyok:         ; pointerTL_y
                sub.w   d5,d6
                sub.w   d5,d6
                add.w   d4,d6
                add.w   d4,d6
                bge.s   .pyposi
                clr.w   d6
.pyposi:        cmp.w   #(NBLOCKH)*16-32,d6
                ble.s   .pyok
                move.w  #(NBLOCKH)*16-32,d6
.pyok:          move.w  d7,2(a0)
                move.w  d6,6(a0)
                
.waitscreen:    IF      DEBUG==0
                tst.b   switchdata+5
                bne.s   .waitscreen                     ; wait until screen is NOT ready
                ENDIF

                bsr     drawscreen
                st      switchdata+5                    ; screen is ready to switch !

                ;end of mainloop
                bra   mainloop

mainloopexit:
                move.l  $4ba.w,d2                        ; measure: end
                sub.l   d1,d2

;**********
SYSRESTORE:
                lea     $ffff8240.w,a6
                lea     oldpal,a5
                moveq   #17-1,d0
.restpal:       move.w  (a5)+,(a6)+                     ; palette and res
                dbra    d0,.restpal
                clr.b   $ffff8265.w                     ; no pixel shift
                clr.b   $ffff820f.w                     ; line width standard
                clr.b   $ffff820d.w                     ; no low byte
                move.w  (a5)+,d0
                movep.w d0,$ff8201-$ff8262(a6)          ; video base address
                move.l  (a5)+,$fffffa06.w               ; iera ierbb
                move.l  (a5)+,$68.w
                move.l  (a5)+,$70.w

                ;return to user mode
                move.l  userstack,-(sp)
                move.w  #$20,-(sp)
                trap    #1
                addq.l  #6,sp

                clr.w   -(sp)
                trap    #1

new70:          movem.l a0-a1/d0,-(sp)
                move.w  #$000,$ffff8240.w
                lea     switchdata+5,a0
                tst.b   (a0)
                bne.s   .ready
                ; not ready
                addq.w  #1,$c-5(a0)
                move.w  #$f00,$ffff8240.w
                bra.s   .end70
.ready:         sf      (a0)+                           ; set not ready
                move.w  (a0)+,d0
                lea     $ffff8200.w,a1
                move.b  d0,$1(a1)                       ; set high base
                move.b  d0,$5(a1)                       ; set high counter
                move.b  (a0),$3(a1)                     ; set mid base
                move.b  (a0)+,$7(a1)                    ; set mid counter
                move.b  (a0),$d(a1)                     ; set low base (last)
                move.b  (a0)+,$9(a1)                    ; set low counter (last)
                move.b  (a0)+,$f(a1)                    ; set line offset
                move.b  (a0),$65(a1)                    ; set pixel shift

                move.l  0-11(a0),d0                     ; swap screen adrs
                move.l  6-11(a0),0-11(a0)
                move.l  d0,6-11(a0)
.end70:         movem.l  (sp)+,a0-a1/d0
new68:          rte


;********** DRAWSCREEN *******
drawscreen:     movem.l a0-a6/d0-d7,-(sp)

                move.w  statusdata+$0,d7                ; viewpointTL_x
                move.w  d7,d6
                lsr.w   #4,d6
                mulu    #31,d6
                add.l   d6,d6
                add.l   d6,d6
                lea     tilemapPre,a5
                adda.l  d6,a5                           ; a5: tilemap

                and.w   #$f,d7
                move.w  d7,-(sp)                        ; stack pixelshift
                move.w  d7,d6
                bne.s   .bothdec                        ; d6=xxyy: xx:nextLineOffset=0, yy: pixelshift
.zerodec:       IF      DEBUG==0
                move.w  #$400,d6
                ELSE
                move.b  #4,$ffff820f.w
                clr.b   $ffff8265.w
                bra.s   .enddec
                ENDIF
.bothdec:       IF      DEBUG==0
                move.w  d6,switchdata+$a                ; set nextlineoffset=0, next pixelshify=t
                ELSE
                clr.b   $ffff820f.w
                move.b  d6,$ffff8265.w
                ENDIF
.enddec:

;d7: nb pixel shift
;a5: current tilemap
;(sp).w: nb pixel shift

                ; blit init
                move.l  switchdata+$6,a6                ; a6: screen address
                lea     endmasks(pc),a4
                add.w   d7,d7
                move.w  0(a4,d7.w),d7                   ; d7.w: mask for last column
                lea     tiles,a4
                lea     $ff8a00,a0                      ; a0: Blitter

;d7: mask for last column
;a0: blitter base
;a4: tiles
;a5: current tilemap
;(sp).w: nb pixel shift

                ; fill blitter halftone with last column mask
                move.w  d7,d6
                swap  d6
                move.w  d7,d6
                move.l  d6,(a0)+
                move.l  d6,(a0)+
                move.l  d6,(a0)+
                move.l  d6,(a0)+
                move.l  d6,(a0)+
                move.l  d6,(a0)+
                move.l  d6,(a0)+
                move.l  d6,(a0)+
                ;d6/d7: free

                move.l  #$20002,(a0)                    ; src x / y incr
                lea     -$20(a0),a0                     ; a0; blitter base
                move.l  #(2<<16)+LINEBYTES-6,$2e(a0)    ; dest x / y incr
                moveq   #-1,d7
                move.l  d7,$28(a0)                      ; endmask 1 / 2
                move.w  d7,$2c(a0)                      ; endmask 3
                move.w  #4,$36(a0)                      ; xCount=4 : copy 4 words = 4 bitplanes
                move.l  #($203<<16)+0,$3a(a0)           ; hop: source / op = source / (busy/hog/smudge/0/linenumber)/ (fxsr/nfsr/0/0/skew)

                moveq   #NBLOCKW-1,d7                   ; number of columns. -1 cause last will me masked
                lea     $24(a0),a1
                lea     $38(a0),a2
                lea     $3c(a0),a3
                moveq   #16,d0                          ; yCount=16 1 block is 16 line
                moveq   #-$40,d1                        ; $c0: BUSY / HOG / smudge
.nxtcol:        move.w  d7,-(sp)

;d0: $10 (used for yCount)
;d1: $80 (used for BUSY)
;d2,d3,d4,d5,d6,d7: / (used for tiles)
;a0: blitter base
;a1: $ff8a24: source addr
;a2: $ff8a38: yCount
;a3: $dd8a3c: BUSY/hop/smudge/0/linenumber
;a5: current tilemap
;a6: screen (dest)
;(sp).w: number of columns left to do
;2(sp).w: nb pixel shift


                move.l  a6,$32(a0)                      ; dest adr

                REPT    2
                movem.l (a5)+,d2-d7
                move.l  d2,(a1)                         ; row 0
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d3,(a1)                         ; row 1
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d4,(a1)                         ; row 2
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d5,(a1)                         ; row 3
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d6,(a1)                         ; row 4
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d7,(a1)                         ; row 5
                move.w  d0,(a2)
                move.b  d1,(a3)
                ENDR

                lea     (-12+31)*4(a5),a5               ; tilemap: return to beginning of column and move right 1 tile
                addq.l  #8,a6                           ; next column
                move.w  (sp)+,d7
                subq.w  #1,d7
                bne.s   .nxtcol

                ; last column : apply right mask !
                move.l  a6,$32(a0)                      ; dest adr
                move.b  #3,$3a(a0)                      ; hop: source&halftone

                REPT    2
                movem.l (a5)+,d2-d7
                move.l  d2,(a1)                         ; row 0
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d3,(a1)                         ; row 1
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d4,(a1)                         ; row 2
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d5,(a1)                         ; row 3
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d6,(a1)                         ; row 4
                move.w  d0,(a2)
                move.b  d1,(a3)
                move.l  d7,(a1)                         ; row 5
                move.w  d0,(a2)
                move.b  d1,(a3)
                ENDR

; show pointer

;a0: blitter base
;a2: $ff8a38: yCount
;a3: $ff8a3c: BUSY/hop/smudge/0/linenumber
;(sp).w: nb pixel shift
                moveq   #2,d0                           ; d0=xCount=2 : copy 2 words
                move.l  #(8<<16)+LINEBYTES-8,d3         ; d3: dest x / y incr
                move.w  #$204,d2
                swap    d2
                move.w  statusdata+4,d2                 ; d2.w pointerTL_x
                add.w   (sp)+,d2                        ; d2.w: add pixelshift for viewpoint
                move.w  d2,d4                           ; d4: pointer x absolute
.nobump         and.w   #$f,d2                          ; d2: hop: source / op = NOT source AND target / (busy/hog/smudge/0/linenumber)/ (fxsr/nfsr/0/0/skew)
                beq.s   .noskew
;if skew>0:
; - xcount + 1
; - set $40 (NFSR)
; - dest y incr - 8
; - set endmask 3 ?
                add.b   #$40,d2
                addq.w  #1,d0
                subq.w  #8,d3

.noskew:        move.l  switchdata+6,a6                 ; a6: screen adress
;d4: pointer x absolute
                move.w  d4,d5
                and.w   #$fff0,d5
                lsr.w   #1,d5
                lea     0(a6,d5.w),a6                   ; a6: screen address for pointer
                
                move.w  statusdata+6,d5                 ; pointerTL_y
                mulu    #LINEBYTES,d5
                lea     0(a6,d5.w),a6                   ; a6: screen address for pointer
                
                
                lea     pointerData,a5
                ;move.l  #$20002,$20(a0)                ; src x / y incr (already set)

                move.w  d0,$36(a0)                      ; xCount
                move.l  d3,$2e(a0)                      ; dest x / y incr
                move.l  d2,$3a(a0)                      ; hop: source / op / (busy/hog/smudge/0/linenumber)/ (fxsr/nfsr/0/0/skew)
                moveq   #32,d0                          ; for yCount



; a5: pointerdata*
; a6: screen*
; a3: BUSY
; a2: yCount
; a0: blitbase
; d0: yCount
; d1: BUSY
                ; mask pixels in black
                REPT 3
                move.l  a5,$24(a0)                      ; set src adr
                move.l  a6,$32(a0)                      ; dest adr
                move.w  d0,(a2)                         ; yCount
                move.b  d1,(a3)                         ; BUSY/hog/smudge/0/lineumber
                addq.l  #2,a6                           ; next bitplane
                ENDR
                move.l  a5,$24(a0)                      ; last bitplane
                move.l  a6,$32(a0)
                move.w  d0,(a2)
                move.b  d1,(a3)
                subq.l  #6,a6

                ; white pixels : only one bitplane !
                lea   128(a5),a5
                move.b  #7,$3b(a0)                      ; op = source OR target
                ;move.l  a5,$24(a0)                     ; bitplane 0 ; set src adr -first not needed)
                move.l  a6,$32(a0)                      ; dest adr
                move.w  d0,(a2)                         ; yCount
                move.b  d1,(a3)                         ; BUSY/hog/smudge/0/linumber

                movem.l (sp)+,a0-a6/d0-d7
                move.w  #$00f,$ffff8240.w
                sf      switchdata+5
                rts






preTilemap:     lea     tilemap,a0
                lea     tilemapPre,a1
                lea     tiles(pc),a2
                move.w  #(tilemap_end-tilemap)/2-1,d1
.loop           moveq   #0,d0
                move.w  (a0)+,d0        // max 512
                lsl.w   #7,d0
                add.l   a2,d0
                move.l  d0,(a1)+
                dbra    d1,.loop
                rts


                SECTION DATA
endmasks:       dc.w  $0000, $8000, $c000, $e000
                dc.w  $f000, $f800, $fc00, $fe00
                dc.w  $ff00, $ff80, $ffc0, $ffe0
                dc.w  $fff0, $fff8, $fffc, $fffe
palette:        incbin  rsc/palette.bin
tiles:          incbin  rsc/tiles.bin
tilemap:        incbin  rsc/tilemap.bin
tilemap_end:    *
pointerData:
.mask:          dc.l $001f0000, $00efe000, $03767800, $05860c00, $0a0e0200, $14070100, $28060080, $300e00c0, $50070040, $60060060, $60060060, $a01f0020, $c02f8030, $c0504030, $d2606930, $ffe47ff0, $ffe27ff0, $c96064b0, $c020a030, $c01f4030, $400f8050, $60060060, $60060060, $200e00a0, $300700c0, $10060140, $080e0280, $04070500, $03061a00, $01e6ec00, $007f7000, $000f8000
.white:         dc.l $001f0000, $00e4e000, $03041800, $04040400, $080e0200, $10040100, $20040080, $200e0080, $40040040, $40040040, $40040040, $801f0020, $80208020, $80404020, $92404920, $ffc47fe0, $92404920, $80404020, $80208020, $801f0020, $40040040, $40040040, $40040040, $200e0080, $20040080, $10040100, $080e0200, $04040400, $03041800, $00e4e000, $001f0000, $00000000

                SECTION BSS
userstack:      ds.l    1
oldpal:         ds.w    16
                ds.w    1                       ; res
                ds.w    1                       ; video adr bytes 2 & 3
                ds.l    1                       ; mfp iera ierb
                ds.l    1                       ; old $68
                ds.l    1                       ; old $70

switchdata:     ds.l    1                       ; $0 current displayed screen
                ds.b    1                       ; $4 0
                ds.b    1                       ; $5 next screen ready ? 0=no
                ds.l    1                       ; $6 next screen buffer
                ds.b    1                       ; $a next line width offset
                ds.b    1                       ; $b next pixel shift
                ds.w    1                       ; $c number of missed switches

statusdata:     ds.w    1                       ; $0 viewpointTL_x (0 -> SCENWIDTH-1)
                ds.w    1                       ; $2 viewpointTL_y (0 -> 496-SCHENHEIGHT)
                ds.w    1                       ; $4 pointerTL_x (0 -> NBLOCKW*16 - 31)
                ds.w    1                       ; $6 pointerTL_y (0 -> NBLOCKH*16 - 31)
                ds.w    1                       ; $8 key up if !=0
                ds.w    1                       ; $a key down
                ds.w    1                       ; $c key left
                ds.w    1                       ; $e key right

tilemapPre:     ds.b    (tilemap_end-tilemap)*2

screen1:        ds.b    200*336/2
screen2:        ds.b    192*336/2
