import "CoreLibs/graphics"

playdate.display.setScale(1)

local grid_size = 16
local screen_width = playdate.display.getWidth()
local screen_height = playdate.display.getHeight()

function playdate.update()
	
end

function draw_grid()
	playdate.graphics.setDitherPattern(0.5)
	for x = grid_size, screen_width, 16 do
		playdate.graphics.drawLine( x, 0, x, screen_height)
	end
	for y = grid_size, screen_height, 16 do
		playdate.graphics.drawLine(0,y,screen_width,y)
	end
	playdate.graphics.setDitherPattern(0.0)
end

function setup()
	draw_grid()	
end

function playdate.AButtonDown()
	-- invert color
	playdate.display.setInverted(not playdate.display.getInverted())
end

setup()