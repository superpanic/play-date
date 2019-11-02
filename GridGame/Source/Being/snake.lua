--import "Common/common"
import "Being/being"


class('Snake').extends(Being)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Being/snake')

function Snake:init(map)
	Snake.super.init(self, img, map, "snake")
	self.parent = self.super.super
	self.t = nil -- timer
	self:setup_frames()
	self:add()
	self:setZIndex(1000)
end

function Snake:attack(str)
	if self.is_dead == true then return end
	print("attacked by "..str)
	self:die()
end

function Snake:check_collision(x, y)
	return false
end

