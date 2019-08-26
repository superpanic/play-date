--import "Common/common"
import "Being/being"

--class('Player').extends(playdate.graphics.sprite)

class('Player').extends(Being)

local player_images = playdate.graphics.imagetable.new('Player/player')

function Player:init()
	Player.super.init(self)
	self.parent = self.super.super
	self.t = nil
	self:setup_frames()
	self:add()
	self:setZIndex(1000)
	--self:tableDump()
end

function Player:setup_frames()	
	self.animation_state = beings_data.beings.player.images
	self.current_state = self.animation_state.idle.frames
	self.frame_speed = self.animation_state.idle.speed
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
	self.t = playdate.timer.new(self.frame_speed, self.next_image, self)
end

function Player:set_animation_idle()
	self.current_state = self.animation_state.idle.frames
	self.frame_speed = self.animation_state.idle.speed
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_right()
	self.current_state = self.animation_state.right.frames
	self.frame_speed = self.animation_state.right.speed
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_left()
	self.current_state = self.animation_state.left.frames
	self.frame_speed = self.animation_state.left.speed
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_down()
	self.current_state = self.animation_state.down.frames
	self.frame_speed = self.animation_state.down.speed
	self.frame_index=1
	self:next_image()
end

function Player:set_animation_up()
	self.current_state = self.animation_state.up.frames
	self.frame_speed = self.animation_state.up.speed
	self.frame_index=1
	self:next_image()
end
