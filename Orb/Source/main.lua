import "CoreLibs/graphics"
import "CoreLibs/sprites"

-- global vars:
lib_gfx = playdate.graphics
lib_spr = playdate.graphics.sprite

playdate.display.setScale(2)

g_screen_width = playdate.display.getWidth()
g_screen_height = playdate.display.getHeight()

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
orb = {}
local orb_img_table = lib_gfx.imagetable.new('Artwork/orb')

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