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

    this.el.canvas = document.getElementById('canvas')
    this.el.palette = document.getElementById('palette')
    this.el.tiles = document.getElementById('tiles')
    this.el.tilesCanvas = document.querySelectorAll('#tilemap .prevnext canvas')
    this.el.tilesUsage = document.querySelectorAll('#tilemap .prevnext .usage')
    this.el.tilesCanvas.forEach(canvas => {
      // les canvas sont zoomés sans smoothing pour voir les pixels
      const ctx = canvas.getContext('2d')
      ctx.scale(2, 2)
      ctx.imageSmoothingEnabled = false
    })

    this.el.tiles.addEventListener('click', this.clickOnTiles.bind(this))
  }

  clickOnTiles (e) {
    let [x, y] = [e.offsetX, e.offsetY]
    x = Math.floor((x - 1) / 17)
    y = Math.floor((y - 1) / 17)
    const tilenb = y * 64 + x
    const tilegfx = this.tilesgfx[tilenb]
    if (tilegfx) {
      this.showOneTileUsage(tilenb)
      var newCanvas = document.createElement('canvas')
      newCanvas.width = 16
      newCanvas.height = 16
      newCanvas.getContext('2d').putImageData(tilegfx.img, 0, 0)
      let ctx = this.el.tilesCanvas[0].getContext('2d')
      ctx.drawImage(newCanvas, 0, 0)
    }
  }

  convertImgToCanvas () {
    const myImgElement = document.getElementById('sourceImg')
    this.el.canvas.width = myImgElement.width
    this.el.canvas.height = myImgElement.height
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
    this.pixel = this.imageCtx.createImageData(1, 1)
    this.pixel.data[3] = 255
  }

  extractPalette () {
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

  showPalette () {
    const div = this.el.palette
    this.palette.forEach((x, y) => {
      const txt = `<div class="palcol">${y}: ${x.usage}<br /><span class="tile" style="background-color: #${x.hex};"></span>#${x.hex}</div>`
      div.innerHTML += txt
    })
  }

  /**
   * build tilesgfx, tilemap
   */
  extractTiles () {
    const tilesgfx = this.tilesgfx
    const tilemap = this.tilemap

    for (let x = 0, tileIdx = 0; x < this.imageWidth >> 4; x++) {
      for (let y = 0; y < this.imageHeight >> 4; y++) {
        const curTile = this.getTileFromMain(x, y, this.palette)
        const tileNb = tilesgfx.findIndex(a => a.hex === curTile.hex)
        if (tileNb === -1) {
          curTile.usage = 1
          tilesgfx.push(curTile)
          tilemap.push(tileIdx++)
        } else {
          // this.blackTile(x, y)
          tilemap.push(tileNb)
          tilesgfx[tileNb].usage++
        }
      }
    }
  }

  showTiles (tilesPerRow = 16) {
    const canvas = this.el.tiles
    const ctx = canvas.getContext('2d')
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
  }

  getTileFromMain (x, y, palette) {
    const tileimg = this.imageCtx.getImageData(x << 4, y << 4, 16, 16)
    let tilehex = ''

    for (let idx = 0; idx < 256 * 4; idx += 4) {
      const pixIdx = (tileimg.data[idx] << 16) + (tileimg.data[idx + 1] << 8) + tileimg.data[idx + 2]
      let colidx = palette.findIndex(p => p.color === pixIdx)
      tilehex += colidx.toString(16)
    }
    return { img: tileimg, hex: tilehex }
  }

  blackTile (x, y) {
    this.imageCtx.fillStyle = '#000000'
    this.imageCtx.fillRect(x << 4, y << 4, 16, 16)
  }

  showOneTileUsage (tileToShow) {
    this.imageCtx.fillStyle = '#000000'
    this.imageCtx.putImageData(this.imageData, 0, 0)
    // const widthTile = this.imageWidth / 16
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
    this.extractPalette()
    this.showPalette()

    this.extractTiles()
    this.showTiles(64)

    console.log(`${this.tilesgfx.length} unique tilesgfx, tilesData=${this.tilesgfx.length * 128} bytes`)
    const tilesUsedOnce = this.tilesgfx.filter(a => a.usage === 1)
    console.log(`${tilesUsedOnce.length} tiles used only 1 time:`, tilesUsedOnce)
    console.log('tilemap:', this.tilemap)

    // this.showOneTileUsage(2)
  }
}
