import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "Player/player"

playdate.display.setScale(2)
playdate.display.setRefreshRate(8)

local gridSize = 16
local gridOn = true
local screenWidth = playdate.display.getWidth()
local screenHeight = playdate.display.getHeight()

local kGameState = {INITIAL, READY, PLAYING, PAUSED, OVER}
local currentState = kGameState.INITIAL

local player = Player()

function playdate.update()
	--playdate.graphics.clear()
	player:nextImage()
	player:update()
	draw_grid()
end

function draw_grid()
	playdate.graphics.setDitherPattern(0.5)
	if gridOn then drawGrid() end
	playdate.graphics.setDitherPattern(0.0)
end

function drawGrid()
	for x = gridSize, screenWidth, 16 do
		playdate.graphics.drawLine( x, 0, x, screenHeight)
	end
	for y = gridSize, screenHeight, 16 do
		playdate.graphics.drawLine(0, y, screenWidth, y)
	end
end

function setup()
	-- setup stuff
	player:moveTo(4*16+9,4*16+9)
	player:update()
end

function playdate.AButtonDown()
	-- invert color
	--playdate.display.setInverted(not playdate.display.getInverted())
end

setup()
