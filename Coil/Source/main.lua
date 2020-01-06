import "CoreLibs/graphics"
import "CoreLibs/sprites"

-- global vars:
lib_gfx = playdate.graphics
lib_spr = playdate.graphics.sprite

playdate.display.setScale(1)
lib_gfx.setBackgroundColor(lib_gfx.kColorWhite)
lib_gfx.clear()

g_grid_size = 16 -- pixel size of tiles
g_screen_width = playdate.display.getWidth()
g_screen_height = playdate.display.getHeight()

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
	local tiles = level_data.levels[1].tiles
	for y = 1,4 do
		for x = 1,12 do
			local tile = tiles[ (y-1)*12+x ]
			-- get the image tile and draw to level map
			local img = level_img_table:getImage(tile)
			-- adjust for image being 0-indexed
			local xp = x * 8
			local yp = y * 8
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
	ball_sprite:setImage(ball_img)

	ball_pos.x = g_screen_width/2
	ball_pos.y = g_screen_height/2
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
	p = degreesToCoords(playdate.getCrankPosition())		
	ball_pos.x = ball_pos.x + ball_velocity * p.x
	ball_pos.y = ball_pos.y + ball_velocity * p.y
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

--local x,y = degreesToCoords(angle)
