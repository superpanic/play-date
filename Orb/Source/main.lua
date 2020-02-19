import "CoreLibs/graphics"
import "CoreLibs/sprites"

-- global vars:
lib_gfx = playdate.graphics
lib_spr = playdate.graphics.sprite

playdate.display.setScale(2)
lib_gfx.setBackgroundColor(lib_gfx.kColorWhite)
lib_gfx.clear()

g_grid_size = 16 -- pixel size of tiles
g_screen_width = playdate.display.getWidth()
g_screen_height = playdate.display.getHeight()

g_hmap_div = 10.6666
-- this is why this magic value is 10.66
-- grid size is 32 (not 16!)
--	32 * 4 = 128 
--	32 * 5 = 160
--	128/w = 10.66
--	160/h = 10.66


-- debug vars
g_debug = true
g_debug_string = ""
g_debug_counter = 1
g_debug_val = 0

-- state vars
local k_game_state = {
	INITIAL = 1, 
	READY   = 2, 
	PLAYING = 3, 
	PAUSED  = 4, 
	OVER    = 5
}

local current_state = k_game_state.INITIAL

-- ball vars
ball = {}
local ball_img_table = lib_gfx.imagetable.new('Artwork/ball')

-- level vars
local level_altitude_offset = 100
local g_current_level = 1
local bg_sprite = lib_spr.new()
local level_img_table = lib_gfx.imagetable.new('Artwork/tiles')
local level_data = playdate.datastore.read('Levels/levels')
if(level_data == nil) then print("cound not read tile data") end

function new_game_object(name, sprite, pos)
	local obj ={}
	obj.name = name
	obj.sprite = sprite
	obj.pos = pos
	obj.friction = 0.92
	
	obj.x_velocity = 0.0
	obj.y_velocity = 0.0

	obj.acceleration = 0.2
	obj.accelerate_flag = false
	obj.altitude = 0
	obj.fall_velocity = 0
	
	obj.print_name = function() 
		print(obj.name) 
	end
	
	return obj
end

function draw_grid(line_color, grid_size)
	lib_gfx.setColor(line_color)
	for x = g_grid_size, g_screen_width, grid_size do
		lib_gfx.drawLine( x, 0, x, g_screen_height)
	end
	for y = g_grid_size, g_screen_height, grid_size do
		lib_gfx.drawLine(0, y, g_screen_width, y)
	end
end

function draw_level(l)
	if not l then l = 1 end
	--print(level_data.levels[1].tiles[1])
	local tiles = level_data.levels[l].tiles
	local w = level_data.levels[l].gridw -- grid width
	local h = level_data.levels[l].gridh -- grid height
	for y = 1,h do
		for x = 1,w do
			local tile = tiles[ (y-1)*w+x ]
			-- get the image tile and draw to level map
			local img = level_img_table:getImage(tile)
			-- adjust for image being 0-indexed
			local xp = (x-1) * 8
			local yp = (y-1) * 8
			img:drawAt(xp,yp)
		end
	end
end

function setup()
	
-- background
	local bg_img = lib_gfx.image.new(g_screen_width, g_screen_height)
	
	
	-- draw background
	lib_gfx.lockFocus(bg_img)
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(0, 0, g_screen_width, g_screen_height)
		--draw_grid(lib_gfx.kColorWhite, 32)
		draw_level()
	lib_gfx.unlockFocus()
	bg_sprite:setImage(bg_img)

	bg_sprite:moveTo(g_screen_width/2, g_screen_height/2)

	bg_sprite:setZIndex(-1000)
	bg_sprite:add()
	
-- ball
	local ball_img = ball_img_table:getImage(13)
	local ball_sprite = lib_spr.new()
	ball_sprite:setImage(ball_img)
	local ball_pos = {}
	ball_pos.x = 50.0
	ball_pos.y = 25.0

	ball = new_game_object("ball", ball_sprite, ball_pos)
	ball.sprite:moveTo(ball.pos.x, ball.pos.y)
	ball.sprite:setZIndex(1000)	
	ball.sprite:add()

-- crank
	-- reset the crank diff
	playdate.getCrankChange()
	return
end

function get_ball_frame()
	local x = (math.floor(ball.pos.x) % 5)+1
	local y = (math.floor(ball.pos.y) % 5)
	return y*5+x
end

