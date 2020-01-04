--import "Common/common"
import "Weapon/weapon"

class('Dagger').extends(Weapon)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Weapon/dagger')

function Dagger:init()
	if not img then
		print("dagger weapon image missing")
	end
	
	Dagger.super.init(self, {
		image  = img, 
		name   = "Dagger", 
		damage = 100, 
		speed  = 50,
		size   = 100, 
		hands  = 1, 
		level  = 1
	} )
	self.parent = self.super.super
end
