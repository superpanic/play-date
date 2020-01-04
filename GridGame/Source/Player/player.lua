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
	self.inventory_updated = true
end

function Player:check_collision(x, y)
	local being = self.map:get_being_at(x, y)
	if being then
		if being.name == "snake" then
			being:attacked_by(self)
		elseif being.name == "gold" then
			print("take gold!")
			being:attacked_by(self)
		elseif being.name == "cig" then
			print("take cig!")
			being:attacked_by(self)
		end
		
		return true
	else
		return false
	end
end

function Player:pick_up(item)
	if item.is_item then
		-- add item to inventory
		table.insert(self.inventory, item)
		print("items in inventory: " .. #self.inventory)
		if self.inventory[1] == nil then
			print("inventory is nil")
		else
			print("added " .. self.inventory[#self.inventory].className .. " to inventory")
			self.inventory_updated = true
		end
	end	
end

