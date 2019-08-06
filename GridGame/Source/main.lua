import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"
import "Player/player"
import "Item/item"
import "Map/map"
import "Common/common"

local grid_on = false

local k_game_state = {
	INITIAL = 1, 
	READY   = 2, 
	PLAYING = 3, 
	PAUSED  = 4, 
	OVER    = 5
}

local current_state = k_game_state.INITIAL
local player = Player()
local player2 = Player()
local map = Map()
local item = Item()
local item2 = Item()

playdate.display.setRefreshRate(0)

function setup()	
--	print(player:isa(Player))
--	print("Player: "..player.className)
--	print("Player.super: "..player.super.className)
--	print("Player.super.super: "..player.super.super.className)
--	print("Player.super.super.super: "..player.super.super.super.className)
	player:moveTo(2*16+9, 2*16+9)
	player2:moveTo(4*16+9, 4*16+9)
	--player:add()
	--item:add()
	--item2:add()
--	p2:moveTo(4*16+9, 4*16+9)
end

function playdate.update()
	if grid_on then draw_grid() end
	playdate.timer.updateTimers()
	item.update()
	--libspr.update()
end

function playdate.rightButtonDown()
	player:set_animation_right()
end

function playdate.rightButtonUp()
	player:set_animation_idle()
end

setup()