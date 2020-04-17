import "CoreLibs/graphics"
import "CoreLibs/sprites"

-- global vars:
lib_gfx = playdate.graphics
lib_spr = playdate.graphics.sprite

playdate.display.setRefreshRate(30)
playdate.display.setScale(2)
lib_gfx.setBackgroundColor(lib_gfx.kColorBlack)
lib_gfx.clear()

local DEBUG_FLAG = false
local DEBUG_STRING = ""
local DEBUG_VAL = 0.0

local DEBUG_STEP_FRAME = false
local DEBUG_FRAME_STEP = false
local DEBUG_FRAME_COUNTER = 0

local SCREEN_WIDTH = playdate.display.getWidth()
local SCREEN_HEIGHT = playdate.display.getHeight()

local GRID_SIZE = 16
local HALF_GRID_SIZE = GRID_SIZE / 2

local INFINITY_FLOOR_ALTITUDE = -1000
local ALTITUDE_LIMIT = -500
local EDGE_COLLISION_HEIGHT = 4

local FRICTION = 0.92
local GRAVITY = 0.75

-- state vars
local GAME_STATE = {
	initial = 1, 
	ready   = 2, 
	playing = 3, 
	paused  = 4, 
	goal    = 5,
	over    = 6
}

local CURRENT_STATE = GAME_STATE.initial

-- ORB vars
local ORB = {}
local ORB_IMAGE_TABLE = lib_gfx.imagetable.new('Artwork/ORB')

-- level vars
local CURRENT_LEVEL = 3
local BACKGROUND_SPRITE = lib_spr.new()
local TILE_IMAGES = lib_gfx.imagetable.new('Artwork/level_tiles')
local LEVEL_DATA = playdate.datastore.read("Levels/levels")
	print(LEVEL_DATA.description)
local TILE_DATA = playdate.datastore.read("Levels/tiles")
	print(TILE_DATA.description)

local LEVEL_OFFSET = { x=60, y=20, velx=0, vely=0 }

function new_game_object(name, sprite, pos)
	local obj ={}
	obj.name = name
	obj.sprite = sprite
	
	-- use sprite cover to draw on top of object
	obj.sprite_cover = lib_spr.new()
	local img = lib_gfx.image.new(GRID_SIZE*2, GRID_SIZE*2)
	obj.sprite_cover:setImage(img)
	obj.sprite_cover:add()

	obj.pos = {}
	obj.pos.x = pos.x
	obj.pos.y = pos.y
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

	obj.set_z_index = function(z)
		obj.sprite:setZIndex(z)
		obj.sprite_cover:setZIndex(z+1)
	end
	
	return obj
end

function setup()
-- orb (player sprite)
	local orb_img = ORB_IMAGE_TABLE:getImage(13)
	local orb_sprite = lib_spr.new()
	orb_sprite:setImage(orb_img)
	local orb_pos = {}
	orb_pos.x = 0.0
	orb_pos.y = 0.0
	ORB = new_game_object("ORB", orb_sprite, orb_pos)
	ORB.print_name()
	move_orb_to_start_position()
	ORB.sprite:moveTo(ORB.pos.x, ORB.pos.y)
	ORB.set_z_index(1000)
	ORB.sprite:add()

--	m = ORB.sprite:getImage():getMaskImage()
--	lib_gfx.lockFocus(m)
--		m:setInverted(true)
--	lib_gfx.unlockFocus()

-- background as a sprite
	local bg_img = lib_gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)
	lib_gfx.lockFocus(bg_img)
		lib_gfx.setColor(lib_gfx.kColorClear)
		lib_gfx.fillRect(0,0,SCREEN_WIDTH,SCREEN_HEIGHT)
	lib_gfx.unlockFocus()
	BACKGROUND_SPRITE:setImage(bg_img)
	BACKGROUND_SPRITE:moveTo(SCREEN_WIDTH/2,SCREEN_HEIGHT/2)
	BACKGROUND_SPRITE:setZIndex(-1000)
	BACKGROUND_SPRITE:add()
	
