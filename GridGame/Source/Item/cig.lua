--import "Common/common"
import "Item/item"

class('Cig').extends(Item)

--local player_images = playdate.graphics.imagetable.new('Player/player')
local img = playdate.graphics.imagetable.new('Item/cig')

function Cig:init(map, val)
	Cig.super.init(self, img, map, "cig")
	self.value = val
	self.parent = self.super.super
end

