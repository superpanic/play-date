--import "Common/common"
import "Being/being"

--class('Player').extends(playdate.graphics.sprite)

class('Player').extends(Being)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local player_images = playdate.graphics.imagetable.new('Being/flower')

function Player:init(map)
	Player.super.init(self, player_images, map)
	self.parent = self.super.super
	self.t = nil -- timer
	self:setup_frames()
	self:add()
	self:setZIndex(1000)
end

function Player:check_collision(x, y)
	local being = self.map:get_being_at(x, y)
	if being then
		if being.className == "Snake" then
			being:attack("player")
		end
		return true
	else
		return false
	end
end
