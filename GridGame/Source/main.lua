import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"
import "Player/player"
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
	-- setup stuff
	player:moveTo(2*16+9, 2*16+9)
end

function playdate.update()
	if grid_on then draw_grid() end
	playdate.timer.updateTimers()
	libspr.update()
end

function playdate.rightButtonDown()
	player:set_animation_right()
end

function playdate.rightButtonUp()
	player:set_animation_idle()
end

setup()