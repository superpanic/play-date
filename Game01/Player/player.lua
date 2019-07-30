class('Player').extends(playdate.graphics.sprite)

function Player:init(image)
	Player.super.init(self, image)
	self.health = 100
	--self:setCollisionRect(0, 0, self.width, self.height)
	self:setZIndex(500)
	self:addSprite()
	
	return self
end