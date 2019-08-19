--import "Common/common"

class('Being').extends(playdate.graphics.sprite)

function Being:init()
	Being.super.init(self)
	self.current_pos = { x = 1, y = 1 }
end

function Being:moveToPos(x, y)
	self.current_pos.x = x
	self.current_pos.y = y
	-- moveTo is 0 indexted
	self:moveTo((x-1)*grid_size+grid_size/2, (y-1)*grid_size+grid_size/2)
end

function Being:moveRight()
	self:moveToPos(self.current_pos.x + 1, self.current_pos.y)
end

function Being:moveLeft()
	self:moveToPos(self.current_pos.x - 1, self.current_pos.y)
end

function Being:moveUp()
	self:moveToPos(self.current_pos.x, self.current_pos.y - 1)
end

function Being:moveDown()
	self:moveToPos(self.current_pos.x, self.current_pos.y + 1)
end
