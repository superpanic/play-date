--import "Common/common"
import "Being/being"
import "Weapon/dagger"

--class('Player').extends(playdate.graphics.sprite)

class('Player').extends(Being)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local player_images = playdate.graphics.imagetable.new('Player/player')

function Player:init(map)
	Player.super.init(self, player_images, map, "player")
	self.parent = self.super.super
	self.t = nil -- timer
	self:setup_frames()
	self:add()
	self:setZIndex(1000)

	self.weapon = Dagger()
end

function Player:check_collision(x, y)
	local being = self.map:get_being_at(x, y)
	if being then
		if being.className == "Snake" then
			being:attack(self)
		end
		return true
	else
		return false
	end
end
