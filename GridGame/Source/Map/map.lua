import "Common/common"

class('Map').extends(playdate.graphics.sprite)

--local gridSize = 16
local grid_width = 400/grid_size
local grid_height = 240/grid_size

function Map:init()
	Map.super.init(self)
	-- main properties
	self.img_table = playdate.graphics.imagetable.new("Map/map")
	--self.img = playdate.graphics.image.new(screen_width, screen_height, 1)
	self.pnoise = {}
	self.legend = {
		STONE_WALL_1      =  1,
		STONE_WALL_2      =  2,
		WALL_1            =  3,
		WALL_2            =  4,
		STONE_WALL_EDGE_1 =  5,
		STONE_WALL_EDGE_2 =  6,
		WALL_EDGE_1       =  7,
		WALL_EDGE_2       =  8,
		SAND_1            =  9,
		SAND_2            = 10,
		FLOOR_1           = 11,
		FLOOR_2           = 12
	}
	self.img = playdate.graphics.image.new(screen_width, screen_height)
	self:setImage(self.img)
	-- generate map
	self:generate_map()
	self:draw_map()
	-- center on screen
	self:moveTo(screen_width/2,screen_height/2)
	self:setZIndex(-1000)
	self:add()
end

function Map:generate_map()
	-- the goal is to generate a map from perlin noise
	-- draw corridors to areas that are not accessible
	local s, ms = playdate.getSecondsSinceEpoch()
	math.randomseed(ms)
	local seed = math.random()
	-- randomize z value to 'seed' the perlin noise
	self.pnoise = playdate.graphics.perlinArray( grid_width * grid_height, 0, 0.4, 0, 0.24, 10.0 * seed, 0, 0)
end

function Map:draw_map()
	playdate.graphics.lockFocus(self.img)
	for x = 1, grid_width do
		for y = 1, grid_height do
			local val = self.pnoise[grid_width*(y-1)+x]
			local tile = nil
			local im = nil
			if math.floor(val+0.5) == 0 then	
				if (x+y) % 2 == 0 then
					tile = self.legend.WALL_2
				else
					tile = self.legend.WALL_2
				end
				im = self.img_table:getImage( tile )
			else
				if (x+y) % 2 == 0 then
					if self:is_wall_end(x, y) then
						tile = self.legend.STONE_WALL_EDGE_2 
					else
						tile = self.legend.STONE_WALL_1
					end
				else
					if self:is_wall_end(x, y) then
						tile = self.legend.STONE_WALL_EDGE_2
					else
						tile = self.legend.STONE_WALL_1
					end
				end
				im = self.img_table:getImage( tile )
			end
			im:drawAt((x-1)*grid_size,(y-1)*grid_size)
		end
	end
	playdate.graphics.unlockFocus()
end

function Map:is_wall_end(x, y)
	local p = grid_width*(y-1)+x
	if x > 0 and x <= grid_width and y > 0 and y < grid_height then
		local val = self.pnoise[p+grid_width]
		if math.floor(val+0.5) == 0 then 
			return true 
		end
	end
	return false
end


-- if stone wall


-- use perlin noise and smooth it out?
-- all maps have an entry
-- not all maps have an exit
-- start generating in the middle
-- start with a floor type
-- extend out
-- if we reach edge add wall