-- reset crank
	playdate.getCrankChange()
	return
end

function playdate.update()
	if DEBUG_FLAG and DEBUG_STEP_FRAME then
		if not DEBUG_FRAME_STEP then return end
	end

	if CURRENT_STATE == GAME_STATE.initial then
		print("setup")
		setup()
		CURRENT_STATE = GAME_STATE.ready


	elseif CURRENT_STATE == GAME_STATE.ready then
		print("start")
		CURRENT_STATE = GAME_STATE.playing
		

	elseif CURRENT_STATE == GAME_STATE.playing then
		update_orb()
		draw_level()
		end_level_check()
		lib_spr.update() -- update all sprites
		update_level_offset()
	

	elseif CURRENT_STATE == GAME_STATE.goal then
		level_clear()
		update_orb()
		draw_level()
		lib_spr.update() -- update all sprites
		update_level_offset()

	elseif CURRENT_STATE == GAME_STATE.dead then
		-- nothing
		
	elseif CURRENT_STATE == GAME_STATE.paused then
		paused()
		
	end

	if DEBUG_FLAG then
		DEBUG_FRAME_STEP = false
		DEBUG_FRAME_COUNTER = DEBUG_FRAME_COUNTER + 1
		lib_gfx.setImageDrawMode(lib_gfx.kDrawModeFillWhite)
		lib_gfx.drawText(DEBUG_STRING, 5, 5)
		lib_gfx.drawText(tostring(DEBUG_VAL), 5, 20)
		lib_gfx.setImageDrawMode(lib_gfx.kDrawModeCopy)
	end
	
end

function level_clear()
	add_friction(0.75)
end

function end_level_check()
	if ( get_tile_type( math.floor(ORB.pos.x+0.5), math.floor(ORB.pos.y+0.5) ) == "goal" ) then 
		CURRENT_STATE = GAME_STATE.goal
		ORB.accelerate_flag = false
		print("goal!")
	end
	if ORB.altitude <= ALTITUDE_LIMIT then
		CURRENT_STATE = GAME_STATE.dead
		print("dead!")
		return
	end
end

function add_friction(f)
	if math.abs(ORB.x_velocity) < 0.001 then ORB.x_velocity = 0 else
		ORB.x_velocity = ORB.x_velocity * f
	end
	if math.abs(ORB.y_velocity) < 0.001 then ORB.y_velocity = 0 else
		ORB.y_velocity = ORB.y_velocity * f
	end
end

