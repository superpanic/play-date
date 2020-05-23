import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "Utils/fps"
print("using outdated CoreLibs/utilities/fps library")
--playdate.setCollectsGarbage(false)
import "audio"

-- local vars:
local lib_gfx = playdate.graphics
local lib_spr = playdate.graphics.sprite
local lib_tim = playdate.timer

playdate.display.setRefreshRate(30)
playdate.display.setScale(2)
lib_gfx.setBackgroundColor(lib_gfx.kColorBlack)
lib_gfx.clear()

local DEBUG_FLAG = true
local DEBUG_STRING = "debug mode"
local DEBUG_VAL = 0.0

local DEBUG_STEP_FRAME = false
local DEBUG_FRAME_STEP = false
local DEBUG_FRAME_COUNTER = 0

-- GLOBALS

-- full screen size
local SCREEN_WIDTH  = playdate.display.getWidth()
local SCREEN_HEIGHT = playdate.display.getHeight()

-- game world area size
local GAME_AREA_WIDTH  = SCREEN_WIDTH - 32
local GAME_AREA_HEIGHT = SCREEN_HEIGHT

local GRID_SIZE = 16
local HALF_GRID_SIZE = GRID_SIZE / 2

local INFINITY_FLOOR_ALTITUDE = -1000
local ALTITUDE_LIMIT = -500
local EDGE_COLLISION_HEIGHT = 4

local CRANK_VECTOR = {x=0, y=0}
local SINE_LUT = {}
local COSINE_LUT = {}

local VECTOR_LUT_X = {}
local VECTOR_LUT_Y = {}

local FRICTION = 0.92
local GRAVITY = 0.75

-- state vars
local GAME_STATE = {
	initial  = 1, 
	setup    = 2,
	menu     = 3,
	ready    = 4, 
	playing  = 5, 
	paused   = 6, 
	goal     = 7,
	gameover = 8,
	cleanup  = 9
}

local CURRENT_STATE = GAME_STATE.initial

local MENU_SELECT_COUNTER = 1
local MENU_DATA = playdate.datastore.read("Json/menu")
	print(MENU_DATA.loadmessage) -- to make sure the json is readable

-- ORB vars
local ORB = {}
local ORB_IMAGE_TABLE = lib_gfx.imagetable.new('Artwork/orb')
local ORB_FX_IMAGE_TABLE = lib_gfx.imagetable.new('Artwork/orb_fx')

--[[ NUMBER_OF_SPRITE_LAYERS is the number 
	of layers used for game sprite objects. 
	each game sprite object uses: 
	one IMAGE sprite 
	one EFFECT sprite 
	one MASK sprite
	therefore the z-index has to be multiplied 
	with NUMBER_OF_SPRITE_LAYERS ]]--
local NUMBER_OF_SPRITE_LAYERS = 3

-- game
local GAME_TIMER = 0
local GAME_TIME_STAMP = 0

-- audio
local AUDIO_FX = new_audio_fx_player()
--local MUSIC_PLAYER = new_music_player()

-- interface
local INTERFACE_IMAGE = lib_gfx.image.new("Artwork/interface.png")
local INTERFACE_SPRITE = {}
local INTERFACE_FONT = playdate.graphics.loadFont("Fonts/orb_font")
lib_gfx.setFont(INTERFACE_FONT)

-- level vars
local CURRENT_LEVEL = 1
local BACKGROUND_SPRITE = {} 
local LEVEL_IMAGE_WIDTH = 1024
local LEVEL_IMAGE_HEIGHT = 512
local TILE_IMAGES = lib_gfx.imagetable.new('Artwork/level_tiles')
local LEVEL_DATA = playdate.datastore.read("Json/levels")
	print(LEVEL_DATA.loadmessage) -- to make sure the json is readable
local TILE_DATA = playdate.datastore.read("Json/tiles")
	print(TILE_DATA.loadmessage) -- to make sure the json is readable

local LEVEL_OFFSET = { floatx=60.0, floaty=20.0, x=60, y=20, velx=0, vely=0, drawy=0 }

local LEVEL_ITEMS = {}
local LEVEL_ITEMS_IMAGE_TABLE = lib_gfx.imagetable.new('Artwork/items')
local ITEM_DATA = playdate.datastore.read("Json/items")
	print(ITEM_DATA.loadmessage) -- to make sure the json is readable


local SMALL_ART_DATA = playdate.datastore.read("Json/small_art")
	print(SMALL_ART_DATA.loadmessage) -- to make sure the json is readable



