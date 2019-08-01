
class('Player').extends(playdate.graphics.sprite)

local playerImages = playdate.graphics.imagetable.new('Player/player')

function Player:init()
	Player.super.init(self)	
	self:setImage(playerImages[1])
	self.nImages = 2
	self.currentImage = 1
	self:add()
end

function Player:setupFrames()
	self.kAnimationState = {IDLE, RIGHT}
end

function Player:nextImage()
	if self.currentImage >= self.nImages then
		self.currentImage = 1
	else
		self.currentImage = self.currentImage + 1
	end
	self:setImage(playerImages[self.currentImage])
end

