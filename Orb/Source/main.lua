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
local LEVEL_DATA = playdate.datastore.read("Levels/levels")
local BACKGROUND_SPRITE = lib_spr.new()

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

	-- TODO: collision check

	-- set orb pos
	ORB.pos.x = next_pos.x
	ORB.pos.y = next_pos.y

	-- move sprite
	local isox, isoy = grid_to_iso(ORB.pos.x, ORB.pos.y, 0, 0)
	ORB.sprite:moveTo(isox, isoy + (ORB.altitude))
	local image_frame = get_orb_frame()
	ORB.sprite:setImage(ORB_IMAGE_TABLE:getImage( image_frame ))
end

function get_orb_frame()
	local imap_size = 5 -- the image map is 5 x 5 tiles
	local spx,spy = ORB.sprite:getPosition()
	local x = (math.floor(spx) % imap_size)+1
	local y = (math.floor(spy) % imap_size)
	return y*imap_size+x
end

function draw_level(level)
	if DEBUG_FLAG then
		draw_debug_grid(CURRENT_LEVEL)
	end
end

function draw_debug_grid(level)
	if not level then level = 1 end
	local level_width = LEVEL_DATA.levels[CURRENT_LEVEL].width
	local level_height = LEVEL_DATA.levels[CURRENT_LEVEL].height
	local xoff = 130
	local yoff = 4

	local img = BACKGROUND_SPRITE:getImage()
	lib_gfx.lockFocus(img)
		-- draw to background sprite
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(0,0,SCREEN_WIDTH, SCREEN_HEIGHT)
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

function iso_to_grid(x, y, offx, offy)
	local gx = p.x + p.y * 2 - offx + GRID_SIZE
	local gy = p.y * 2 - (p.x - offx) + GRID_SIZE
	return gx, gy
end

function grid_to_iso(x,y , offx, offy)
	local ix = x-y + offx
	local iy = math.abs(x+y) + offy
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