                mc68000

main:

                clr.l   -(sp)       ;SUP_SET
                move.w  #$20,-(sp)  ;Super()
                trap    #1
                addq.l  #6,sp
                move.l  d0,userstack

                ;save palette + res + set new palette + low rest
                lea     $ff8240,a6
                lea     oldpal,a5
                lea     palette,a4
                moveq   #16-1,d0
.savpal:        move.w  (a6),(a5)+
                move.w  (a4)+,(a6)+
                dbra    d0,.savpal
                move.w  (a6),(a5)+          ; save resolution
                clr.w   (a6)                ; set low resolution

measure:        move.l  $4ba.w,d1
                moveq   #99,d0
.d1:            bsr     drawscreen
                dbf     d0,.d1
                move.l  $4ba.w,d2
                sub.l   d1,d2


                move.w  #7,-(sp)
                trap    #1
                addq.l  #2,sp

                ; restore palette
                lea     $ff8240,a6
                lea     oldpal,a5
                moveq   #17-1,d0
.restpal:       move.w  (a5)+,(a6)+
                dbra    d0,.restpal

                ;return to user mode
                move.l  userstack,-(sp)    ;stack
                move.w  #$20,-(sp)  ;Super()
                trap    #1
                addq.l  #6,sp

                clr.w   -(sp)
                trap    #1



drawscreen:     movem.l a0-a6/d0-d7,-(sp)
                lea     $3f8000,a6
                lea     tilemap+99,a5
                lea     tiles,a4

                ; blit init
                lea     $ff8a00,a0          ; a0: Blitter
                move.w  #2,$20(a0)          ; source x incr
                move.w  #2,$22(a0)          ; source y incr
                move.w  #2,$2e(a0)          ; dest x incr
                move.w  #160-6,$30(a0)      ; dest y incr
                moveq   #-1,d7
                move.w  d7,$28(a0)          ; endmask 1
                move.w  d7,$2a(a0)          ; endmask 2
                move.w  d7,$2c(a0)          ; endmask 3
                move.w  #4,$36(a0)          ; xCount=4
                move.b  #0,$3d(a0)          ; skew / nfsr / fxsr
                move.b  #3,$3b(a0)          ; op = source
                move.b  #2,$3a(a0)          ; hop: source



                suba.w  d0,a5
                moveq   #12,d7              ; 12 rows (192 pixels height)
.nxtrow:        move.w  d7,-(sp)
                moveq   #20,d7               ; show 20*1=20 blocks (320 pixels wide)
.nxtline:       move.w  d7,-(sp)

                moveq   #0,d7
                move.b  (a5)+,d7            ; d7: tile number TODO: this should be .w / a5: next tile horizontaly
                lsl.w   #7,d7
                lea     (a4,d7.w),a3        ; a3: adr of tile ; TODO adda ?

;a3: source tile
;a4: tiles (fixed)
;a5: tilemap (current)
;a6: screen (dest)

                move.l  a3,$24(a0)          ; source adr
                move.l  a6,$32(a0)          ; dest adr
                move.w  #16,$38(a0)         ; yCount=16
                move.b  #$c0,$3c(a0)        ; BUSY / HOG / smudge

                addq.l  #8,a6

                move.w  (sp)+,d7
                subq.w  #1,d7
                bne     .nxtline

                lea     -20+121(a5),a5              ; tilemap: return to beginning of row and move down 1 tile
                lea     15*160(a6),a6               ; screen: one block down
                move.w  (sp)+,d7
                subq.w  #1,d7
                bne     .nxtrow

                movem.l (sp)+,a0-a6/d0-d7
                rts


                SECTION DATA
palette:        incbin  rsc/palette.bin
tiles:          incbin  rsc/tiles.bin
tilemap:        incbin  rsc/tilemap.bin

                SECTION BSS
userstack:      ds.l    1
oldpal:         ds.w    16
