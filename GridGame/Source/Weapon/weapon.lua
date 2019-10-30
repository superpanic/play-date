class('Weapon').extends(Object)

function Weapon:init(images, name, damage, size, hands, level)
	Being.super.init(self)

	self.name = name
	self.images = images
	self.damage = damage
	self.size = size
	self.hands = hands
	self.level = level
	
end

