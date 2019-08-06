import "Common/common"

class('Item').extends(playdate.graphics.sprite)

local item_images = playdate.graphics.imagetable.new('Item/items')

function Item:init()
	Item.super.init(self)
	self.t = nil
	self:setup_frames()
	self.currentPos = libpnt.new(0,0)
	self.destinationPos = libpnt.new(0,0)
	self:add()
	self:setZIndex(1001)
end

function Item:setup_frames()
	print(self.className .. ":setup_frames() not implemented")
end

