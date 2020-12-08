class Tilemap {
  constructor () {
    this.imageData = null
    this.imageWidth = null
    this.imageHeight = null
    this.imageCtx = null
    this.pixel = null
    this.palette = null
    this.tiles = [] // gfx
    this.tilemap = [] // tile numbers
    this.tileUsage = [] //

  }

  convertImgToCanvas () {
    var myImgElement = document.getElementById('sourceImg')
    var myCanvasElement = document.createElement('canvas')
    myCanvasElement.width = myImgElement.width
    myCanvasElement.height = myImgElement.height
    var context = myCanvasElement.getContext('2d')
    // context.scale(myCanvasElement.width / myImgElement.width, myCanvasElement.height / myImgElement.height);
    context.drawImage(myImgElement, 0, 0)
    document.body.appendChild(myCanvasElement)
    myImgElement.remove()

    this.imageWidth = myImgElement.width
    this.imageHeight = myImgElement.height
    this.imageCtx = context
    this.imageData = context.getImageData(0, 0, this.imageWidth, this.imageHeight)

    // only do this once per page
    // then this.imageCtx.putImageData( pixel, x, y );
    this.pixel = this.imageCtx.createImageData(1, 1)
    this.pixel.data[3] = 255
  }

  getPalette () {
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

  getTilemap () {
    const tiles = this.tiles
    const tilemap = this.tilemap
    const tileUsage = this.tileUsage

    for (let x = 0, tileIdx = 0; x < this.imageWidth >> 4; x++) {
      for (let y = 0; y < this.imageHeight >> 4; y++) {
        const tilehex = this.getTileHex(x, y, this.palette)
        const tileNb = tiles.findIndex(a => a === tilehex)
        if (tileNb === -1) {
          tiles.push(tilehex)
          tilemap.push(tileIdx)
          tileUsage[tileIdx++] = 1
        } else {
          this.blackTile(x, y)
          tilemap.push(tileNb)
          tileUsage[tileNb]++
        }
      }
    }
  }

  getTileHex (x, y, palette) {
    const tiledata = this.imageCtx.getImageData(x << 4, y << 4, 16, 16).data
    let tilehex = ''

    for (let idx = 0; idx < 256 * 4; idx += 4) {
      const pixIdx = (tiledata[idx] << 16) + (tiledata[idx + 1] << 8) + tiledata[idx + 2]
      let colidx = palette.findIndex(p => p.color === pixIdx)
      tilehex += colidx.toString(16)
    }
    return tilehex
  }

  blackTile (x, y) {
    this.imageCtx.fillRect(x << 4, y << 4, 16, 16)
  }

  showOneTileUsage (tileToShow) {
    this.imageCtx.putImageData(this.imageData, 0, 0)
    //const widthTile = this.imageWidth / 16
    const heightTile = this.imageHeight / 16
    for (let tilenb = 0; tilenb < this.tilemap.length; tilenb++) {
      const currentTile = this.tilemap[tilenb]
      if (currentTile === tileToShow) {
        const x = parseInt(tilenb / heightTile)
        const y = tilenb - x * heightTile
        this.imageCtx.fillRect(x * 16, y * 16, 16, 16)
      }
    }
  }

  go () {
    this.convertImgToCanvas()
    this.getPalette()
    console.log('palette', this.palette)

    this.getTilemap()
    console.log(`${this.tiles.length} unique tiles, tilesData=${this.tiles.length * 128} bytes`)
    const tilesUsedOnce = this.tileUsage.filter(a => a === 1)
    console.log(`${tilesUsedOnce.lenght} tiles used only 1 time`)
    //console.log(tiles)
    console.log(this.tilemap)
    console.log(this.tileUsage)

    this.showOneTileUsage(2)
  }
}