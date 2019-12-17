--import "Common/common"
import "Item/item"

class('Gold').extends(Item)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Item/gold')

function Gold:init(map, params)
	Gold.super.init(self, img, map, "gold")
	if params.value then self.value = params.value
	else print("Gold with no value loaded"); self.value = 0 end
	self.parent = self.super.super
end