function update_orb()
	-- get current direction
	-- local vectorx, vectory = degrees_to_vector( playdate.getCrankPosition()-45 )
	local vectorx, vectory, vectorz
	if playdate.accelerometerIsRunning() then
		vectorx, vectory, vectorz = playdate.readAccelerometer()
		vectory = vectory - 0.5
		vectorx, vectory = rotate_vector(vectorx, vectory) -- rotate 45 degrees
		vectorx = vectorx * 4
		vectory = vectory * 4
		if DEBUG_FLAG then DEBUG_STRING = string.format("x:%.2f, y:%.2f", vectorx, vectory) end
	else
		-- use crank for direction instead
		vectorx, vectory = degrees_to_vector( playdate.getCrankPosition()-45 )
		vectorx = vectorx * 1.5
		vectory = vectory * 1.5
	end
	
	if ORB.accelerate_flag then
		ORB.x_velocity = ORB.x_velocity + (vectorx * ORB.acceleration)
		ORB.y_velocity = ORB.y_velocity + (vectory * ORB.acceleration)
	end

	add_friction(ORB.friction)

	-- set next pos
	local next_pos = {}
	next_pos.x = ORB.pos.x + ORB.x_velocity
	next_pos.y = ORB.pos.y + ORB.y_velocity

	local collision_detected = wall_collision_check(ORB, next_pos.x, next_pos.y)

	-- set orb pos
	if collision_detected == false then
		ORB.pos.x = next_pos.x
		ORB.pos.y = next_pos.y
	end

	-- calculate altitude
	-- get tile grid position

	-- don't set altitude, instead increase fall velocity if orb is above floor...
	-- ORB.altitude = get_altitude_at_pos(ORB.pos.x, ORB.pos.y)

	local alt = get_altitude_at_pos(math.floor(ORB.pos.x+0.5), math.floor(ORB.pos.y+0.5))
	
	if alt < ORB.altitude - ORB.fall_velocity then
		ORB.fall_velocity = ORB.fall_velocity + GRAVITY
		ORB.altitude = math.max(alt, ORB.altitude - ORB.fall_velocity)
	else
		ORB.altitude = alt
		ORB.fall_velocity = 0
	end
	
	-- add slope velocity
	local slope_vx, slope_vy = get_slope_vector(ORB.pos.x, ORB.pos.y, ORB.altitude)
	ORB.x_velocity = ORB.x_velocity - slope_vx
	ORB.y_velocity = ORB.y_velocity - slope_vy

	-- move sprite
	local isox, isoy = grid_to_iso(ORB.pos.x, ORB.pos.y, 0, 0)
	-- offset orb half image height
	isoy = isoy - select(1,ORB.sprite:getImage():getSize())/2
	
	-- floor value to sync with background movement
	isox = math.floor( isox + LEVEL_OFFSET.x + 0.5 )
	isoy = math.floor( isoy - ORB.altitude + LEVEL_OFFSET.y + 0.5 )

	ORB.sprite:moveTo(isox, isoy)

	local image_frame = get_orb_frame()
	ORB.sprite:setImage(ORB_IMAGE_TABLE:getImage( image_frame ))

	DEBUG_VAL = ORB.altitude

end

function update_level_offset()
	LEVEL_OFFSET.velx = LEVEL_OFFSET.velx * FRICTION
	LEVEL_OFFSET.vely = LEVEL_OFFSET.vely * FRICTION

	local orb_x, orb_y = ORB.sprite:getPosition()
	if orb_x < GRID_SIZE * 3 then LEVEL_OFFSET.velx = LEVEL_OFFSET.velx + 0.5 end
	if orb_x > SCREEN_WIDTH - GRID_SIZE * 3 then LEVEL_OFFSET.velx = LEVEL_OFFSET.velx - 0.5 end
	if orb_y < GRID_SIZE * 2 then LEVEL_OFFSET.vely = LEVEL_OFFSET.vely + 0.5 end
	if orb_y > SCREEN_HEIGHT - GRID_SIZE * 2 then LEVEL_OFFSET.vely = LEVEL_OFFSET.vely - 0.5 end

	offset_background(LEVEL_OFFSET.velx, LEVEL_OFFSET.vely)
end

function draw_level(level)
	if not level then level = CURRENT_LEVEL end

	clear_background()
	z_mask_reset(ORB)

	local w = LEVEL_DATA.levels[level].w 
	local h = LEVEL_DATA.levels[level].h
	
	for y = 1, h do
		for x = 1, w do
			local index = w * (y-1) + x
			local tile = LEVEL_DATA.levels[level].tiles[index]
			local height_offset = LEVEL_DATA.levels[level].altitude[index]
			
			-- calculate tile screen position
			local isox, isoy = grid_to_iso( (x-1) * GRID_SIZE, (y-1) * GRID_SIZE)
						
			--z_mask_draw(ORB, index, tile, isox, isoy, height_offset)
			
			-- add tile image offset
			isox = isox + TILE_DATA.tiles[tile].xoffset + LEVEL_OFFSET.x
			isoy = isoy + TILE_DATA.tiles[tile].yoffset + LEVEL_OFFSET.y
			
			-- add latitude offset
			isoy = isoy - height_offset

			local image = TILE_IMAGES:getImage(tile)
			lib_gfx.lockFocus(BACKGROUND_SPRITE:getImage())
				image:drawAt(isox,isoy)
			lib_gfx.unlockFocus()

			z_mask_draw(ORB, x, y, tile, image, isox, isoy, height_offset )
		end
	end

	if DEBUG_FLAG then
		draw_debug_grid(CURRENT_LEVEL)
	end
