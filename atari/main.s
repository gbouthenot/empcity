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

                bsr     testfill1

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



testfill1:      lea     $3f8000,a6
                lea     tilemap,a5
                lea     tiles,a4

                moveq   #20-1,d6            ; show 20 blocks (320 pixels wide)
.copytile:      moveq   #0,d7
                move.b  (a5),d7             ; d7: tile number TODO: this should be .w
                lea     31(a5),a5           ; a5: next tile horizontaly
                lsl.w   #7,d7
                lea     (a4,d7),a3          ; a3: adr of tile

                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)
                lea     160(a6),a6        ; next row
                move.w  (a3)+,6(a6)
                move.w  (a3)+,4(a6)
                move.w  (a3)+,2(a6)
                move.w  (a3)+,(a6)

                lea     -15*160-8(a6),a6
                dbra    d6,.copytile
                rts


                SECTION DATA
palette:        incbin  palette.bin
tiles:          incbin  tiles.bin
tilemap:        incbin  tilemap.bin

                SECTION BSS
userstack:      ds.l    1
oldpal:         ds.w    16
