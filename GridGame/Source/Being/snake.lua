--import "Common/common"
import "Being/being"


class('Snake').extends(Being)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Being/snake')

function Snake:init()
	Snake.super.init(self, img)
	self.parent = self.super.super
	self.t = nil -- timer
	self:setup_frames()
	self:add()
	self:setZIndex(1000)
end
