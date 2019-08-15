import "Common/common"

class('Map').extends(playdate.graphics.sprite)

--local gridSize = 16
local grid_width = 400/grid_size
local grid_height = 240/grid_size

function Map:init()
	Map.super.init(self)
	self.parent = self.super.super
	
	self.img_table = playdate.graphics.imagetable.new("Map/map")
	self.img = playdate.graphics.image.new(screen_width, screen_height)
	self:setImage(self.img)
	
	-- generate map
	self.map = playdate.datastore.read('Map/tiles')
	self.level_data = playdate.datastore.read('Map/levels')
	
	self.level_map = {}

--	self:generate_random_map()
	self.level_map = self:get_level_map(1)

	self:draw_map()
	-- center on screen
	self:moveTo(screen_width/2,screen_height/2)
	
	self:add()
	self:setZIndex(-1000)
end

function Map:generate_random_map()
	-- generate a map from perlin noise
	local s, ms = playdate.getSecondsSinceEpoch()
	math.randomseed(ms)
	local seed = math.random()
	-- randomize z value to 'seed' the perlin noise
	self.level_map = playdate.graphics.perlinArray( grid_width * grid_height, 0, 0.4, 0, 0.24, 10.0 * seed, 0, 0)
end

function Map:draw_map()
	playdate.graphics.lockFocus(self.img)
	for x = 1, grid_width do
		for y = 1, grid_height do
			local val = self.level_map[grid_width*(y-1)+x]
			local tile = self:tile_index("EMPTY")
			local im = nil
			if math.floor(val+0.5) == 0 then	
				tile = self:tile_index("EMPTY")
			else
				if self:is_wall_edge(x, y) then
					tile = self:tile_index("STONE_WALL_EDGE")
				else
					tile = self:tile_index("STONE_WALL")
				end				
			end
			im = self.img_table:getImage( tile )
			-- adjust for image being 0-indexed
			im:drawAt((x-1)*grid_size,(y-1)*grid_size)
		end
	end
	playdate.graphics.unlockFocus()
end

function Map:get_level_name(l)
	if l > 0 and self.level_data and #self.level_data.levels >= l then
		return self.level_data.levels[l].name
	end
	return "not defined"
end

function Map:get_level_map(l)
	if l > 0 and self.level_data and #self.level_data.levels >= l then
		return self.level_data.levels[l].data
	end
	return nil
end

function Map:find_first_empty_tile()
	t = {x=1,y=1}
	for row = 1, grid_width do
		for col = 1, grid_height do
			if self:is_tile_passable(col, row) then
				t.x = col
				t.y = row
				return t
			end
		end
	end
	return t
end

function Map:is_tile_passable(x, y)
	if x > 0 and x <= grid_width and y > 0 and y <= grid_height then
		local val = self.level_map[grid_width*(y-1)+x]
		if math.floor(val+0.5) == 0 then 
			return true 
		end
	end
	return false
end

function Map:is_wall_edge(x, y)
	local p = grid_width*(y-1)+x
	if x > 0 and x <= grid_width and y > 0 and y < grid_height then
		local val = self.level_map[p+grid_width]
		if math.floor(val+0.5) == 0 then 
			return true 
		end
	end
	return false
end

function Map:tile_index(name)
	local t = self.map.tiles
	for i=1, #t do
		if t[i].name == name then
			return t[i].index
		end
	end
	return nil
end
