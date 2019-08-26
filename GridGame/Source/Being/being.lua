class('Being').extends(playdate.graphics.sprite)

function Being:init()
	Being.super.init(self)
	self.current_pos = { x = 1, y = 1 }
	self.pos_offset = { x = 0, y = 0 }
end

function Being:move_to_pos(x, y)
	self.current_pos.x = x
	self.current_pos.y = y
	-- moveTo is 0 indexted
	self:moveTo((x + self.pos_offset.x - 1)*grid_size+grid_size/2, (y + self.pos_offset.y - 1)*grid_size+grid_size/2)
end

function Being:set_offset(x,y)
	self.pos_offset.x = x
	self.pos_offset.y = y
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

function Being:get_offset()
	return self.pos_offset
end

function Being:move_right()
	self:move_to_pos(self.current_pos.x + 1, self.current_pos.y)
end

function Being:move_left()
	self:move_to_pos(self.current_pos.x - 1, self.current_pos.y)
end

function Being:move_up()
	self:move_to_pos(self.current_pos.x, self.current_pos.y - 1)
end

function Being:move_down()
	self:move_to_pos(self.current_pos.x, self.current_pos.y + 1)
end