-- main game loop
function playdate.update()
	if current_state == k_game_state.INITIAL then
		print("setup")
		setup()
		current_state = k_game_state.READY

	elseif current_state == k_game_state.READY then
		print("start")
		current_state = k_game_state.PLAYING
		
	elseif current_state == k_game_state.PLAYING then
		update_ball_motion()
		lib_spr.update() -- update all sprites
		
	elseif current_state == k_game_state.PAUSED then
		paused()
	end
	if g_debug == true then
		print_pos()
		lib_gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
		lib_gfx.drawText(g_debug_string, 10, g_screen_height-22)
		draw_debug_grid()
	end
end

function paused()
	return
end

function update_ball_motion()
	-- get current direction
	local vector = degreesToCoords(playdate.getCrankPosition())

	-- adjust velocity
	if ball.accelerate_flag then
		ball.x_velocity = ball.x_velocity + (vector.x * ball.acceleration)
		ball.y_velocity = ball.y_velocity + (vector.y * ball.acceleration)
	else
		ball.x_velocity = ball.x_velocity * ball.friction
		ball.y_velocity = ball.y_velocity * ball.friction
	end

	-- set next pos
	local next_pos = {}
	next_pos.x = ball.pos.x + ball.x_velocity
	next_pos.y = ball.pos.y + ball.y_velocity

	-- adjust next pos
	next_pos = collision_check(next_pos)
	altitude_update()

	-- set ball poss
	ball.pos.x = next_pos.x
	ball.pos.y = next_pos.y

	-- move sprite
	ball.sprite:moveTo(ball.pos.x, ball.pos.y+(ball.altitude))
	ball.sprite:setImage(ball_img_table:getImage(get_ball_frame()))
end

function collision_check(next_pos)
	-- collision with walls
	-- collision with other objects
	-- adjust next pos before returning
	return next_pos
end

function altitude_update()
	ball.altitude = (100-get_altitude_at_pos(ball.pos))/2

	-- are we on flat gound?
	-- if more than 2 adjacent squares have the same height value, the ground is flat.
	local current_pos = iso_to_grid_pos(ball.pos)
	local table_pos_x, table_pos_y = get_height_table_lookup_pos(current_pos)
	local compare_value = get_height_val_at(current_pos)
	local flat_counter = 0
	--local flat = true

	for x = -1,1 do
		for y = -1,1 do
			-- look in hmap and compare with current hmap value
			if get_height_table_value_at(table_pos_x+x, table_pos_y+y) == compare_value then 
				flat_counter = flat_counter + 1
			end
		end
	end

	if flat_counter <= 3 then 
		local vector = {x=0.0,y=0.0}
		-- we are on a slope!
		-- find direction of the slope:
		-- there is only 4 possible slopes (+ flat)		
		if get_height_table_value_at(table_pos_x-1, table_pos_y) < compare_value then
			vector = {x=-0.1, y=-0.1}
		elseif get_height_table_value_at(table_pos_x+1, table_pos_y) < compare_value then
			vector = {x=0.1, y=0.1}
		elseif get_height_table_value_at(table_pos_x, table_pos_y-1) < compare_value  then
			vector = {x=0.1, y=0.0}
		elseif get_height_table_value_at(table_pos_x, table_pos_y+1) < compare_value then
			vector = {x=-0.1, y=0.1}
		end
		ball.x_velocity = ball.x_velocity + vector.x
		ball.y_velocity = ball.y_velocity + vector.y
	end

--	local current_pos = iso_to_grid_pos(ball.pos)
--	local search_pos = current_pos
--	local step_counter = 1

end

function degreesToCoords(angle)
	local crankRads = math.rad(angle)
	local xp = math.sin(crankRads)
	local yp = -1 * math.cos(crankRads)
	return {x=xp, y=yp}
end

function get_altitude_at_pos(p)
	local pos = iso_to_grid_pos(p)
	local h = get_height_val_at({x=pos.x, y=pos.y})
	return h
end

function iso_to_grid_pos(p)
	local offset = level_data.levels[g_current_level].offset
	local grid_x = p.x + p.y * 2 - offset + g_grid_size
	local grid_y = p.y * 2 - (p.x - offset) + g_grid_size
	return { x = grid_x, y = grid_y }
end