-- classes
function new_level_item(id, x, y, x_off, y_off, size, collidable, frames, update_func, action_func)
	local obj = {}

	obj.id = id -- type of item
	
	obj.frame_list = frames
	obj.current_frame = 1

	obj.collidable = collidable
	obj.size = size

	obj.sprite = lib_spr.new()
	obj.sprite:setImage(LEVEL_ITEMS_IMAGE_TABLE:getImage(obj.frame_list[obj.current_frame]))
	
	obj.x = ((x-1) * GRID_SIZE)+GRID_SIZE/2
	obj.y = ((y-1) * GRID_SIZE)+GRID_SIZE/2
	obj.x_off = x_off
	obj.y_off = y_off
	obj.altitude = get_altitude_at_pos(math.floor(obj.x+0.5), math.floor(obj.y+0.5))
	print("item altitude: "..obj.altitude)

	local isox, isoy = grid_to_iso(obj.x, obj.y, 0, 0)
	obj.isox = isox
	obj.isoy = isoy
	
	print(obj.isox, obj.isoy)

	obj.sprite:setZIndex(isoy * NUMBER_OF_SPRITE_LAYERS) 
	print(obj.sprite:getZIndex())
	
	obj.sprite:add()
	--obj.sprite:setVisible(false)
	
	obj.action = action

	obj.collision_distance = collision_radius -- not really radius, instead a square

	obj.collision_check = function(x, y)
		if not collidable then return false end
		local cd = obj.size
		if x > obj.x-cd and x < obj.x+cd and y > obj.y-cd and y < obj.y+cd then
			return true
		end
		return false
	end

	obj.update = update_func -- call function using: _G[obj.update](obj)
	obj.action = action_func -- call function using: _G[obj.action](obj)

	obj.do_update = function()
		-- run updates
		if obj.update then _G[obj.update](obj) end
		-- update position
		local isox = math.floor(obj.isox + LEVEL_OFFSET.x + 0.5) + obj.x_off
		local isoy = math.floor(obj.isoy + LEVEL_OFFSET.y + 0.5) + obj.y_off
		obj.sprite:moveTo(isox, isoy - obj.altitude)
	end

	obj.do_action = function()
		if obj.action then _G[obj.action](obj) end
	end

	obj.set_z_index = function(z)
		obj.sprite:setZIndex(z)
	end

	return obj
end

function new_game_sprite(name, sprite, pos)
	local obj ={}
	obj.name = name
	obj.sprite = sprite
	
	obj.sprite_effect = lib_spr.new()
	local img = lib_gfx.image.new(GRID_SIZE*2, GRID_SIZE*2) -- might be too small for larger objects
	obj.sprite_effect:setImage(img)
	obj.sprite_effect:add()

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
	obj.falling = false
	
	obj.print_name = function() 
		print(obj.name) 
	end

	obj.set_z_index = function(z)
		z = z * NUMBER_OF_SPRITE_LAYERS
		obj.sprite:setZIndex(z)
		obj.sprite_effect:setZIndex(z+1)
		obj.sprite_cover:setZIndex(z+2)
	end

	obj.get_z_index = function()
		return obj.sprite:getZIndex()
	end
	
	return obj
end

function setup()

	generate_vector_LUT()

-- orb (player sprite)
	local orb_img = ORB_IMAGE_TABLE:getImage(13)
	local orb_sprite = lib_spr.new()
	orb_sprite:setImage(orb_img)
	local orb_pos = {}
	orb_pos.x = 0.0
	orb_pos.y = 0.0
	ORB = new_game_sprite("ORB", orb_sprite, orb_pos)
	ORB.print_name()
	move_orb_to_start_position()
	--ORB.sprite:moveTo(ORB.pos.x, ORB.pos.y)
	ORB.set_z_index(0)
	ORB.sprite:add()

-- background as a sprite
	BACKGROUND_SPRITE = lib_spr.new()
	local bg_img = lib_gfx.image.new(LEVEL_IMAGE_WIDTH, LEVEL_IMAGE_HEIGHT)	
	lib_gfx.lockFocus(bg_img)
		lib_gfx.setColor(lib_gfx.kColorClear)
		lib_gfx.fillRect(0,0,GAME_AREA_WIDTH,GAME_AREA_HEIGHT)
	lib_gfx.unlockFocus()
	BACKGROUND_SPRITE:setImage(bg_img)
	BACKGROUND_SPRITE:moveTo(GAME_AREA_WIDTH/2,SCREEN_HEIGHT/2)
	BACKGROUND_SPRITE:setZIndex(-10000)
	BACKGROUND_SPRITE:add()

-- interface
	INTERFACE_SPRITE = lib_spr.new()
	INTERFACE_SPRITE:setImage(INTERFACE_IMAGE)
	INTERFACE_SPRITE:moveTo(GAME_AREA_WIDTH+16,SCREEN_HEIGHT/2)
	INTERFACE_SPRITE:setZIndex(2000)
	INTERFACE_SPRITE:add()
	
-- reset crank
	playdate.getCrankChange()
	return
end