end

function z_mask_reset(obj)
	lib_gfx.lockFocus(obj.sprite_cover:getImage())
		lib_gfx.setColor(lib_gfx.kColorClear)
		lib_gfx.fillRect(0,0,GRID_SIZE*2,GRID_SIZE*2)

		if DEBUG_FLAG then
			lib_gfx.setColor(lib_gfx.kColorWhite)
			lib_gfx.drawRect(0,0,GRID_SIZE*2,GRID_SIZE*2)
		end

	lib_gfx.unlockFocus()
	obj.sprite_cover:moveTo( obj.sprite:getPosition() )
end

function z_mask_draw( obj, tile_col, tile_row, tile, image, tile_iso_x, tile_iso_y, tile_altitude )
	obj_col = math.floor(obj.pos.x / GRID_SIZE) + 1
	obj_row = math.floor(obj.pos.y / GRID_SIZE) + 1

	-- check 1: are we standing on this tile?
	if obj_col == tile_col and obj_row == tile_row then
		-- if DEBUG_FLAG then DEBUG_STRING = TILE_DATA.tiles[tile].name end
		return -- dont mask if orb is standing on tile!
	end

	-- check 2: is tile to the left or the north of the orb? then return
	if tile_col < obj_col or tile_row < obj_row then return end
	
	-- check 3: is tile lower or same altitude as obj?
	local alt_diff = tile_altitude - obj.altitude
	-- if alt_diff <= 0 then return end
	-- this is a hack and does not work on low tiles that cover the object.
	if alt_diff < HALF_GRID_SIZE then return end

	-- ok, assume the tile is covering the object
	local objx, objy = obj.sprite:getPosition() -- screen position
	objx = objx - GRID_SIZE
	objy = objy - GRID_SIZE
	lib_gfx.lockFocus(obj.sprite_cover:getImage())
		image:drawAt( tile_iso_x - objx, tile_iso_y - objy )
	lib_gfx.unlockFocus()

end

function wall_collision_check(obj, nextx, nexty)
	-- collision if altitude is higher than 4 pixels
	
	objx = math.floor(obj.pos.x + 0.5)
	objy = math.floor(obj.pos.y + 0.5)
	nextx = math.floor(nextx + 0.5)
	nexty = math.floor(nexty + 0.5)

	-- if pos is the same, no collision, return
	if objx == nextx and objy == nexty then return false end
	
	local current_altitude = obj.altitude
	local next_altitude = get_altitude_at_pos(nextx, nexty)

	-- if altitude difference is same or low, no collision, roll on, return
	if next_altitude <= current_altitude + EDGE_COLLISION_HEIGHT then return false end
	
	-- we have a collision!

	-- create reversed velocity coordinates
	local rx = math.floor(obj.pos.x + (-obj.x_velocity) + 0.5)
	local ry = math.floor(obj.pos.y + (-obj.y_velocity) + 0.5)
	
	-- get reversed velocity x and y altitudes
	local rx_alt = get_altitude_at_pos(rx, nexty)
	local ry_alt = get_altitude_at_pos(nextx, ry)
	
	-- try
	if rx_alt <= current_altitude + EDGE_COLLISION_HEIGHT then
		-- no collision here, we can move  in this direction
		obj.x_velocity = -obj.x_velocity
	elseif ry_alt <= current_altitude + EDGE_COLLISION_HEIGHT then
		-- no collision here, we can move in this direction
		obj.y_velocity = -obj.y_velocity
	else
		-- blocked both ways, stop
		obj.x_velocity = 0
		obj.y_velocity = 0
	end

	return true
end

