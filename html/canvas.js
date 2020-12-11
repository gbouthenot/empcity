/* eslint-env browser */
class Tilemap {
  constructor () {
    this.el = {}
    this.imageData = null
    this.imageWidth = null
    this.imageHeight = null
    this.imageCtx = null
    this.pixel = null
    this.palette = [] // [ {color:3159149, hex:'"30346d', usage: 234}, ... ]
    this.tilesgfx = [] // [ {img: ImageData, hex: "3315...",usage: 133} ]
    this.tilemap = [] // [ tile index in tilesgfx, ... ]
    this.tilelistWidth = 64

    this.el.canvas = document.getElementById('canvas')
    this.el.palette = document.getElementById('palette')
    this.el.tiles = document.getElementById('tiles')
    this.el.tilesCanvas = document.querySelectorAll('#tilemap .prevnext canvas')
    this.el.tilesUsage = document.querySelectorAll('#tilemap .prevnext .usage')
    // le premier tile canvas est zoomé sans smoothing pour voir les pixels
    // le deuxième: pas besoin, il est recopié
    const ctx = this.el.tilesCanvas[0].getContext('2d')
    ctx.scale(2, 2)
    ctx.imageSmoothingEnabled = false

    // install handlers
    this.el.tiles.addEventListener('click', this.clickOnTiles.bind(this))
    this.el.canvas.addEventListener('click', this.clickOnImage.bind(this))
  }

  /**
   * HANDLER: click on the main image
   * select tile in tile map + show usage
   * show where this tile is used in the image
   */
  clickOnImage (e) {
    const clickedTile = (e.offsetX >> 4) + (e.offsetY >> 4) * (this.imageWidth + 1 >> 4)
    const tilenb = this.tilemap[clickedTile]
    // show where it is used is the main image
    this.selectTile(tilenb)
  }

  /**
   * HANDLER: click on the tiles list
   * select tile in tile map + show usage
   * show where this tile is used in the image
   */
  clickOnTiles (e) {
    let [x, y] = [e.offsetX, e.offsetY]
    x = Math.floor((x - 1) / 17)
    y = Math.floor((y - 1) / 17)
    const tilenb = y * this.tilelistWidth + x
    // check if the tile exists
    if (this.tilesgfx[tilenb]) {
      this.selectTile(tilenb)
    }
  }

  /**
   * highlight the tile in the tiles list
   * show where this tile is used in the image
   * show a zoomed version of the tile, with the usage count
   */
  selectTile (tilenb) {
    this.showTileUsage(tilenb)
    this.showZoomedTile(tilenb)
    this.showTiles(tilenb)
  }

  /**
   * fetch the <img> from the DOM
   * convert it to a new canvas
   * remove the original <img>
   */
  convertImgToCanvas () {
    // use naturalWidth because when zoom factor = 90% chrome return width and height reduced by 1
    const myImgElement = document.getElementById('sourceImg')
    this.el.canvas.width = myImgElement.naturalWidth
    this.el.canvas.height = myImgElement.naturalHeight
    const context = this.el.canvas.getContext('2d')
    // context.scale(myCanvasElement.width / myImgElement.width, myCanvasElement.height / myImgElement.height);
    context.drawImage(myImgElement, 0, 0)
    myImgElement.remove()

    this.imageWidth = myImgElement.width
    this.imageHeight = myImgElement.height
    this.imageCtx = context
    this.imageData = context.getImageData(0, 0, this.imageWidth, this.imageHeight)

    // only do this once per page
    // then this.imageCtx.putImageData( pixel, x, y );
    // this.pixel = this.imageCtx.createImageData(1, 1)
    // this.pixel.data[3] = 255
  }

  /**
   * Show the palette on the DOM
   */
  showPalette () {
    const div = this.el.palette
    this.palette.forEach((x, y) => {
      const txt = `<div class="palcol">${y}: ${x.usage}<br /><span class="tile" style="background-color: #${x.hex};"></span>#${x.hex}</div>`
      div.innerHTML += txt
    })
  }

