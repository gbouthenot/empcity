                mc68000
LINEBYTES       EQU     168
NBLOCKX         EQU     17                              ; nb horizontal blocks 17
DEBUG           EQU     0


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
                move.l  $4ba.w,d1                       ; measure start
                moveq   #0,d7                           ; d7: x coord (0-1616)
mainloop:
                btst    #7,$fffffc00.w
                beq.s   .waitscreen
.readkey:       cmp.b   #$39,$fffffc02.w
                beq.s   mainloopexit
                btst    #7,$fffffc00.w
                bne.s   .readkey

.waitscreen:    IF      DEBUG==0
                tst.b   switchdata+5
                bne.s   .waitscreen                     ; wait until screen is NOT ready
                ENDIF

                bsr     drawscreen
                st      switchdata+5                    ; screen is ready to switch !

                ;end of mainloop
                addq.w  #1,d7
                cmp.w   #1616,d7
                ble.s   mainloop

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
; d7: x coord
drawscreen:     movem.l a0-a6/d0-d7,-(sp)

                move.w  d7,d6
                lsr.w   #4,d6
                mulu    #31,d6
                add.l   d6,d6
                add.l   d6,d6
                lea     tilemapPre,a5
                adda.l  d6,a5                           ; a5: tilemap

                lea     switchdata,a2
                and.w   #$f,d7
                move.w  d7,d6
                bne.s   .bothdec                        ; d6=xxyy: xx:offset(0), yy: pixelshift
.zerodec:       IF      DEBUG==0
                move.w  #$400,d6
                ELSE
                move.b  #4,$ffff820f.w
                clr.b   $ffff8265.w
                bra.s   .enddec
                ENDIF
.bothdec:       IF      DEBUG==0
                move.w  d6,$a(a2)                       ; set nextlineoffset=0, next pixelshify=t
                ELSE
                clr.b   $ffff820f.w
                move.b  d6,$ffff8265.w
                ENDIF
.enddec:

                move.l  6(a2),a6                        ; a6: screen adress
                lea     endmasks(pc),a4
                add.w   d7,d7
                move.w  0(a4,d7.w),d7                   ; get mask for last column
                lea     tiles,a4

                ; blit init
                lea     $ff8a00,a0                      ; a0: Blitter
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
                move.l  #$20002,(a0)                    ; src x / y incr
                lea     -$20(a0),a0
                move.l  #(2<<16)+LINEBYTES-6,$2e(a0)    ; dest x / y incr
                moveq   #-1,d7
                move.l  d7,$28(a0)                      ; endmask 1 / 2
                move.w  d7,$2c(a0)                      ; endmask 3
                move.w  #4,$36(a0)                      ; xCount=4 : copy 4 words = 4 bitplanes
                move.l  #($203<<16)+0,$3a(a0)           ; hop: source / op = source / (linenumber, smudge,hog)/ (skew / nfsr / fxsr)

                moveq   #NBLOCKX-1,d7                   ; number of columns. Last one will me masked
                lea     $24(a0),a1
                lea     $38(a0),a2
                lea     $3c(a0),a3
                moveq   #16,d0                          ; yCount=16 1 block is 16 line
                moveq   #-$40,d1                        ; $c0: BUSY / HOG / smudge
.nxtcol:        move.w  d7,-(sp)

;a5: tilemap (current)
;a6: screen (dest)
;a0: blitter base

                move.l  a6,$32(a0)                      ; dest adr

                REPT    2
                movem.l (a5)+,d2-d7
                ;REPT    12
                ;move.l  (a5)+,(a1)                     ; set source address / a5: next tile vertically
                ;move.w  d0,(a2)                        ; yCount=16
                ;move.b  d1,(a3)                        ; BUSY / HOG / smudge
                ;ENDR
                move.l  d2,(a1)
                move.w  d0,(a2)
                move.b  d1,(a3)

                move.l  d3,(a1)
                move.w  d0,(a2)
                move.b  d1,(a3)

                move.l  d4,(a1)
                move.w  d0,(a2)
                move.b  d1,(a3)

                move.l  d5,(a1)
                move.w  d0,(a2)
                move.b  d1,(a3)

                move.l  d6,(a1)
                move.w  d0,(a2)
                move.b  d1,(a3)

                move.l  d7,(a1)
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

                lea     (-12+31)*4(a5),a5               ; tilemap: return to beginning of column and move right 1 tile
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


tilemapPre:     ds.b    (tilemap_end-tilemap)*2

screen1:        ds.b    200*336/2
screen2:        ds.b    192*336/2
