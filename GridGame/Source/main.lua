import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "Player/player"

playdate.display.setScale(2)
playdate.display.setRefreshRate(0)

local gridSize = 16
local gridOn = true
local screenWidth = playdate.display.getWidth()
local screenHeight = playdate.display.getHeight()

local kGameState = {
	INITIAL = 1, 
	READY   = 2, 
	PLAYING = 3, 
	PAUSED  = 4, 
	OVER    = 5
}

local currentState = kGameState.INITIAL
local player = Player()

function playdate.update()
	--playdate.graphics.clear()
	--player:nextImage()
	player:update()
	-- draw grid
	if gridOn then drawGrid() end
	-- drive timers
	
	playdate.timer.updateTimers()
end

function drawGrid()
	playdate.graphics.setDitherPattern(0.5)
	for x = gridSize, screenWidth, 16 do
		playdate.graphics.drawLine( x, 0, x, screenHeight)
	end
	for y = gridSize, screenHeight, 16 do
		playdate.graphics.drawLine(0, y, screenWidth, y)
	end
	playdate.graphics.setDitherPattern(0.0)
end

function setup()
	-- setup stuff
	player:moveTo(2*16+9,2*16+9)
	player:update()
end

function playdate.rightButtonDown()
	player:setAnimationRight()
end

function playdate.rightButtonUp()
	player:setAnimationIdle()
end

setup()