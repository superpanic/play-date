--import "Common/common"
import "Item/item"

class('Gold').extends(Item)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Item/gold')

function Gold:init(map, val)
	Gold.super.init(self, img, map, "gold")
	self.value = val
	self.parent = self.super.super
end

