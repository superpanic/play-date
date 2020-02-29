import "CoreLibs/graphics"
import "CoreLibs/sprites"

-- global vars:
lib_gfx = playdate.graphics
lib_spr = playdate.graphics.sprite

playdate.display.setRefreshRate(30)
playdate.display.setScale(2)
lib_gfx.setBackgroundColor(lib_gfx.kColorBlack)
lib_gfx.clear()

local DEBUG_FLAG = true
local DEBUG_STRING = ""

local SCREEN_WIDTH = playdate.display.getWidth()
local SCREEN_HEIGHT = playdate.display.getHeight()

local GRID_SIZE = 16

-- state vars
local GAME_STATE = {
	initial = 1, 
	ready   = 2, 
	playing = 3, 
	paused  = 4, 
	over    = 5
}

local CURRENT_STATE = GAME_STATE.initial

-- ORB vars
local ORB = {}
local ORB_IMAGE_TABLE = lib_gfx.imagetable.new('Artwork/ORB')

-- level vars
local CURRENT_LEVEL = 1
local BACKGROUND_SPRITE = lib_spr.new()
local TILE_IMAGES = lib_gfx.imagetable.new('Artwork/level_tiles')
local LEVEL_DATA = playdate.datastore.read("Levels/levels")
	print(LEVEL_DATA.description)
local TILE_DATA = playdate.datastore.read("Levels/tiles")
	print(TILE_DATA.description)

local LEVEL_OFFSET = {x=0,y=0}


function new_game_object(name, sprite, pos)
	local obj ={}
	obj.name = name
	obj.sprite = sprite
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
	
	return obj
end

function playdate.update()
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
		lib_spr.update() -- update all sprites
		
	elseif CURRENT_STATE == GAME_STATE.paused then
		paused()


	end
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
	ORB.sprite:moveTo(ORB.pos.x, ORB.pos.y)
	ORB.sprite:setZIndex(1000)
	ORB.sprite:add()
	
-- background as a sprite
	local bg_img = lib_gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)
	lib_gfx.lockFocus(bg_img)
		lib_gfx.setColor(lib_gfx.kColorBlack)
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

function update_orb()
	-- get current direction
	local vectorx, vectory = degrees_to_vector( playdate.getCrankPosition() )

	if ORB.accelerate_flag then
		ORB.x_velocity = ORB.x_velocity + (vectorx * ORB.acceleration)
		ORB.y_velocity = ORB.y_velocity + (vectory * ORB.acceleration)
	end

	ORB.x_velocity = ORB.x_velocity * ORB.friction
	ORB.y_velocity = ORB.y_velocity * ORB.friction

	-- set next pos
	local next_pos = {}
	next_pos.x = ORB.pos.x + ORB.x_velocity
	next_pos.y = ORB.pos.y + ORB.y_velocity

	-- TODO: collision check here!

	-- set orb pos
	ORB.pos.x = next_pos.x
	ORB.pos.y = next_pos.y

	-- move sprite
	local isox, isoy = grid_to_iso(ORB.pos.x, ORB.pos.y, 0, 0)
	-- offset orb half image height
	isoy = isoy - select(1,ORB.sprite:getImage():getSize())/2

	ORB.sprite:moveTo(isox, isoy + (ORB.altitude))
	local image_frame = get_orb_frame()
	ORB.sprite:setImage(ORB_IMAGE_TABLE:getImage( image_frame ))
	if DEBUG_FLAG then
		DEBUG_STRING = (
			"x:"..string.format("%03d",math.floor(ORB.pos.x + 0.5))..
			" y:"..string.format("%03d",math.floor(ORB.pos.y + 0.5))
		)
	end
end

function get_orb_frame()
	local imap_size = 5 -- the image map is 5 x 5 tiles
	local spx,spy = ORB.sprite:getPosition()
	local x = (math.floor(spx) % imap_size)+1
	local y = (math.floor(spy) % imap_size)
	return y*imap_size+x
end

function clear_background()
	lib_gfx.lockFocus(BACKGROUND_SPRITE:getImage())
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(0,0,SCREEN_WIDTH, SCREEN_HEIGHT)
	lib_gfx.unlockFocus()
end

function draw_level(level)
	if not level then level = 1 end
	
	clear_background()

	local w = LEVEL_DATA.levels[level].w 
	local h = LEVEL_DATA.levels[level].h
	
	local print_flag = false

	for y = 1, h do
		for x = 1, w do
			local index = w * (y-1) + x
			local tile = LEVEL_DATA.levels[level].tiles[index]
			local height_offset = LEVEL_DATA.levels[level].heights[index]
			
			-- calculate tile screen position
			local isox, isoy = grid_to_iso( (x-1) * GRID_SIZE, (y-1) * GRID_SIZE)
			-- add tile image offset
			isox = isox + TILE_DATA.tiles[tile].xoffset
			isoy = isoy + TILE_DATA.tiles[tile].yoffset
			-- add latitude offset
			isoy = isoy - height_offset

			local image = TILE_IMAGES:getImage(tile)
			lib_gfx.lockFocus(BACKGROUND_SPRITE:getImage())
				image:drawAt(isox,isoy)
			lib_gfx.unlockFocus()
		end
	end

	if DEBUG_FLAG then
		draw_debug_grid(CURRENT_LEVEL)
	end
end

function draw_debug_grid(level)
	if not level then level = 1 end
	local level_width = LEVEL_DATA.levels[CURRENT_LEVEL].w
	local level_height = LEVEL_DATA.levels[CURRENT_LEVEL].h
	local xoff = 130
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
		lib_gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
		lib_gfx.drawText(DEBUG_STRING, 10, SCREEN_HEIGHT-22)
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

function iso_to_grid(x, y, offsetx, offsety)
	if not offsetx then offsetx = 0 end
	if not offsety then offsety = 0 end
	x = x - LEVEL_OFFSET.x
	y = y - LEVEL_OFFSET.y
	local gx = x + y * 2 - offsetx + GRID_SIZE
	local gy = y * 2 - (x - offsetx) + GRID_SIZE
	return gx, gy
end

function grid_to_iso(x, y, offsetx, offsety)
	if not offsetx then offsetx = 0 end
	if not offsety then offsety = 0 end
	local ix = x-y + offsetx + LEVEL_OFFSET.x
	local iy = math.abs(x+y)/2 + offsety + LEVEL_OFFSET.y
	return ix, iy
end



-- buttons

function playdate.BButtonDown()
	if current_state == GAME_STATE.paused then return end
	ORB.accelerate_flag = true
end

function playdate.BButtonUp()
	if current_state == GAME_STATE.paused then return end
	ORB.accelerate_flag = false
end

function playdate.rightButtonDown()
	LEVEL_OFFSET.x = LEVEL_OFFSET.x+10
end

function playdate.leftButtonDown()
	LEVEL_OFFSET.x = LEVEL_OFFSET.x-10
end

function playdate.downButtonDown()
	LEVEL_OFFSET.y = LEVEL_OFFSET.y+10
end

function playdate.upButtonDown()
	LEVEL_OFFSET.y = LEVEL_OFFSET.y-10
end
