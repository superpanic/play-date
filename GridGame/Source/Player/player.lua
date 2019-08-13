import "Common/common"

class('Player').extends(playdate.graphics.sprite)

local player_images = playdate.graphics.imagetable.new('Player/player')

function Player:init()
	Player.super.init(self)
	self.parent = self.super.super
	self.t = nil
	self:setup_frames()
	self.current_pos = { x = 1, y = 1 }
	self:add()
	self:setZIndex(1000)
end

function Player:moveToPos(x, y)
	self.current_pos.x = x
	self.current_pos.y = y
	-- moveTo is 0 indexted
	self:moveTo((x-1)*grid_size+grid_size/2, (y-1)*grid_size+grid_size/2)
end

function Player:moveRight()
	self:moveToPos(self.current_pos.x + 1, self.current_pos.y)
end

function Player:moveLeft()
	self:moveToPos(self.current_pos.x - 1, self.current_pos.y)
end

function Player:moveUp()
	self:moveToPos(self.current_pos.x, self.current_pos.y - 1)
end

function Player:moveDown()
	self:moveToPos(self.current_pos.x, self.current_pos.y + 1)
end

function Player:setup_frames()
	self.k_animation_state = {
		IDLE =  { 1, 2 },
		RIGHT = { 3, 4 },
		LEFT =  { 3, 4 },
		DOWN =  { 1, 2 },
		UP   =  { 1, 2 }
	}
	self.k_animation_speed = {
		IDLE  = 1000 / 4,
		RIGHT = 1000 / 4,
		LEFT  = 1000 / 4,
		DOWN  = 1000 / 4,
		UP    = 1000 / 4
	}
	self.current_state = self.k_animation_state.IDLE
	self.animation_speed = self.k_animation_speed.IDLE
	self.frame_index = 1
	self:setImage(player_images[self.current_state[self.frame_index]])
	self:next_image()
end

function Player:next_image()
	if self.frame_index >= #self.current_state then
		self.frame_index = 1
	else
		self.frame_index++
	end
	-- update image
	self:setImage(player_images[self.current_state[self.frame_index]])
	-- handle timers
	if self.t then self.t:remove() end
	self.t = playdate.timer.new(self.animation_speed, self.next_image, self)
end

function Player:set_animation_idle()
	self.current_state = self.k_animation_state.IDLE
	self.animation_speed = self.k_animation_speed.IDLE
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_right()
	self.current_state = self.k_animation_state.RIGHT
	self.animation_speed = self.k_animation_speed.RIGHT
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_left()
	self.current_state = self.k_animation_state.LEFT
	self.animation_speed = self.k_animation_speed.LEFT
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_down()
	self.current_state = self.k_animation_state.DOWN
	self.animation_speed = self.k_animation_speed.DOWN
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_up()
	self.current_state = self.k_animation_state.UP
	self.animation_speed = self.k_animation_speed.UP
	self.frame_index=1
	self:next_image()
end
