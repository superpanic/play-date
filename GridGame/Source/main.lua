import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"
import "Player/player"
import "Item/item"
import "Map/map"
import "Common/common"

local k_game_state = {
	INITIAL = 1, 
	READY   = 2, 
	PLAYING = 3, 
	PAUSED  = 4, 
	OVER    = 5
}

local current_state = k_game_state.INITIAL

local level = 1
local score = 0

playdate.display.setRefreshRate(0)

local player = Player()
local enemy = Being() 
local map = Map()

-- game setup
function setup()
	map:load_level(1)
	local pos = map:find_first_empty_tile()
	player:set_offset(map:get_map_offset().x, map:get_map_offset().y)
	player:move_to_pos(pos.x, pos.y)
end

function update_map_offset(dir_x,dir_y)
	-- scroll if closer than edge_limit to screen edge	
	local pos = player:get_screen_pos()
	pos.x = math.floor(pos.x/grid_size)
	pos.y = math.floor(pos.y/grid_size)
	local scroll_x, scroll_y = 0, 0

	if dir_x == 1 then -- right edge
		if pos.x > screen_width/grid_size - edge_limit then
			scroll_x = -1
		end
	elseif dir_x == -1 then -- left edge
		if pos.x <= edge_limit then
			scroll_x = 1
		end
	end
	
	if dir_y == 1 then -- lower edge
		if pos.y > screen_height/grid_size - edge_limit then
			scroll_y = -1
		end
	elseif dir_y == -1 then -- upper edge
		if pos.y <= edge_limit then
			scroll_y = 1
		end	
	end
	
	map:add_map_offset(scroll_x, scroll_y)
	player:set_offset(map:get_map_offset().x, map:get_map_offset().y)
end

-- main game loop
function playdate.update()
	playdate.timer.updateTimers()
	-- update all sprites
	libspr.update()
end

-- handle buttons
function playdate.rightButtonDown()
	-- has to add +1 due to mixed 0 indexing and 1 indexing...
	if map:is_tile_passable(player.current_pos.x+1, player.current_pos.y) then
		update_map_offset(1,0)
		player:move_right()
	end
	player:set_animation_right()
end

function playdate.leftButtonDown()
	if map:is_tile_passable(player.current_pos.x -1, player.current_pos.y) then
		update_map_offset(-1,0)
		player:move_left()
	end
	player:set_animation_left()
end

function playdate.downButtonDown()
	if map:is_tile_passable(player.current_pos.x, player.current_pos.y +1) then
		update_map_offset(0,1)
		player:move_down()
	end
	player:set_animation_down()
end

function playdate.upButtonDown()
	if map:is_tile_passable(player.current_pos.x , player.current_pos.y -1) then
		update_map_offset(0,-1)
		player:move_up()
	end
	player:set_animation_up()
end

--[[
function playdate.rightButtonUp()
	player:set_animation_idle()
end

function playdate.leftButtonUp()
	player:set_animation_idle()
end

function playdate.downButtonUp()
	player:set_animation_idle()
end

function playdate.upButtonUp()
	player:set_animation_idle()
end
]]--


setup()
