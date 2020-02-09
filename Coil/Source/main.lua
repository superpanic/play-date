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

g_debug = true
g_debug_string = ""

local g_friction = 0.92
local g_acceleration = 0.2
local g_accelerate_flag = false


local k_game_state = {
	INITIAL = 1, 
	READY   = 2, 
	PLAYING = 3, 
	PAUSED  = 4, 
	OVER    = 5
}

local current_state = k_game_state.INITIAL

-- ball
local ball_sprite = lib_spr.new()
local ball_pos = {x=0,y=0}
local ball_velocity = 1
local ball_img_table = lib_gfx.imagetable.new('Artwork/ball')

-- level
local g_current_level = 1
local bg_sprite = lib_spr.new()
local level_img_table = lib_gfx.imagetable.new('Artwork/tiles')
local level_data = playdate.datastore.read('Levels/levels')
if(level_data == nil) then print("cound not read tile data") end

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

function draw_debug_grid(l)
	if not l then l = 1 end
	local w = 4
	local h = 5
	local grid_size = g_grid_size
	local xoffset = 120
	local yoffset = 4
	lib_gfx.setColor(lib_gfx.kColorWhite)
	for y = 0, h do
		lib_gfx.drawLine(xoffset, y * grid_size + yoffset, grid_size * w + xoffset, y * grid_size + yoffset)
		for x = 0, w do
			lib_gfx.drawLine(x * grid_size + xoffset, yoffset, x * grid_size + xoffset, h * grid_size + yoffset+1)
		end
	end
	p = iso_to_grid_pos(ball_pos,48)
	lib_gfx.setColor(lib_gfx.kColorXOR)
	lib_gfx.drawPixel(p.x+xoffset,p.y+yoffset)
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
	ball_sprite:setImage(ball_img)

--	ball_pos.x = g_screen_width/2
--	ball_pos.y = g_screen_height/2

	ball_pos.x = 50.0
	ball_pos.y = 25.0

	ball_sprite:moveTo(ball_pos.x, ball_pos.y)
	
	ball_sprite:setZIndex(1000)
	ball_sprite:add()

-- crank
	-- reset the crank diff
	playdate.getCrankChange()
	return
end

function get_ball_frame()
	local x = (math.floor(ball_pos.x) % 5)+1
	local y = (math.floor(ball_pos.y) % 5)
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
		lib_gfx.drawText(g_debug_string, 10, g_screen_height-25)
		draw_debug_grid()
	end
end

function paused()
	return
end

function update_ball_motion()
	if g_accelerate_flag then
		ball_velocity = ball_velocity + g_acceleration
	else
		ball_velocity = ball_velocity * g_friction
	end
	pos = degreesToCoords(playdate.getCrankPosition())		
	ball_pos.x = ball_pos.x + ball_velocity * pos.x
	ball_pos.y = ball_pos.y + ball_velocity * pos.y
	ball_sprite:moveTo(ball_pos.x, ball_pos.y)
	ball_sprite:setImage(ball_img_table:getImage(get_ball_frame()))
end

function degreesToCoords(angle)
	local crankRads = math.rad(angle)
	local xp = math.sin(crankRads)
	local yp = -1 * math.cos(crankRads)
	return {x=xp, y=yp}
end

function playdate.BButtonDown()
	if current_state == k_game_state.PAUSED then return end
	g_accelerate_flag = true
end

function playdate.BButtonUp()
	if current_state == k_game_state.PAUSED then return end
	g_accelerate_flag = false
end

function playdate.AButtonDown()
	if current_state == k_game_state.PAUSED then
		current_state = k_game_state.PLAYING
	else
		print("sprite count: " .. playdate.graphics.sprite.spriteCount() )

		current_state = k_game_state.PAUSED
	end	
end

function playdate.rightButtonDown()
	--print_pos()
end

function iso_to_grid_pos(pos, offset)
	--local offset_x = 48.0
	local tx = pos.x + (pos.y-1)*2 - offset + g_grid_size
	local ty = pos.y*2 - (pos.x - offset)/2 + g_grid_size
	return {x=tx, y=ty}
end

function get_height_val_at(pos)
	-- get list of height map values
	local h_map = level_data.levels[g_current_level].hmap
	-- get grid position from iso (screen position)
	local grid_pos = iso_to_grid_pos(pos, level_data.levels[g_current_level].offset)
	-- get level  width
	local w = level_data.levels[g_current_level].gridw
	-- get level height
	local h = level_data.levels[g_current_level].gridh

	local lookup_x = math.floor(grid_pos.x / w)
	local lookup_y = math.floor(grid_pos.y / h)
	--print(lookup_x, lookup_y)
	local i = w * (lookup_y-1) + lookup_x
	local h_val = 999
	if i <= #h_map and i > 0 then
		h_val = h_map[i]
	end
	return h_val
end

function print_pos()
	p = iso_to_grid_pos(ball_pos, 48)
	local h_val = get_height_val_at({x=p.x, y=p.y})
	g_debug_string=("x:"..string.format("%03d",math.floor(p.x/14)).." y:"..string.format("%03d",math.floor(p.y/12)) .. " height:".. string.format("%03d",h_val) )
end

-- x offset 48
-- y offset 0
-- grid 16

-- x - offset + (y-1)*2
-- y/2 - (x-x_offset)/2