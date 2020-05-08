# speed-up notes
- test: is it the level arrays (tiles and heightmap) or the image redraw that makes the game frame differ when the level grows?

# try to rewrite these for speed
- check update_orb()
- update_level_offset()
- draw_interface()

# lua performance tests:
https://springrts.com/wiki/Lua_Performance

## SDK 0.8.1 API changes
```lua
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