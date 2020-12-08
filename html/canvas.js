let imageWidth
let imageHeight
let imageCtx
let pixel

function convertImgToCanvas () {
  var myImgElement = document.getElementById('sourceImg')
  var myCanvasElement = document.createElement('canvas')
  myCanvasElement.width = myImgElement.width
  myCanvasElement.height = myImgElement.height
  var context = myCanvasElement.getContext('2d')
  // context.scale(myCanvasElement.width / myImgElement.width, myCanvasElement.height / myImgElement.height);
  context.drawImage(myImgElement, 0, 0)
  document.body.appendChild(myCanvasElement)
  myImgElement.remove()

  imageWidth = myImgElement.width
  imageHeight = myImgElement.height
  imageCtx = context

  // only do this once per page
  // then imageCtx.putImageData( pixel, x, y );
  pixel = imageCtx.createImageData(1, 1)
  pixel.data[3] = 255
}

function getPalette (imageCtx) {
  const data = imageCtx.getImageData(0, 0, imageWidth, imageHeight).data
  const pal = {}
  for (let y = 0; y < imageHeight; y++) {
    for (let x = 0; x < imageWidth; x++) {
      let idx = (y * imageWidth + x) << 2
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
  return pal2
}

function getTileHex (x, y, palette) {
  const tiledata = imageCtx.getImageData(x << 4, y << 4, 16, 16).data
  let tilehex = ''

  for (let idx = 0; idx < 256 * 4; idx += 4) {
    const pixIdx = (tiledata[idx] << 16) + (tiledata[idx + 1] << 8) + tiledata[idx + 2]
    let colidx = palette.findIndex(p => p.color === pixIdx)
    tilehex += colidx.toString(16)
  }
  return tilehex
}

function blackTile (x, y) {
  imageCtx.fillRect(x << 4, y << 4, 16, 16)
}

function go () {
  convertImgToCanvas()
  const palette = getPalette(imageCtx)
  console.log('palette', palette)
  const tiles = []

  for (let x = 0; x < imageWidth >> 4; x++) {
    for (let y = 0; y < imageHeight >> 4; y++) {
      const tilehex = getTileHex(x, y, palette)
      const tileNb = tiles.findIndex(a => a === tilehex)
      if (tileNb === -1) {
        tiles.push(tilehex)
      } else {
        blackTile(x, y)
      }
    }
  }
  console.log(`${tiles.length} unique tiles, tilesData=${tiles.length * 128} bytes`)
}
