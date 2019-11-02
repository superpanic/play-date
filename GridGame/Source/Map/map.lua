class('Map').extends(playdate.graphics.sprite)

local gridSize = 16
-- local grid_width = 400/grid_size
-- local grid_height = 240/grid_size

function Map:init()
	print("Map:init")
	Map.super.init(self)
	self.parent = Map.super
	
	self.map_offset = {x=0, y=0}
	
	-- load art
	self.img_table = playdate.graphics.imagetable.new("Map/map")
	self.img = playdate.graphics.image.new(screen_width, screen_height)
	self:setImage(self.img)
	
	self.level_art = playdate.datastore.read('Map/tiles')
	if(self.level_art == nil) then print("cound not read tile data") end
	
	self.level_data = playdate.datastore.read('Map/levels')
	if(self.level_data == nil) then print("cound not read level data") end

	self.current_level_tiles = {}
	self.current_level_beings = {}

	-- center image on screen
	self:moveTo(screen_width/2,screen_height/2)

	self:add()
	self:setZIndex(-1000)
	self.is_level_loaded = false

end

function Map:update_beings()
	local n_beings = #self.current_level_beings
	if n_beings > 0 then
		for i=n_beings,1,-1 do
			-- TODO: this remove loop is slow
			if self.current_level_beings[i].remove_me then
				print("removing "..self.current_level_beings[i].className)
				self.current_level_beings[i]:removeSprite() -- removing from sprite update
				table.remove(self.current_level_beings,i)
			end
		end
	end
end

function Map:load_level(level)
	-- load level data
	--self:generate_random_map()
	self:load_level_map(level)
	self:load_level_beings(level)
	self:process_wall_endings()
	self:process_tile_variations()
	self:draw_map()
end

function Map:get_map_offset()
	return self.map_offset
end

function Map:add_map_offset(x, y)
	self.map_offset.x = self.map_offset.x + x
	self.map_offset.y = self.map_offset.y + y
	if #self.current_level_beings > 0 then
		for i, being in ipairs(self.current_level_beings) do
			being:set_offset(self.map_offset.x, self.map_offset.y)
			being:update_pos()
		end
	end
	self:draw_map()
end

function Map:generate_random_map()
	self.grid_width = math.floor(400/grid_size)
	self.grid_height = math.floor(240/grid_size)
	-- generate a map from perlin noise
	local s, ms = playdate.getSecondsSinceEpoch()
	math.randomseed(ms)
	local seed = math.random()
	-- randomize z value to 'seed' the perlin noise
	self.level_map = playdate.graphics.perlinArray( self.grid_width * self.grid_height, 0, 0.4, 0, 0.24, 10.0 * seed, 0, 0)
	-- make integers
	for i = 1, #self.level_map do
		self.level_map[i] = math.floor(self.level_map[i] + 0.5)
	end
end

function Map:draw_map()
	if self.is_level_loaded == false then return end
	playdate.graphics.lockFocus(self.img) 
		--
		playdate.graphics.setColor(playdate.graphics.kColorBlack)
		playdate.graphics.fillRect(0, 0, screen_width, screen_height)
		-- draw part of map visible on screen
		for x = 1, self.grid_width do
			for y = 1, self.grid_height do
				-- get the tile to draw
				local tile = self.current_level_tiles[ self.grid_width * (y - 1) + x ]
				-- get the image tile and draw to level map
				local im = self.img_table:getImage(tile)
				-- adjust for image being 0-indexed
				local col = x + self.map_offset.x
				local row = y + self.map_offset.y
				im:drawAt((col-1)*grid_size,(row-1)*grid_size)
			end
		end
	--
	playdate.graphics.unlockFocus()
	self:markDirty()
end

function Map:process_tile_variations()
	if self.is_level_loaded == false then return end
	for x = 1, self.grid_width do
		for y = 1, self.grid_height do
			-- find the tile to draw
			local id = self.level_map[self.grid_width*(y-1)+x]
			self.current_level_tiles[self.grid_width*(y-1)+x] = self:get_tile_index(id)
		end
	end		
end