-- update
function playdate.update()

	if DEBUG_FLAG and DEBUG_STEP_FRAME then
		if not DEBUG_FRAME_STEP then return end
	end

	if CURRENT_STATE == GAME_STATE.initial then
		CURRENT_STATE = GAME_STATE.menu
		--MUSIC_PLAYER.play_title(true)


	-- menu loop
	elseif CURRENT_STATE == GAME_STATE.menu then
		-- draw menu
		menu()


	elseif CURRENT_STATE == GAME_STATE.setup then
		-- is a game already running? then return to it
		-- no game running, setup a new game
		print("setup")
		print("fps:", playdate.display.getRefreshRate())
		--MUSIC_PLAYER.stop_title()
		setup()
		CURRENT_STATE = GAME_STATE.ready

	elseif CURRENT_STATE == GAME_STATE.ready then
		print("start")
		draw_level()
		add_items()
		offset_background()
		GAME_TIME_STAMP = playdate.getCurrentTimeMilliseconds()
		CURRENT_STATE = GAME_STATE.playing
		

	-- main game loop
	elseif CURRENT_STATE == GAME_STATE.playing then
		update_orb()
		update_items()
		offset_background()
		update_level_offset()
		draw_interface()
		end_level_check()
		update_game_timer()
		lib_spr.update() -- update all sprites
		playdate.drawFPS(10, SCREEN_HEIGHT-20)

	elseif CURRENT_STATE == GAME_STATE.goal then
		level_clear()
		update_orb()
		update_items()
		offset_background()
		update_level_offset()
		draw_interface()
		lib_spr.update() -- update all sprites

	elseif CURRENT_STATE == GAME_STATE.dead then
		update_orb()
		update_items()
		offset_background()
		update_level_offset()
		draw_interface()
		lib_spr.update() -- update all sprites
		if game_over_check() then
			CURRENT_STATE = GAME_STATE.gameover
		end

	elseif CURRENT_STATE == GAME_STATE.gameover then
		update_orb()
		update_items()
		offset_background()
		update_level_offset()
		draw_interface()
		lib_spr.update() -- update all sprites

	elseif CURRENT_STATE == GAME_STATE.paused then
		paused()

	elseif CURRENT_STATE == GAME_STATE.cleanup then
		cleanup()
		CURRENT_STATE = GAME_STATE.setup
	end

	lib_tim.updateTimers()

	if DEBUG_FLAG then
		DEBUG_FRAME_STEP = false
		DEBUG_FRAME_COUNTER = DEBUG_FRAME_COUNTER + 1
		lib_gfx.setImageDrawMode(lib_gfx.kDrawModeFillWhite)
		lib_gfx.drawText(DEBUG_STRING, 5, 5)
		lib_gfx.drawText(tostring(DEBUG_VAL), 5, 20)
		lib_gfx.setImageDrawMode(lib_gfx.kDrawModeCopy)
	end
	
end

function cleanup()
	-- sprites
	print(" cleaning up, active sprites: ".. lib_spr.spriteCount())
	if not ORB.sprite then return end
	ORB.sprite:remove()
	ORB.sprite_cover:remove()
	ORB = {}
	if not BACKGROUND_SPRITE then return end
	BACKGROUND_SPRITE:remove()
	BACKGROUND_SPRITE = {}
	INTERFACE_SPRITE:remove()
	INTERFACE_SPRITE = {}
	if LEVEL_ITEMS and #LEVEL_ITEMS > 0 then
		for i = 1,#LEVEL_ITEMS do
			LEVEL_ITEMS[i].sprite:remove()
			LEVEL_ITEMS[i].sprite = nil
		end
		LEVEL_ITEMS = nil 
	end
	print("   all clear, active sprites: ".. lib_spr.spriteCount())
	-- vars
	LEVEL_OFFSET = { floatx=60.0, floaty=20.0, x=60, y=20, velx=0, vely=0, drawy=0 }
end

function add_items()
	-- clear level objects
	LEVEL_ITEMS = {}

	-- read level data
	local items = LEVEL_DATA.levels[CURRENT_LEVEL].items
	if not items then return end
	if #items == 0 then return end
	
	--print("item name: "..items[1].name)
	for i = 1,#items do
		local item = items[i]
		local item_data = ITEM_DATA.items[item.id]
		LEVEL_ITEMS[i] = new_level_item(item.id, item.x, item.y, item_data.xoffset, item_data.yoffset, item_data.size, item_data.collidable, item_data.frames, item_data.update_func, item_data.action_func)
		print("type:"..item.type)
	end
end

function update_items()
	if #LEVEL_ITEMS == 0 then return end
	for i = 1,#LEVEL_ITEMS do
		local item = LEVEL_ITEMS[i]
		item.do_update()
	end
end

function menu()
	-- loop throught json menu data structure and print to screen
	for index = 1, #MENU_DATA.menu do
		if index == MENU_SELECT_COUNTER then lib_gfx.setImageDrawMode(lib_gfx.kDrawModeNXOR)
		else lib_gfx.setImageDrawMode(lib_gfx.kDrawModeFillWhite) end
		lib_gfx.drawText(MENU_DATA.menu[index].name, 55, 10+20*index)
	end
	lib_gfx.setImageDrawMode(lib_gfx.kDrawModeCopy)
