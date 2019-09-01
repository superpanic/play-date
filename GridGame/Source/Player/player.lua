--import "Common/common"
import "Being/being"

--class('Player').extends(playdate.graphics.sprite)

class('Player').extends(Being)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local player_images = playdate.graphics.imagetable.new('Being/flower')

function Player:init()
	Player.super.init(self, player_images)
	self.parent = self.super.super
	self.t = nil -- timer
	self:setup_frames()
	self:add()
	self:setZIndex(1000)
end

