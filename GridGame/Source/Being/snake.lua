--import "Common/common"
import "Being/being"
import "Weapon/dagger"

class('Snake').extends(Being)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Being/snake')

function Snake:init(map)
	Snake.super.init(self, img, map, "snake")
	self.parent = self.super.super
	self.t = nil -- timer
	self.health = 200
	self:setup_frames()
	self:add()
	self:setZIndex(1000)
	
	self.weapon = Dagger()
end

function Snake:attacked_by(attacker)
	if self.is_dead == true then return end
	print(attacker.name.." attacks "..self.name.." with: "..attacker.weapon.name)
	if self.health > attacker.weapon.damage then
		self.health = self.health - attacker.weapon.damage
	else
		self.health = 0
		self:die()
	end
	print(self.name .. " health: " .. self.health)
end

function Snake:check_collision(x, y)
	return false
end

function Snake:run_ai()
	-- can see player?
	local i_see_player = self.map:can_see_player(self)
	if i_see_player then
		--
	end
end