end

function update_game_timer()
	GAME_TIMER = (LEVEL_DATA.levels[CURRENT_LEVEL].time * 1000) - (playdate.getCurrentTimeMilliseconds() - GAME_TIME_STAMP)
end

function new_game()
	print("new game")
	CURRENT_STATE = GAME_STATE.setup
end

function continue()
	print("continue")
	-- TODO:
end

function level_clear()
	add_friction(0.75)
end

function game_over_check()
	-- nothing (yet)
	return false
end



-- interface
function draw_interface()
	local s = ""
	local px = 0
	local py = 0
	local ox = 0 -- offset all x
	local oy = 0 -- offset all y
	lib_gfx.lockFocus(INTERFACE_SPRITE:getImage())
	-- crank circle
		px = 17 + ox
		py = 83 + oy
		lib_gfx.setColor(lib_gfx.kColorWhite)
		lib_gfx.fillCircleAtPoint(px, py, 11)
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.setLineWidth(2)
		lib_gfx.setLineCapStyle(lib_gfx.kLineCapStyleRound)
		lib_gfx.drawLine( px, py, px + (CRANK_VECTOR.x * 12), py + (CRANK_VECTOR.y * 12))
	-- game timer
		px = 32 + ox
		py = 35 + oy
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(px-30, py, px-2, 5)
		lib_gfx.setImageDrawMode(lib_gfx.kDrawModeFillWhite)
		s = string.format("%02.2f", math.max(GAME_TIMER/1000, 0.0))
		lib_gfx.drawTextAligned(s, px, py, kTextAlignment.right)
	-- score
		px = 32 + ox
		py = 53 + oy
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(px-30, py, px-2, 5)
		lib_gfx.setImageDrawMode(lib_gfx.kDrawModeFillWhite)
		s = string.format("%06d", 55)
		lib_gfx.drawTextAligned(s, px, py, kTextAlignment.right)
	-- speed meter
		-- px = 3 + ox
		-- py = 71 + oy
		-- lib_gfx.setColor(lib_gfx.kColorBlack)
		-- lib_gfx.fillRect(px,py,27,5)
		-- lib_gfx.setColor(lib_gfx.kColorWhite)
		-- lib_gfx.fillRect( px, py, math.min( 27, (math.abs(ORB.x_velocity)+math.abs(ORB.y_velocity)+ORB.fall_velocity)*6 ), 5 )
	-- alt meter
		px = 32 + ox
		py = 109 + oy
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(px-30, py, px-2, 5)
		lib_gfx.setImageDrawMode(lib_gfx.kDrawModeFillWhite)
		s = string.format("%03.1f", ORB.altitude)
		lib_gfx.drawTextAligned(s, px, py, kTextAlignment.right)
		--INTERFACE_FONT:drawText(ORB.altitude,110)
		--lib_gfx.drawText("text", 10, 10)
	lib_gfx.unlockFocus()
	INTERFACE_SPRITE:markDirty()
end

function end_level_check()
	-- goal check
	if ( get_tile_at( math.floor(ORB.pos.x+0.5), math.floor(ORB.pos.y+0.5) ).type == "goal" ) then 
		-- do an altitude check (to see if we are really standing on the goal plate)
		if ( ORB.altitude == get_altitude_at_pos(ORB.pos.x, ORB.pos.y) ) then
			CURRENT_STATE = GAME_STATE.goal
			ORB.accelerate_flag = false
			print("goal!")
		end
		return
	end

	-- if ORB.altitude <= ALTITUDE_LIMIT then
	-- 	ORB.x_velocity = 0
	-- 	ORB.y_velocity = 0
	-- 	ORB.accelerate_flag = false
	-- 	print("game over, altitude limit reached!")
	-- 	CURRENT_STATE = GAME_STATE.dead
	-- 	return
	-- end
end

function add_friction(f)
	if math.abs(ORB.x_velocity) < 0.001 then ORB.x_velocity = 0 else
		ORB.x_velocity = ORB.x_velocity * f
	end
	if math.abs(ORB.y_velocity) < 0.001 then ORB.y_velocity = 0 else
		ORB.y_velocity = ORB.y_velocity * f
	end
end

