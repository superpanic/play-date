import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"
import "Player/player"
import "Being/snake"
import "Item/gold"
import "Item/cig"
import "Item/item"
import "Map/map"
import "Hud/hud"
import "common"

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

local map = Map()
local player = Player(map)
local hud = Hud(player)
map:set_player(player)

-- game setup
function setup()
	map:load_level(1)
	local pos = map:find_first_empty_tile()
	player:set_offset(map:get_map_offset().x, map:get_map_offset().y)
	player:move_to_pos(pos.x, pos.y)
	map:draw_map()
	hud:setup()
end

function update_map_offset(dir_x,dir_y)
	-- scroll if closer than global_edge_limit to screen edge	
	local pos = player:get_screen_pos()
	pos.x = math.floor(pos.x/global_grid_size)
	pos.y = math.floor(pos.y/global_grid_size)
	local scroll_x, scroll_y = 0, 0

	if dir_x == 1 then -- right edge
		if pos.x > screen_width/global_grid_size - global_edge_limit then
			scroll_x = -1
		end
	elseif dir_x == -1 then -- left edge
		if pos.x <= global_edge_limit then
			scroll_x = 1
		end
	end
	
	if dir_y == 1 then -- lower edge
		if pos.y > screen_height/global_grid_size - global_edge_limit then
			scroll_y = -1
		end
	elseif dir_y == -1 then -- upper edge
		if pos.y <= global_edge_limit then
			scroll_y = 1
		end	
	end
	
	map:add_map_offset(scroll_x, scroll_y)
	local map_offset = map:get_map_offset() 
	player:set_offset(map_offset.x, map_offset.y)
	--player:update_pos()
end

-- main game loop
function playdate.update()
	if current_state == k_game_state.INITIAL then
		setup()
		current_state = k_game_state.READY

	elseif current_state == k_game_state.READY then
		current_state = k_game_state.PLAYING

	elseif current_state == k_game_state.PLAYING then
		playdate.timer.updateTimers() -- update all timers
		map:update_beings()
		hud:update()
		--map:update_visibility_map()
		libspr.update() -- update all sprites
	end
end

-- handle buttons
function playdate.rightButtonDown()
	-- has to add +1 due to mixed 0 indexing and 1 indexing...
	if map:is_tile_passable(player.current_pos.x+1, player.current_pos.y) then
		if player:move_right() then
			update_map_offset(1,0)
		end
	end
	player:set_animation_right()
end

function playdate.leftButtonDown()
	if map:is_tile_passable(player.current_pos.x -1, player.current_pos.y) then
		if player:move_left() then
			update_map_offset(-1,0)
		end
	end
	player:set_animation_left()
end

function playdate.downButtonDown()
	if map:is_tile_passable(player.current_pos.x, player.current_pos.y +1) then
		if player:move_down() then
			update_map_offset(0,1)
		end
	end
	player:set_animation_down()
end

function playdate.upButtonDown()
	if map:is_tile_passable(player.current_pos.x , player.current_pos.y -1) then
		if player:move_up() then
			update_map_offset(0,-1)
		end
	end
	player:set_animation_up()
end