  /**
   * Show tiles list with a magenta background
   * If highlight, the tile is framed with a green box
   * all 16x16 tiles are displayed inside a frame
   */
  showTiles (highlight = null) {
    const canvas = this.el.tiles
    const ctx = canvas.getContext('2d')
    const tilesPerRow = this.tilelistWidth
    const nbrows = Math.ceil(this.tilesgfx.length / tilesPerRow)
    canvas.width = tilesPerRow * 17 + 2
    canvas.height = nbrows * 17 + 2
    ctx.fillStyle = '#ff00ff' // magenta
    ctx.fillRect(0, 0, canvas.width - 1, canvas.height - 1)

    let curX = 0
    let curY = 0
    this.tilesgfx.forEach((x, idx) => {
      // ctx.fillRect(curX << 3, curY << 3, 16, 16)
      ctx.putImageData(x.img, curX * 17 + 1, curY * 17 + 1)
      curX++
      if (curX === tilesPerRow) {
        curX = 0
        curY++
      }
    })

    if (highlight !== null) {
      const y = Math.floor(highlight / tilesPerRow)
      const x = highlight - y * tilesPerRow
      ctx.strokeStyle = '#00ff00' // green
      ctx.lineWidth = 1
      ctx.strokeRect(x * 17 + 0.5, y * 17 + 0.5, 17, 17)
    }
  }

  /**
   * Display a zoomed version of the tile, with the usage number as "curr"
   * Also keep the previously shown tile as "prev"
   */
  showZoomedTile (tilenb) {
    const tilegfx = this.tilesgfx[tilenb]

    // copie curr -> prev
    this.el.tilesUsage[1].innerText = this.el.tilesUsage[0].innerText
    this.el.tilesCanvas[1].getContext('2d').drawImage(this.el.tilesCanvas[0], 0, 0)

    // copie le tile dans un canvas temporaire
    // draw ce canvas temp sur le canvas affiché et zoomé
    var tmpcanvas = document.createElement('canvas')
    tmpcanvas.width = 16
    tmpcanvas.height = 16
    tmpcanvas.getContext('2d').putImageData(tilegfx.img, 0, 0)
    let ctx = this.el.tilesCanvas[0].getContext('2d')
    ctx.drawImage(tmpcanvas, 0, 0)
    this.el.tilesUsage[0].innerText = ` ${tilegfx.usage} times`
  }

  /**
   * show where the tile is used in the image by painting black
   */
  showTileUsage (tileToShow) {
    this.imageCtx.fillStyle = '#000000'
    this.imageCtx.putImageData(this.imageData, 0, 0)
    const widthTile = this.imageWidth / 16
    for (let tilenb = 0; tilenb < this.tilemap.length; tilenb++) {
      const currentTile = this.tilemap[tilenb]
      if (currentTile === tileToShow) {
        const y = parseInt(tilenb / widthTile)
        const x = tilenb - y * widthTile
        // paint it black
        this.imageCtx.fillRect(x * 16, y * 16, 16, 16)
      }
    }
  }

  /**
   * Build tilesgfx, tilemap
   * walk over all 16x16 blocks in image (a tile)
   * if this tile is not yet present in the tiles list, add it
   * Add tile index in the the tilemap
   */
  buildTilemap () {
    const tilesgfx = this.tilesgfx
    const tilemap = this.tilemap

    for (let y = 0, tileIdx = 0; y < this.imageHeight >> 4; y++) {
      for (let x = 0; x < this.imageWidth >> 4; x++) {
        const curTile = this.extractTile(x, y, this.palette)
        const tileNb = tilesgfx.findIndex(a => a.hex === curTile.hex)
        if (tileNb === -1) {
          curTile.usage = 1
          tilesgfx.push(curTile)
          tilemap.push(tileIdx++)
        } else {
          tilemap.push(tileNb)
          tilesgfx[tileNb].usage++
        }
      }
    }
  }

  /**
   * read a 16x16 block in the image
   * returns it as image data and palette-indexed hex string
   * used by buildTilemap
   */
  extractTile (x, y, palette) {
    const tileimg = this.imageCtx.getImageData(x << 4, y << 4, 16, 16)
    let tilehex = ''

    for (let idx = 0; idx < 256 * 4; idx += 4) {
      const pixIdx = (tileimg.data[idx] << 16) + (tileimg.data[idx + 1] << 8) + tileimg.data[idx + 2]
      let colidx = palette.findIndex(p => p.color === pixIdx)
      tilehex += colidx.toString(16)
    }
    return { img: tileimg, hex: tilehex }
  }