-- update orb
function update_orb()
	
	local vectorx, vectory, vectorz
	if playdate.accelerometerIsRunning() then
		-- ACCELEROMETER controls direction
		vectorx, vectory, vectorz = playdate.readAccelerometer()
		vectory = vectory - 0.5
		vectorx, vectory = rotate_vector(vectorx, vectory) -- rotate 45 degrees
		vectorx = vectorx * 4
		vectory = vectory * 4
		if DEBUG_FLAG then DEBUG_STRING = string.format("x:%.2f, y:%.2f", vectorx, vectory) end
	else
		-- CRANK controls direction
		local crank_pos = playdate.getCrankPosition()
		CRANK_VECTOR.x, CRANK_VECTOR.y = degrees_to_vector_lut( crank_pos )
		vectorx, vectory = degrees_to_vector_lut( crank_pos - 45 )
		vectorx = vectorx * 1.5
		vectory = vectory * 1.5
	end
	
	if CURRENT_STATE == GAME_STATE.playing then
		if ORB.accelerate_flag then
			ORB.x_velocity = ORB.x_velocity + (vectorx * ORB.acceleration)
			ORB.y_velocity = ORB.y_velocity + (vectory * ORB.acceleration)
		end

		add_friction(ORB.friction)

		check_special_tiles(ORB)

		-- set next pos
		local next_pos = {}
		next_pos.x = ORB.pos.x + ORB.x_velocity
		next_pos.y = ORB.pos.y + ORB.y_velocity

		local collision_detected = false
		collision_detected = wall_collision_check(ORB, next_pos.x, next_pos.y)
		collision_detected = collision_detected or item_collision_check(ORB, next_pos.x, next_pos.y)

		-- if we did not collide with anything move orb
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
			print(ORB.fall_velocity)
			ORB.altitude = math.max(alt, ORB.altitude - ORB.fall_velocity)
			if ORB.fall_velocity > GRAVITY * 3 then -- are we falling or just rolling?
				ORB.falling = true
			end
		else
			if ORB.falling then
				-- did we fall too hard?
				if ORB.fall_velocity > GRAVITY * 5 then
					AUDIO_FX.play_crash()
					CURRENT_STATE = GAME_STATE.dead
					-- play death animation
					-- TODO: temporary solution:
					ORB.sprite:setImage(ORB_FX_IMAGE_TABLE:getImage(3))
					print("dead!")
				else
					-- we survived the fall
					ORB.falling = false
					AUDIO_FX.play_fall(alt)
				end
			end
			ORB.altitude = alt
			ORB.fall_velocity = 0
		end
		
		-- add slope velocity
		local slope_vx, slope_vy = get_slope_vector(ORB.pos.x, ORB.pos.y, ORB.altitude)
		ORB.x_velocity = ORB.x_velocity - slope_vx
		ORB.y_velocity = ORB.y_velocity - slope_vy

	end



	-- move sprite
	local isox, isoy = grid_to_iso(ORB.pos.x, ORB.pos.y, 0, 0)
	-- offset orb half image height
	isoy = isoy - HALF_GRID_SIZE -- select(1,ORB.sprite:getImage():getSize())/2

	-- set z index before adding offsets
	ORB.set_z_index(isoy)

	-- floor value to sync with background movement
	isox = math.floor( isox + LEVEL_OFFSET.x + 0.5 )
	isoy = math.floor( isoy - ORB.altitude + LEVEL_OFFSET.y + 0.5 )

	ORB.sprite:moveTo(isox, isoy)



	if CURRENT_STATE == GAME_STATE.playing then
		local image_frame = get_orb_frame()
		ORB.sprite:setImage(ORB_IMAGE_TABLE:getImage( image_frame ))
	end
	z_mask_update(ORB)

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

