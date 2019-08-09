import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"
import "Player/player"
import "Item/item"
import "Map/map"
import "Common/common"

local grid_on = false

local k_game_state = {
	INITIAL = 1, 
	READY   = 2, 
	PLAYING = 3, 
	PAUSED  = 4, 
	OVER    = 5
}

local current_state = k_game_state.INITIAL
local player = Player()
local map = Map()

playdate.display.setRefreshRate(0)


function setup()	
	player:moveToPos(0, 0)
end

function playdate.update()
	if grid_on then draw_grid() end
	playdate.timer.updateTimers()
	-- update all sprites
	libspr.update()
end

function playdate.rightButtonDown()
	player:moveRight()
	player:set_animation_right()
end

function playdate.rightButtonUp()
	player:set_animation_idle()
end


function playdate.leftButtonDown()
	player:moveLeft()
	player:set_animation_right()
end

function playdate.leftButtonUp()
	player:set_animation_idle()
end


function playdate.downButtonDown()
	player:moveDown()
	player:set_animation_down()
end

function playdate.downButtonUp()
	player:set_animation_idle()
end


function playdate.upButtonDown()
	player:moveUp()
	player:set_animation_up()
end

function playdate.upButtonUp()
	player:set_animation_idle()
end

setup()