  /**
   * Read all pixel data and build the palette
   */
  buildPalette () {
    const data = this.imageData.data
    const pal = {}
    for (let y = 0; y < this.imageHeight; y++) {
      for (let x = 0; x < this.imageWidth; x++) {
        let idx = (y * this.imageWidth + x) << 2
        const pixidx = (data[idx++] << 16) + (data[idx++] << 8) + data[idx]
        const value = pal[pixidx]
        if (!value) {
          pal[pixidx] = 1
        } else {
          pal[pixidx]++
        }
      }
    }
    const pal2 = []
    for (let col in pal) {
      col = parseInt(col)
      pal2.push({ color: col, hex: ('00000' + col.toString(16)).slice(-6), usage: pal[col] })
    }
    this.palette = pal2
  }

  go () {
    this.convertImgToCanvas()
    this.buildPalette()
    this.showPalette()

    this.buildTilemap()
    this.showTiles()

    console.log(`${this.tilesgfx.length} unique tilesgfx, tilesData=${this.tilesgfx.length * 128} bytes`)
    const tilesUsedOnce = this.tilesgfx.filter(a => a.usage === 1)
    console.log(`${tilesUsedOnce.length} tiles used only 1 time:`, tilesUsedOnce)
    console.log('tilemap:', this.tilemap)
  }
}



class Ste {
  /**
   * return hex string for 16 pixels interleaved on 4 bitplanes
   * 9939 9999 9999 9399
   * doit retourner: dffb 0000 2004 ffff
   */
  bitplanify (hexrow) {
    let out = [0, 0, 0, 0]
    for (let dec = 15; dec >= 0; dec--) {
      let num = parseInt(hexrow[15 - dec], 16)
      out[0] |= (num & 1) << dec
      num >>= 1
      out[1] |= (num & 1) << dec
      num >>= 1
      out[2] |= (num & 1) << dec
      num >>= 1
      out[3] |= (num & 1) << dec
    }
    out = out.reduce((acc, val) => acc + ('000'  + val.toString(16)).slice(-4), '')
    return out
  }

  convertTile (tile) {
    let out = new Uint16Array()
    for (let i = 0; i < 16; i++) {
      let block = tile.hex.slice(i * 16, i * 16 + 16)
      out += this.bitplanify(block)
    }
    return out
  }

  sendPalette (palette) {
    let pal = this.convPalette(palette)
    pal = this.hex2bin(pal)
    this.sendfile('palette.bin', [ pal ])
  }

  sendTilemap (tilemap) {
    this.sendfile('tilemap.bin', [ new Uint8Array(tilemap) ])
  }

  sendTiles (tiles) {
    let tilesbin = tiles.map(tile => this.convertTile(tile))
    tilesbin = tilesbin.map(tile => this.hex2bin(tile))
    this.sendfile('tiles.bin', tilesbin)
  }

  hex2bin (hex) {
    return new Uint8Array(hex.match(/../gi).map(a => parseInt(a, 16)))
  }

  /**
   * this.sendfile("test.bin", [new Uint8Array([1,2,3])])
   */
  sendfile (name, aBytes) {
    const blob = new Blob(aBytes, { type: 'application/octet-binary' })
    const anc = document.createElement('a')
    anc.download = name
    anc.rel = 'noopener'
    anc.href = URL.createObjectURL(blob)
    anc.click()
    // expire ater 1 minute
    setTimeout(_ => URL.revokeObjectURL(anc.href), 60E3)
  }

  /**
   * transform "d0e0f0" -> "0e7f"
   */
  convColor (hex) {
    const comp8to4Bit = c => (c >> 5) + (((c >> 4) & 1) << 3)
    const r = comp8to4Bit(parseInt(hex.slice(0, 2), 16))
    const g = comp8to4Bit(parseInt(hex.slice(2, 4), 16))
    const b = comp8to4Bit(parseInt(hex.slice(4, 6), 16))
    return ('000' + ((r << 8) + (g << 4) + b).toString(16)).slice(-4)
  }

  convPalette (pal) {
    const stpal = pal.map(col => this.convColor(col.hex))
    return (stpal.reduce((a, b) => a + b) + "0000000000000000000000000000000000000000").slice(0, 64)
  }
}

if (typeof module !== 'undefined') { module.exports = { Tilemap, Ste } }
