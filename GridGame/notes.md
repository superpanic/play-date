```lua
-- draw a 16 x 16, dithered grid
function draw_grid()
	playdate.graphics.setDitherPattern(0.5)
	for x = grid_size, screen_width, 16 do
		playdate.graphics.drawLine( x, 0, x, screen_height)
	end
	for y = grid_size, screen_height, 16 do
		playdate.graphics.drawLine(0, y, screen_width, y)
	end
	playdate.graphics.setDitherPattern(0.0)
end
```