function grid_to_iso_pos(p)
	-- TODO: rewrite to use high-res grid coordiantes and convert (render) to isometric-screen coordinates!
	-- start by writing the algorithm for converting grid to iso
	local offset = level_data.levels[g_current_level].offset
	local iso_x = 0
	local iso_y = 0
	return { x =iso_x, y = iso_y }
end

function get_height_val_at(top_down_pos)
	lookup_x, lookup_y = get_height_table_lookup_pos(top_down_pos)
	return get_height_table_value_at(lookup_x, lookup_y)
end

function get_height_table_lookup_pos(top_down_pos)
	local lookup_x = math.floor(((top_down_pos.x) / g_hmap_div)+1.0)
	local lookup_y = math.floor(((top_down_pos.y) / g_hmap_div)+1.0)
	return lookup_x, lookup_y
end

function get_height_table_value_at(lookup_x, lookup_y)
	-- get list of height map values
	local h_map = level_data.levels[g_current_level].hmap
	-- get height table width
	local w = level_data.levels[g_current_level].height_table_w
	-- get height table height
	local h = level_data.levels[g_current_level].height_table_h

	local h_val = 999
	-- boundary check
	if (lookup_x > 0 and lookup_x <= w and lookup_y > 0 and lookup_y <= h) then
		local index = w * (lookup_y-1) + lookup_x
		if index <= #h_map and index > 0 then
				h_val = h_map[index]
		end
	end

	return h_val
end


-- BUTTONS

function playdate.BButtonDown()
	if current_state == k_game_state.PAUSED then return end
	ball.accelerate_flag = true
end

function playdate.BButtonUp()
	if current_state == k_game_state.PAUSED then return end
	ball.accelerate_flag = false
end

function playdate.AButtonDown()
	if current_state == k_game_state.PAUSED then
		current_state = k_game_state.PLAYING
		print("game running")
	else
		current_state = k_game_state.PAUSED
		print("game paused")
		print("debug value: " .. g_debug_val)
	end
end

function playdate.rightButtonDown()
	local xoff = 48
	local debug_pos_list = { {x=xoff,y=0}, {x=xoff,y=16}, {x=xoff,y=32}, {x=xoff,y=48},
				 {x=xoff,y=0}, {x=xoff+16,y=8}, {x=xoff+32,y=16}, {x=xoff+48,y=24},
				{x=xoff,y=0}, {x=xoff-16,y=8}, {x=xoff-32,y=16}, {x=xoff-48,y=24} }
	if g_debug_counter < #debug_pos_list then
		g_debug_counter = g_debug_counter + 1
	else
		g_debug_counter=1
	end
	ball.pos.x = debug_pos_list[g_debug_counter].x
	ball.pos.y = debug_pos_list[g_debug_counter].y
end

function playdate.upButtonDown()
	ball.pos.x = 48
	ball.pos.y = -7
end

function playdate.downButtonDown()
	ball.pos.x = ball.pos.x + 0.5
	ball.pos.y = ball.pos.y + 0.25
end

function playdate.leftButtonDown()
	ball.pos.x = ball.pos.x - 0.5
	ball.pos.y = ball.pos.y + 0.25
end




-- DEBUG

function print_pos()
	local p = iso_to_grid_pos(ball.pos, 48)
	local h_val = get_height_val_at({x=p.x, y=p.y})
	g_debug_string = (
		 "x:"..string.format("%03d",math.floor(p.x + 0.5))..
		" y:"..string.format("%03d",math.floor(p.y + 0.5)) .. 
		" height:".. string.format("%03d", h_val)
	)
end

function draw_debug_grid(l)
	if not l then l = 1 end
	local w = 4
	local h = 5
	local grid_size = g_grid_size
	local xoffset = 130
	local yoffset = 4
	lib_gfx.setColor(lib_gfx.kColorWhite)
	for y = 0, h do
		lib_gfx.drawLine(xoffset, y * grid_size + yoffset, grid_size * w + xoffset, y * grid_size + yoffset)
		for x = 0, w do
			lib_gfx.drawLine(x * grid_size + xoffset, yoffset, x * grid_size + xoffset, h * grid_size + yoffset+1)
		end
	end
	local p = iso_to_grid_pos(ball.pos,48)
	lib_gfx.setColor(lib_gfx.kColorXOR)
	-- divide by 2, and draw pixel
	lib_gfx.drawPixel((p.x/2)+xoffset,(p.y/2)+yoffset)
end