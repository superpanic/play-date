--import "Common/common"
import "Weapon/weapon"

class('Sword').extends(Weapon)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Weapon/sword')

function Sword:init()
	if not img then
		print("sword weapon image missing")
	end

	Sword.super.init(self, {
		image  = img, 
		name   = "Sword", 
		damage = 100,
		speed  = 100,
		size   = 100, 
		speed  = 50, 
		hands  = 1, 
		level  = 1
	} )
	self.parent = self.super.super
end
