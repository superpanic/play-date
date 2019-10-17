--import "Common/common"
import "Being/being"


class('Snake').extends(Being)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Being/snake')

function Snake:init(map)
	Snake.super.init(self, img, map)
	self.parent = self.super.super
	self.t = nil -- timer
	self:setup_frames()
	self:add()
	self:setZIndex(1000)
end

function Snake:attack(str)
	print("attacked by "..str)
end

function Snake:check_collision(x, y)
	return false
end