function get_slope_vector( x, y, current_altitude )
	x = math.floor(x+0.5)
	y = math.floor(y+0.5)

	if not current_altitude then current_altitude = get_altitude_at_pos( x, y ) end

	local w = LEVEL_DATA.levels[CURRENT_LEVEL].w * GRID_SIZE
	local h = LEVEL_DATA.levels[CURRENT_LEVEL].h * GRID_SIZE

	local slope_vx = 0
	local slope_vy = 0
	local force = 0
	local fx, fy = 0, 0

	local check_altitude = current_altitude
	for iy = -1, 1 do
		for ix = -1, 1 do
			if ix == 0 and iy == 0 then else -- don't check the pixel we stand on
				check_altitude = get_altitude_at_pos(x+ix,y+iy)	-- checking all directions, (because if we are standing still we need to check all directions anyway!)
				if check_altitude < current_altitude then -- only add force if check_altitude is lower than current_altitude
					-- force is equal to difference between check_altitude and current_altitude
					force = current_altitude - check_altitude
					if force <= 1 then -- if force is greater than 1, this is not a slope (it's an edge)
						-- ix and iy is the direction
						fx = ix * force
						fy = iy * force
						-- add negative force to total slope value
						slope_vx = slope_vx - fx
						slope_vy = slope_vy - fy
					end
				end
			end
		end
	end
	-- divide with 8 (the total number of coordinates added together)
	return slope_vx/8, slope_vy/8
end

function get_tile_type( x, y )
	if x < 0 or y < 0 then return "outofbounds" end
	local w = LEVEL_DATA.levels[CURRENT_LEVEL].w
	local h = LEVEL_DATA.levels[CURRENT_LEVEL].h
	if x >= w * GRID_SIZE or y >= h * GRID_SIZE then return "outofbounds" end

	local tilex = math.floor((x / GRID_SIZE))+1
	local tiley = math.floor((y / GRID_SIZE))+1
	local tile_index = w * (tiley-1) + tilex
	local tile_type =  LEVEL_DATA.levels[CURRENT_LEVEL].tiles[tile_index]
	return TILE_DATA.tiles[tile_type].type
end

function get_altitude_at_pos( x, y )

	if x < 0 or y < 0 then return INFINITY_FLOOR_ALTITUDE end

	local w = LEVEL_DATA.levels[CURRENT_LEVEL].w
	local h = LEVEL_DATA.levels[CURRENT_LEVEL].h

	if x >= w * GRID_SIZE or y >= h * GRID_SIZE then return INFINITY_FLOOR_ALTITUDE end

	-- find tile base altitude
	local tilex = math.floor((x / GRID_SIZE))+1
	local tiley = math.floor((y / GRID_SIZE))+1

	local tile_index = w * (tiley-1) + tilex

	local tile_type = LEVEL_DATA.levels[CURRENT_LEVEL].tiles[tile_index]
	local tile_altitude = LEVEL_DATA.levels[CURRENT_LEVEL].altitude[tile_index]

	-- find local tile altitude
	local tile_heightmap_x = math.floor( (x - GRID_SIZE * (tilex-1) ))+1
	local tile_heightmap_y = math.floor( (y - GRID_SIZE * (tiley-1) ))+1

	local tile_heightmap_index = (GRID_SIZE * (tile_heightmap_y-1) + tile_heightmap_x)

	-- add base altitude to local tile altitude
	local altitude = TILE_DATA.tiles[tile_type].heightmap[tile_heightmap_index]
	altitude = altitude + tile_altitude
	
	return altitude
end

function get_orb_frame()
	local imap_size = 5 -- the image map is 5 x 5 tiles
	--local spx,spy = ORB.sprite:getPosition()
	local spx, spy = grid_to_iso(ORB.pos.x, ORB.pos.y)
	local x = (math.floor(spx) % imap_size)+1
	local y = (math.floor(spy) % imap_size)
	return y*imap_size+x
end

function move_orb_to_start_position()
	ORB.pos.x = HALF_GRID_SIZE
	ORB.pos.y = HALF_GRID_SIZE
end

function offset_background(x,y)
	LEVEL_OFFSET.x = LEVEL_OFFSET.x + x
	LEVEL_OFFSET.y = LEVEL_OFFSET.y + y
	BACKGROUND_SPRITE:markDirty()
end

function clear_background()
	lib_gfx.lockFocus(BACKGROUND_SPRITE:getImage())
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(0,0,SCREEN_WIDTH, SCREEN_HEIGHT)
	lib_gfx.unlockFocus()
end

function draw_debug_grid(level)
	if not level then level = CURRENT_LEVEL end
	local level_width = LEVEL_DATA.levels[CURRENT_LEVEL].w
	local level_height = LEVEL_DATA.levels[CURRENT_LEVEL].h
	local xoff = 100
	local yoff = 4

	local img = BACKGROUND_SPRITE:getImage()
	lib_gfx.lockFocus(img)
		-- draw to background sprite
		lib_gfx.setColor(lib_gfx.kColorWhite)
			for y = 0, level_height do
				lib_gfx.drawLine(
					xoff, 
					y * GRID_SIZE + yoff, 
					GRID_SIZE * level_width + xoff, 
					y * GRID_SIZE + yoff
				)
				for x = 0, level_width do
					lib_gfx.drawLine(
						x * GRID_SIZE + xoff, 
						yoff, 
						x * GRID_SIZE + xoff, 
						level_height * GRID_SIZE + yoff + 1
					)
				end
			end
		lib_gfx.setColor(lib_gfx.kColorXOR)
		lib_gfx.drawPixel( ORB.pos.x + xoff, ORB.pos.y + yoff )
	lib_gfx.unlockFocus()
	BACKGROUND_SPRITE:markDirty()
--	BACKGROUND_SPRITE.addDirtyRect(xoff, yoff, GRID_SIZE*level_width, GRID_SIZE*level_height)
end



-- algorithms / math

function degrees_to_vector(angle)
	local crankRads = math.rad(angle)
	local vx = math.sin(crankRads)
	local vy = -1 * math.cos(crankRads)
	return vx, vy
end

function rotate_vector( x, y, rad )
	if not rad then rad = -0.785398 end -- 45 degrees
	cos = math.cos(rad)
	sin = math.sin(rad)
	px = x * cos - y * sin
	py = x * sin + y * cos
	return px, py
end

function iso_to_grid(x, y, offsetx, offsety)
	if not offsetx then offsetx = 0 end
	if not offsety then offsety = 0 end
	x = x - LEVEL_OFFSET.x
	y = y - LEVEL_OFFSET.y
	local gx = x + y * 2 - offsetx --+ GRID_SIZE
	local gy = y * 2 - (x - offsetx) --+ GRID_SIZE
	return gx, gy
end

function grid_to_iso(x, y, offsetx, offsety)
	if not offsetx then offsetx = 0 end
	if not offsety then offsety = 0 end
	local ix = x-y + offsetx -- + LEVEL_OFFSET.x
	local iy = math.abs(x+y)/2 + offsety -- + LEVEL_OFFSET.y
	return ix, iy
end




-- buttons

function playdate.BButtonDown()
	if CURRENT_STATE == GAME_STATE.paused then return end
	if CURRENT_STATE == GAME_STATE.playing then 
		ORB.accelerate_flag = true 
	end
end


function playdate.BButtonUp()
	ORB.accelerate_flag = false
end

function playdate.AButtonDown()	
	if CURRENT_STATE == GAME_STATE.paused then return end
	if CURRENT_STATE == GAME_STATE.playing then 
		ORB.accelerate_flag = true 
		playdate.startAccelerometer()
	end
end

function playdate.AButtonUp()
	ORB.accelerate_flag = false
	playdate.stopAccelerometer()
end

function playdate.rightButtonDown()
	
end

function playdate.leftButtonDown()
	
end

function playdate.downButtonDown()
	DEBUG_FRAME_STEP = true
end

function playdate.upButtonDown()
	if (CURRENT_LEVEL < #LEVEL_DATA.levels) then
		CURRENT_LEVEL = CURRENT_LEVEL +1
	else
		CURRENT_LEVEL = 1
	end
	move_orb_to_start_position()
end