function Map:process_wall_endings()
	if self.is_level_loaded == false then 
		print("error: no level loaded")
		return 
	end
	for x = 1, self.grid_width do
		for y = 1, self.grid_height do
			local id = self.level_map[self.grid_width*(y-1)+x]
			local tname = self:get_tile_name(id)
			if tname == "stone wall" then
				if self:is_wall_edge(x, y) then
					self.level_map[self.grid_width*(y-1)+x] = self:get_tile_id("stone wall edge")
				end
			end
			if tname == "brick wall" then
				if self:is_wall_edge(x, y) then
					self.level_map[self.grid_width*(y-1)+x] = self:get_tile_id("brick wall edge")
				end
			end
		end
	end
end

function Map:get_level_name(l)
	print("l: "..l)
	if l > 0 and self.level_data and #self.level_data.levels >= l then
		return self.level_data.levels[l].name
	end
	return "not defined"
end

function Map:load_level_map(l)
	print("loading level: "..self:get_level_name(l))
	if l > 0 and self.level_data and #self.level_data.levels >= l then
		self.level_map = self.level_data.levels[l].data
		self.grid_width = self.level_data.levels[l].width 
		self.grid_height = #self.level_map / self.grid_width
		self.is_level_loaded = true
	end
end

function Map:find_first_empty_tile()
	t = {x=1,y=1}
	if self.is_level_loaded == false then 
		print("error: no level loaded")
		return t 
	end
	for row = 1, self.grid_width do
		for col = 1, self.grid_height do
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
	if self.is_level_loaded == false then return end
	-- boundary check
	if x > 0 and x <= self.grid_width and y > 0 and y <= self.grid_height then
		local val = self.level_map[self.grid_width*(y-1)+x]
		local tiles = self.level_art.tiles
		for i=1, #tiles do
			if tiles[i].id == val then
				return tiles[i].passable
			end
		end
	end
	return false
end

function Map:is_wall_edge(x, y)
	if y == self.grid_height then return true end
	local p = self.grid_width*(y-1)+x
	if x > 0 and x <= self.grid_width and y > 0 and y < self.grid_height then
		--local id = self.level_map[p+self.grid_width]
		if self:is_tile_passable(x, y) == false and self:is_tile_passable(x, y+1) == true then
			return true 
		end
	end
	return false
end

function Map:get_tile_index(n)
	if self.is_level_loaded == false then return end
	-- takes id or name as input
	local t = self.level_art.tiles
	for i=1, #t do
		if tonumber(n) ~= nil then
			if t[i].id == n then
				tile_index = math.random(1, #t[i].tile)
				return t[i].tile[tile_index]
			end		
		else
			if t[i].name == n then
				tile_index = math.random(1, #t[i].tile)
				return t[i].tile[tile_index]
			end		
		end
	end
	return nil
end

function Map:get_tile_name(id)
	if self.is_level_loaded == false then return end
	local t = self.level_art.tiles
	for i=1, #t do
		if t[i].id == id then
			return t[i].name
		end
	end
	return nil
end

function Map:get_tile_id(name)
	if self.is_level_loaded == false then return end
	local t = self.level_art.tiles
	for i=1, #t do
		if t[i].name == name then
			return t[i].id
		end
	end
	return nil
end

function Map:load_level_beings(l)
	print("loading "..self:get_level_name(l).." beings")
	if l > 0 and self.level_data and #self.level_data.levels >= l then
		local n_beings = #self.level_data.levels[l].beings
		if n_beings > 0 then
			-- load level beings
			for i = 1, n_beings do
				print(self.level_data.levels[l].beings[i].class)
				local being_data = self.level_data.levels[l].beings[i]
				if being_data.class == "snake" then
					--local b = Snake()
					local being = Snake(self) -- needs reference to map (self)
					being:move_to_pos(being_data.pos[1], being_data.pos[2])
					table.insert(self.current_level_beings, being)
				end
			end
		end
	else
		print("level being data missing for level: "..self:get_level_name(l))
	end
end

function Map:get_being_at(x, y)
	if #self.current_level_beings > 0 then
		for i, being in ipairs(self.current_level_beings) do
			local p = being.current_pos
			if p.x == x and p.y == y then
				return being
			end
		end
	end
	return nil
end
