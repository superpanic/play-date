class('Weapon').extends(Object)

function Weapon:init(params)
	Weapon.super.init(self)

	if params.images then self.images = params.images
	else self.images = 0 end
	
	if params.name then self.name = params.name
	else self.name = "Undefined weapon" end

	if params.damage then self.damage = params.damage 
	else self.damage = 0 end
	
	if params.size then self.size = params.size 
	else self.size = 0 end

	if params.hands then self.hands = params.hands
	else self.hands = 0 end

	if params.level then self.level = params.level
	else self.level = 0 end

end

