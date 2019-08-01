
class('Player').extends(playdate.graphics.sprite)

local playerImages = playdate.graphics.imagetable.new('Player/player')

function Player:init()
	Player.super.init(self)
	self:add()
	self.t = nil
	self:setupFrames()
end

function Player:setupFrames()
	self.kAnimationState = {
		IDLE =  { 1, 2},
		RIGHT = { 3, 4}
	}
	self.kAnimationSpeed = {
		IDLE  = 1000 /  4,
		RIGHT = 1000 /  4
	}
	self.currentState = self.kAnimationState.IDLE
	self.animationSpeed = self.kAnimationSpeed.IDLE
	self.frameIndex = 1
	self:setImage(playerImages[self.currentState[self.frameIndex]])
	self:nextImage()
end

function Player:nextImage()
	if self.frameIndex >= #self.currentState then
		self.frameIndex = 1
	else
		self.frameIndex++
	end
	self:setImage(playerImages[self.currentState[self.frameIndex]])
	if self.t then self.t:remove() end
	self.t = playdate.timer.new(self.animationSpeed, self.nextImage, self)
end

function Player:setAnimationIdle()
	self.currentState = self.kAnimationState.IDLE
	self.animationSpeed = self.kAnimationSpeed.IDLE
	self.frameIndex=1
	self:nextImage()
end

function Player:setAnimationRight()
	self.currentState = self.kAnimationState.RIGHT
	self.animationSpeed = self.kAnimationSpeed.RIGHT
	self.frameIndex=1
	self:nextImage()
end

function Player:setAnimation(state)
end