-- draw level
function draw_level(level)
	if not level then level = CURRENT_LEVEL end

	local w = LEVEL_DATA.levels[level].w 
	local h = LEVEL_DATA.levels[level].h

	print("loading "..LEVEL_DATA.levels[level].name)
	if not (w*h == #LEVEL_DATA.levels[level].tiles) and not (w*h == #LEVEL_DATA.levels[level].altitude) then 
		print("defined level length wrong!") 
		return 
	end

	local index, tile, height_offset = 0
	local isox, isoy
	local draw_limit = GRID_SIZE * 2

	-- reset draw y offset
	-- 1. draw tiles at positive offset
	-- 2. move babckground to negative offset
	-- 3. don't move sprites at all!

	local draw_offset = 0
	for y = 1, h do
		for x = 1, w do
			index = w * (y-1) + x
			tile = LEVEL_DATA.levels[level].tiles[index]
			height_offset = LEVEL_DATA.levels[level].altitude[index]
			-- calculate tile screen position
			isox, isoy = grid_to_iso( (x-1) * GRID_SIZE, (y-1) * GRID_SIZE)
			isoy = isoy + TILE_DATA.tiles[tile].yoffset
			-- add latitude offset
			isoy = isoy - height_offset
			if isoy < draw_offset then draw_offset = isoy end
		end
	end
	
	LEVEL_OFFSET.drawy = -(math.ceil(draw_offset+GRID_SIZE))

	lib_gfx.lockFocus(BACKGROUND_SPRITE:getImage())
	for y = 1, h do
		for x = 1, w do
			index = w * (y-1) + x
			tile = LEVEL_DATA.levels[level].tiles[index]
			height_offset = LEVEL_DATA.levels[level].altitude[index]
			
			-- calculate tile screen position
			isox, isoy = grid_to_iso( (x-1) * GRID_SIZE, (y-1) * GRID_SIZE)			

			isox = isox + TILE_DATA.tiles[tile].xoffset
			isoy = isoy + TILE_DATA.tiles[tile].yoffset
			
			-- start drawing at center x of image
			isox = isox + LEVEL_IMAGE_WIDTH / 2
			
			-- add latitude offset
			isoy = isoy - height_offset + LEVEL_OFFSET.drawy

			-- draw image
			TILE_IMAGES:getImage(tile):drawAt(isox,isoy)
		end
	end
	lib_gfx.unlockFocus()
	BACKGROUND_SPRITE:markDirty()
end

function update_level_offset()
	LEVEL_OFFSET.velx = LEVEL_OFFSET.velx * FRICTION
	LEVEL_OFFSET.vely = LEVEL_OFFSET.vely * FRICTION

	local orb_x, orb_y = ORB.sprite:getPosition()
	if orb_x < GRID_SIZE * 3 then LEVEL_OFFSET.velx = LEVEL_OFFSET.velx + 0.5 end
	if orb_x > GAME_AREA_WIDTH - GRID_SIZE * 3 then LEVEL_OFFSET.velx = LEVEL_OFFSET.velx - 0.5 end
	if orb_y < GRID_SIZE * 2 then LEVEL_OFFSET.vely = LEVEL_OFFSET.vely + 0.5 end
	if orb_y > GAME_AREA_HEIGHT - GRID_SIZE * 2 then LEVEL_OFFSET.vely = LEVEL_OFFSET.vely - 0.5 end

	offset_level(LEVEL_OFFSET.velx, LEVEL_OFFSET.vely)
end

function offset_background()
	local y = math.floor(LEVEL_IMAGE_HEIGHT/2+LEVEL_OFFSET.y-LEVEL_OFFSET.drawy+0.5)
	BACKGROUND_SPRITE:moveTo(LEVEL_OFFSET.x, y)
end

-- z mask
function z_mask_update(obj)	
	
	z_mask_reset(obj)

	local w = LEVEL_DATA.levels[CURRENT_LEVEL].w
	local h = LEVEL_DATA.levels[CURRENT_LEVEL].h

	local index, tile, tile_altitude = 0
	local tile_isox, tile_isoy

	local px = math.floor(obj.pos.x + 0.5)
	local py = math.floor(obj.pos.y + 0.5)

	local obj_col = math.floor(px / GRID_SIZE) + 1
	local obj_row = math.floor(py / GRID_SIZE) + 1
	
	-- if outside return - outside on zero-side (top and left) should be covered though
	if obj_col > w or obj_row > h then return end	

	DEBUG_STRING = string.format( "%02d/%02d  (%03d/%03d)", obj_col, obj_row, math.floor(obj.pos.x+1+0.5), math.floor(obj.pos.y+1+0.5) )

	-- checking 16 tiles; from standing tile and 4 tiles down and right
	lib_gfx.lockFocus(obj.sprite_cover:getImage())
		for row = math.max(1,obj_row), math.min(h,obj_row+3) do
			for col = math.max(1,obj_col), math.min(w,obj_col+3) do
				repeat
					index = w * (row-1) + col

					tile = LEVEL_DATA.levels[CURRENT_LEVEL].tiles[index]
					tile_altitude = LEVEL_DATA.levels[CURRENT_LEVEL].altitude[index]

					tile_isox, tile_isoy = grid_to_iso( (col-1) * GRID_SIZE, (row-1) * GRID_SIZE)					
					tile_isox = tile_isox + TILE_DATA.tiles[tile].xoffset + LEVEL_OFFSET.x
					tile_isoy = tile_isoy + TILE_DATA.tiles[tile].yoffset - tile_altitude + LEVEL_OFFSET.y
					tile_isox = math.floor(tile_isox+0.5)
					tile_isoy = math.floor(tile_isoy+0.5)
					
					local image = TILE_IMAGES:getImage(tile)
					
					-- check 1: are we standing on this tile?
					if obj_col == col and obj_row == row then
						do break end -- do not mask if orb is standing on tile!
					end
					
					-- check 2: is tile to the left or above (up) the orb? then return
					if col < obj_col or row < obj_row then 
						do break end
					end

					-- check 3: is tile lower or same altitude as obj?
					local alt_diff = tile_altitude - obj.altitude
					if alt_diff <= 0 then -- earlier value was not 0 but HALF_GRID_SIZE
						do break end 
					end 

					-- ok, assume the tile is covering the object
					local objx, objy = obj.sprite:getPosition() -- screen position
					objx = objx - GRID_SIZE
					objy = objy - GRID_SIZE

					-- add special cases (like slopes) here --
					image:drawAt( tile_isox - objx, tile_isoy - objy )
				until true
			end
		end
	lib_gfx.unlockFocus()
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


-- collision
function item_collision_check(obj, nextx, nexty)
	if not LEVEL_ITEMS or #LEVEL_ITEMS == 0 then return false end
	for _, item in ipairs(LEVEL_ITEMS) do
		if item.collision_check(nextx,nexty) then
			-- also do an altitude chack, are we below the item?
			local alt = get_altitude_at_pos(math.floor(obj.pos.x+0.5), math.floor(obj.pos.y+0.5))
			if alt > item.altitude - GRID_SIZE/2 then
				-- we have a collision!
				obj.x_velocity = -obj.x_velocity*0.5
				obj.y_velocity = -obj.y_velocity*0.5
				item.do_action()
				AUDIO_FX.play_switch()
				return true
			end
		end
	end
	return false
end

function wall_collision_check(obj, nextx, nexty)
	-- collision if altitude is higher than EDGE_COLLISION_HEIGHT pixels
	
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
	
	AUDIO_FX.play_collide()

	return true
end


function check_special_tiles(obj)
	local t = get_tile_at( obj.pos.x, obj.pos.y )
	if t.type == "boost" then
		-- boost tiles with arrows increases velocity
		obj.x_velocity = obj.x_velocity + t.value[1];
		obj.y_velocity = obj.y_velocity + t.value[2];
	end 
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
	return get_tile_at(x,y).type
end

function get_tile_at( x, y )
	if x < 0 or y < 0 then return "oob" end -- out of bounds
	local w = LEVEL_DATA.levels[CURRENT_LEVEL].w
	local h = LEVEL_DATA.levels[CURRENT_LEVEL].h
	if x >= w * GRID_SIZE or y >= h * GRID_SIZE then return "oob" end -- out of bounds

	local tilex = math.floor((x / GRID_SIZE))+1
	local tiley = math.floor((y / GRID_SIZE))+1
	local tile_index = w * (tiley-1) + tilex
	local tile_type = LEVEL_DATA.levels[CURRENT_LEVEL].tiles[tile_index]
	return TILE_DATA.tiles[tile_type]
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

	-- check if this is an empty hole tile:
	if TILE_DATA.tiles[tile_type].type == "hole" then return INFINITY_FLOOR_ALTITUDE end

	-- find local tile altitude
	local tile_heightmap_x = math.floor( (x - GRID_SIZE * (tilex-1) ))+1
	local tile_heightmap_y = math.floor( (y - GRID_SIZE * (tiley-1) ))+1

	local tile_heightmap_index = (GRID_SIZE * (tile_heightmap_y-1) + tile_heightmap_x)

	-- add base altitude to local tile altitude
	local altitude;
	if #TILE_DATA.tiles[tile_type].heightmap == 1 then
		altitude = TILE_DATA.tiles[tile_type].heightmap[1] -- if tile altitude is flat just one number might be used in array
	else
		altitude = TILE_DATA.tiles[tile_type].heightmap[tile_heightmap_index]
	end

	altitude = altitude + tile_altitude
	
	return altitude
end

function offset_level(x,y)
	-- mutate
	LEVEL_OFFSET.floatx = LEVEL_OFFSET.floatx + x
	LEVEL_OFFSET.floaty = LEVEL_OFFSET.floaty + y
	-- set
	LEVEL_OFFSET.x = math.floor(LEVEL_OFFSET.floatx + 0.5)
	LEVEL_OFFSET.y = math.floor(LEVEL_OFFSET.floaty + 0.5)
end

function clear_background()
	lib_gfx.lockFocus(BACKGROUND_SPRITE:getImage())
		lib_gfx.setColor(lib_gfx.kColorBlack)
		lib_gfx.fillRect(0,0,SCREEN_WIDTH, SCREEN_HEIGHT)

		--lib_gfx.setColor(lib_gfx.kColorWhite)
		--lib_gfx.drawRect(0,0,LEVEL_IMAGE_WIDTH-1,LEVEL_IMAGE_HEIGHT-1)
	lib_gfx.unlockFocus()
end

function draw_debug_grid(level)
	--does not work at the moment, return!

	if not level then level = CURRENT_LEVEL end
	if true then return end

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


-- item actions
function item_switch_action(obj)
	-- switch frame
	if obj.current_frame < #obj.frame_list then
		obj.current_frame = obj.current_frame+1
	else
		obj.current_frame = 1
	end
	obj.sprite:setImage(LEVEL_ITEMS_IMAGE_TABLE:getImage(obj.frame_list[obj.current_frame]))
	-- go through all tiles and switch all tiles that are of type "boost"
	local switch_list_from = { 14, 15, 16, 17 }
	local switch_list_to   = { 16, 17, 14, 15 }
	print("switching all directional tiles")
	local level_tiles = LEVEL_DATA.levels[CURRENT_LEVEL].tiles
	for i = 1, #level_tiles do
		local switch_to = nil
		for j = 1, #switch_list_from do
			if level_tiles[i] == switch_list_from[j] then 
				switch_to = switch_list_to[j] 
			end
		end
		if switch_to then level_tiles[i] = switch_to end
	end
	draw_level()
end

function item_switch_update(obj)
	-- update for switch items
	-- print("update switch")
end




-- algorithms / math

function rotate_vector( x, y, rad )
	-- used when controlling accelerometer
	if not rad then rad = -0.785398 end -- 45 degrees
	local cos = math.cos(rad)
	local sin = math.sin(rad)
	local px = x * cos - y * sin
	local py = x * sin + y * cos
	return px, py
end

function degrees_to_vector(angle)
	-- use when controlling with crank
	local crankRads = math.rad(angle)
	local vx = math.sin(crankRads)
	local vy = -1 * math.cos(crankRads)
	return vx, vy
end

function degrees_to_vector_lut(angle) -- double speed faster
	-- use when controlling with crank
	local a = math.floor(angle+0.5)
	a = a % 360
	return VECTOR_LUT_X[a+1], VECTOR_LUT_Y[a+1]
end

function generate_vector_LUT()
	for d = 0,359 do
		VECTOR_LUT_X[d+1] = degrees_to_vector_x(d)
		VECTOR_LUT_Y[d+1] = degrees_to_vector_y(d)
	end
end

function degrees_to_vector_x(a)
	-- use when controlling with crank
	local r = math.rad(a)
	local vx = math.sin(r)
	return vx
end
function degrees_to_vector_y(a)
	-- use when controlling with crank
	local r = math.rad(a)
	local vy = -1 * math.cos(r)
	return vy
end

function generate_sine_LUT()
	local delta = 2/360 -- divide full circle of rads (2) in full circle of deg (360) 
	print("generated sine lut")
	SINE_LUT[1] = 0
	for r = 2, 360 do
		SINE_LUT[r] = math.sin(delta * r)
		--print(r, SINE_LUT[r])
	end
end

function generate_cosine_LUT()
	local delta = 2/360 -- divide full circle of rads (2) in full circle of deg (360) 
	print("generated cosine lut")
	COSINE_LUT[1] = 1
	for r = 2, 360 do
		COSINE_LUT[r] = math.cos(delta * r)
		--print(r, COSINE_LUT[r])
	end
end


--[[ 
	function iso_to_grid(x, y, offsetx, offsety)
		if not offsetx then offsetx = 0 end
		if not offsety then offsety = 0 end
		x = x - LEVEL_OFFSET.x
		y = y - LEVEL_OFFSET.y
		local gx = x + y * 2 - offsetx --+ GRID_SIZE
		local gy = y * 2 - (x - offsetx) --+ GRID_SIZE
		return gx, gy
	end 
]]

function grid_to_iso(x, y, offsetx, offsety)
	if not offsetx then offsetx = 0 end
	if not offsety then offsety = 0 end
	local ix = x-y + offsetx 
	local iy = math.abs(x+y)/2 + offsety 
	return ix, iy
end




-- buttons

function playdate.BButtonDown()
	if CURRENT_STATE == GAME_STATE.playing then 
		ORB.accelerate_flag = true 
	end
end


function playdate.BButtonUp()
	ORB.accelerate_flag = false
end

function playdate.AButtonDown()
	if CURRENT_STATE == GAME_STATE.playing then 
		ORB.accelerate_flag = true 
		playdate.startAccelerometer()
	end
end

function playdate.AButtonUp()
	if CURRENT_STATE == GAME_STATE.menu then
		if not MENU_DATA.menu[MENU_SELECT_COUNTER].funct then
			print("no function")
		else
			local f = MENU_DATA.menu[MENU_SELECT_COUNTER].funct
			-- TODO: check if function exists
			_G[f]()
		end
	end
	if CURRENT_STATE == GAME_STATE.playing then
		ORB.accelerate_flag = false
		playdate.stopAccelerometer()
	end
end

function playdate.rightButtonDown()
	CURRENT_STATE = GAME_STATE.cleanup
	if CURRENT_LEVEL < #LEVEL_DATA.levels then
		CURRENT_LEVEL = CURRENT_LEVEL+1
	else
		CURRENT_LEVEL = 1
	end
	print("current level: "..CURRENT_LEVEL)
end


function playdate.leftButtonDown()
	play_sound()
end

function playdate.upButtonDown() -- up button
	if CURRENT_STATE == GAME_STATE.menu then
		if MENU_SELECT_COUNTER <= 1 then
			MENU_SELECT_COUNTER = #MENU_DATA.menu
		else
			MENU_SELECT_COUNTER = MENU_SELECT_COUNTER - 1
		end
	end
end

function playdate.downButtonDown() -- down button
	if CURRENT_STATE == GAME_STATE.menu then
		if MENU_SELECT_COUNTER < #MENU_DATA.menu then
			MENU_SELECT_COUNTER = MENU_SELECT_COUNTER + 1
		else
			MENU_SELECT_COUNTER = 1
		end
	end
end
