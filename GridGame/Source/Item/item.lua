import "common"

class('Item').extends(Being)

function Item:init(img, map, name)
	Item.super.init(self, img, map, name)
	self.parent = self.super.super
	self.is_item = true
	self.t = nil
	self.value = 0
	self:setup_frames()
	self:add()
	self:setZIndex(1001)	
end

function Item:attacked_by(attacker)
	print("pickup!")
	if attacker.name == "player" then
		-- add item to inventory
		attacker:pick_up(self)
		-- kill and remove from map
		self:die()
	end
end
