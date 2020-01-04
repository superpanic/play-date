--import "Common/common"
import "Weapon/weapon"

class('Axe').extends(Weapon)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Weapon/axe')

function Axe:init()
	if not img then
		print("axe weapon image missing")
	end

	Axe.super.init(self, {
		image  = img, 
		name   = "Axe", 
		damage = 300, 
		speed  = 200,
		size   = 200, 
		hands  = 2, 
		level  = 1
	} )
	self.parent = self.super.super
end
