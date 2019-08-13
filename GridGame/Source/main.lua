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
local level = 1
local score = 0

playdate.display.setRefreshRate(0)

-- game setup
function setup()
	local pos = map:find_first_empty_tile()
	player:moveToPos(pos.x, pos.y)
end

-- main game loop
function playdate.update()
	if grid_on then draw_grid() end
	playdate.timer.updateTimers()
	-- update all sprites
	libspr.update()
end


-- handle buttons
function playdate.rightButtonDown()
	-- has to add +1 due to mixed 0 indexing and 1 indexing...
	if map:is_tile_passable(player.current_pos.x+1, player.current_pos.y) then
		player:moveRight()
	end
	player:set_animation_right()
end

function playdate.rightButtonUp()
	player:set_animation_idle()
end

function playdate.leftButtonDown()
	if map:is_tile_passable(player.current_pos.x -1, player.current_pos.y) then	
		player:moveLeft()
	end
	player:set_animation_right()
end

function playdate.leftButtonUp()
	player:set_animation_idle()
end

function playdate.downButtonDown()
	if map:is_tile_passable(player.current_pos.x, player.current_pos.y +1) then	
		player:moveDown()
	end
	player:set_animation_down()
end

function playdate.downButtonUp()
	player:set_animation_idle()
end

function playdate.upButtonDown()
	if map:is_tile_passable(player.current_pos.x , player.current_pos.y -1) then	
		player:moveUp()
	end
	player:set_animation_up()
end

function playdate.upButtonUp()
	player:set_animation_idle()
end

--
setup()
