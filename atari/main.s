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
                lea     tilemap,a5
                moveq   #12,d7              ; 12 rows (192 pixels height)
.nxtrow:        move.w  d7,-(sp)
                moveq   #20,d7              ; show 20 blocks (320 pixels wide)
.nxtline:       move.w  d7,-(sp)
                moveq   #0,d7
                move.b  (a5),d7             ; d7: tile number TODO: this should be .w
                lea     31(a5),a5           ; a5: next tile horizontaly
                lsl.w   #7,d7
                lea     tiles,a3
                lea     (a3,d7.w),a3        ; a3: adr of tile ; TODO adda ?

;a3: tile (source)
;a5: current tilemap
;a6: screen (dest)

                movem.l (a3)+,d0-d7/a0-a2/a4
                move.l  d0,(a6)+
                move.l  d1,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d2,(a6)+
                move.l  d3,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d4,(a6)+
                move.l  d5,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d6,(a6)+
                move.l  d7,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  a0,(a6)+
                move.l  a1,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  a2,(a6)+
                move.l  a4,(a6)
                lea     160-4(a6),a6        ; next row
                movem.l (a3)+,d0-d7/a0-a2/a4
                move.l  d0,(a6)+
                move.l  d1,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d2,(a6)+
                move.l  d3,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d4,(a6)+
                move.l  d5,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d6,(a6)+
                move.l  d7,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  a0,(a6)+
                move.l  a1,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  a2,(a6)+
                move.l  a4,(a6)
                lea     160-4(a6),a6        ; next row
                movem.l (a3)+,d0-d7
                move.l  d0,(a6)+
                move.l  d1,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d2,(a6)+
                move.l  d3,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d4,(a6)+
                move.l  d5,(a6)
                lea     160-4(a6),a6        ; next row
                move.l  d6,(a6)+
                move.l  d7,(a6)

                lea     -15*160+4(a6),a6    ; return to top of tile, but next horizontal tile
                move.w  (sp)+,d7
                subq.w  #1,d7
                bne     .nxtline

                lea     -20*31+1(a5),a5             ; tilemap: return to beginning of row and move down 1 tile
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
