```lua
-- draw a 16 x 16, dithered grid
function draw_grid()
	playdate.graphics.setDitherPattern(0.5)
	for x = global_grid_size, screen_width, 16 do
		playdate.graphics.drawLine( x, 0, x, screen_height)
	end
	for y = global_grid_size, screen_height, 16 do
		playdate.graphics.drawLine(0, y, screen_width, y)
	end
	playdate.graphics.setDitherPattern(0.0)
end

function degreesToCoords(angle)
  local crankRads = math.rad(angle)
  local x = math.sin(crankRads)
  local y = -1 * math.cos(crankRads)

  x = (r * x) + centerX
  y = (r * y) + centerY

  return x,y
end

local x,y = degreesToCoords(angle)

```

** SDK 0.8.1 API changes
```
playdate.graphics.clearStencil → graphics.clearStencilImage
playdate.graphics.loadImage → graphics.image.new
playdate.graphics.loadImageTable → graphics.imagetable.new
playdate.graphics.loadImagetable → graphics.imagetable.new
playdate.graphics.newImage → graphics.image.new
playdate.graphics.nineSlice.drawRect → playdate.graphics.nineSlice.drawInRect
playdate.graphics.getDrawMode → graphics.getImageDrawMode
playdate.graphics.setDrawMode → graphics.setImageDrawMode
playdate.graphics.setFontAdvance → graphics.setFontTracking
playdate.graphics.sprite.setBackgroundColor → playdate.graphics.setBackgroundColor
playdate.setRefreshRate → playdate.display.setRefreshRate
Removed playdate.graphics.animation.loop.updateAll
Removed playdate.graphics.setBufferMode
Removed playdate.graphics.sprite.drawSprites
Removed playdate.readBatteryVoltage
Removed playdate.timer.stop
Removed playdate.timer.updateAll
```