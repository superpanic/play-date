import "Weapon/weapon"

class('Being').extends(playdate.graphics.sprite)

function Being:init(images, map, name)
	Being.super.init(self)
	self.images = images
	self.map = map
	self.name = name
	self.is_item = false
	self.health = 1
	self.current_pos = { x = 1, y = 1 }
	self.pos_offset = { x = 0, y = 0 }
	self.is_dead = false
	self.remove_me = false
	self.inventory = {}
end

function Being:move_to_pos(x, y)
	if self:check_collision(x, y) then
		return false
	end
	self.current_pos.x = x
	self.current_pos.y = y
	-- moveTo is 0 indexted
	self:moveTo((x + self.pos_offset.x - 1)*grid_size+grid_size/2, (y + self.pos_offset.y - 1)*grid_size+grid_size/2)
	return true
end

function Being:check_collision(x, y)
	-- override this template
	return false
end

function Being:update_pos()
	self:moveTo((self.current_pos.x + self.pos_offset.x - 1)*grid_size+grid_size/2, (self.current_pos.y + self.pos_offset.y - 1)*grid_size+grid_size/2)
end

function Being:set_offset(x,y)
	self.pos_offset.x = x
	self.pos_offset.y = y
	self:update_pos()
end

function Being:get_screen_pos()
	local xpos = self.current_pos.x + self.pos_offset.x
	local ypos = self.current_pos.y + self.pos_offset.y
	local p = { 
		x = (xpos - 1) * grid_size + grid_size/2, 
		y = (ypos - 1) * grid_size + grid_size/2
	}
	return p
end

function Being:setup_frames()
	for k,v in pairs(global_beings_data.beings) do
		if k==self.name then
			print(self.name)
			self.animation_state = v.images
		end
	end
	self.current_state = self.animation_state.idle.frames
	self.frame_speed = self.animation_state.idle.speed
	self.next = self.animation_state.idle.next
	self.is_flipped = self.animation_state.idle.flip
	self.frame_index = 1
	self:setImage(self.images[self.current_state[self.frame_index]])
	self:next_image()
end

function Being:next_image()
	if self.remove_me then return end -- avoid adding a timer call (below)

	-- flip image
	local flip
	if self.is_flipped then
		flip = libgfx.kImageFlippedX
	else
		flip = libgfx.kImageUnflipped
	end
	
	-- update image
	self:setImage(self.images[self.current_state[self.frame_index]], flip)
	
	-- handle timers
	if self.t then self.t:remove() end -- if a timer is already set, remove it
	self.t = playdate.timer.new(self.frame_speed, self.next_image, self)
	
		-- advance frame
	if self.frame_index >= #self.current_state then
		self:loop_animation()
	else
		self.frame_index = self.frame_index + 1
	end

end

function Being:run_ai()
	-- override this function
end

function Being:loop_animation()
	if self.is_dead then
		self.remove_me = true
		return
	end
	if self.next == "loop" then
		self.frame_index = 1	
	else
		for _,state in pairs(self.animation_state) do
			if state.name == self.next then
				self:set_animation_state(state)
				break;
			end
		end
	end
end

function Being:set_animation_state(state)
	-- check if state exists, if not default to 'idle'
	if state == nil then state = self.animation_state.idle end

	self.current_state = state.frames
	self.frame_speed = state.speed
	self.next = state.next
	self.is_flipped = state.flip
	self.frame_index = 1
end

function Being:set_animation_idle()
	self:set_animation_state(self.animation_state.idle)
	self:next_image()
end

function Being:set_animation_right()
	self:set_animation_state(self.animation_state.right)
	self:next_image()
end

function Being:set_animation_left()
	self:set_animation_state(self.animation_state.left)
	self:next_image()
end

function Being:set_animation_down()
	self:set_animation_state(self.animation_state.down)
	self:next_image()
end

function Being:set_animation_up()
	self:set_animation_state(self.animation_state.up)
	self:next_image()
end

function Being:get_offset()
	return self.pos_offset
end

function Being:move_right()
	return self:move_to_pos(self.current_pos.x + 1, self.current_pos.y)
end

function Being:move_left()
	return self:move_to_pos(self.current_pos.x - 1, self.current_pos.y)
end

function Being:move_up()
	return self:move_to_pos(self.current_pos.x, self.current_pos.y - 1)
end

function Being:move_down()
	return self:move_to_pos(self.current_pos.x, self.current_pos.y + 1)
end

function Being:attacked_by(attacker)
	if is_item then
		print("destroying item " .. self.name)
		self:die()
		return
	end
	-- override this function
	if self.is_dead == true then return end
	print(attacker.name.." attacks "..self.name)
	self:die()
	return
end

function Being:die()
	-- override this function
	self.is_dead = true
	self:set_animation_state(self.animation_state.death)
	self:next_image()
end
