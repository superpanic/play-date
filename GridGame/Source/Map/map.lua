class('Map').extends(playdate.graphics.sprite)

local tile_render_max_x = screen_width / global_grid_size -- +1
local tile_render_max_y = screen_height / global_grid_size -- +1

function Map:init()
	Map.super.init(self)
	self.parent = Map.super.super
	self.player = {}

	self.private_map_offset = {x=0, y=0}
	
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

	self.visibility_map = {}

	-- center image on screen
	self:moveTo(screen_width/2,screen_height/2)

	self:add()
	self:setZIndex(-1000)
	self.is_level_loaded = false
end

function Map:set_player(p)
	self.player = p
end

function Map:update_beings()
	for i,b in pairs(self.current_level_beings) do
		
		local vis = true
		
		-- offset being pos
		local col = b.current_pos.x + self.private_map_offset.x
		local row = b.current_pos.y + self.private_map_offset.y
		
		-- do boundary check
		if col < 0 or row < 0 then vis = false end
		if col > tile_render_max_x or row > tile_render_max_y then vis = false end

		if vis == true then
			if not( self:line_of_sight(b.current_pos, self.player.current_pos) and self:player_is_within(b.current_pos.x, b.current_pos.y, global_fog_of_war) ) then
				vis = false
			end
		end
		
		b:setVisible(vis)
		
		-- run beings ai
		if not b.remove_me then
			b:run_ai()
		end
		
		-- remove beings
		if b.remove_me then
			print("removing "..b.className)
			b:removeSprite() -- removing from sprite update
			table.remove(self.current_level_beings,i)
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
	return self.private_map_offset
--	return { x = self.private_map_offset.x + x_offset, y = self.private_map_offset.y + y_offset }
end

function Map:add_map_offset(x, y)
	self.private_map_offset.x = self.private_map_offset.x + x
	self.private_map_offset.y = self.private_map_offset.y + y
	if #self.current_level_beings > 0 then
		for i, being in ipairs(self.current_level_beings) do
			being:set_offset(self.private_map_offset.x, self.private_map_offset.y)
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

function Map:draw_map_all()
	if self.is_level_loaded == false then return end
	libgfx.lockFocus(self.img) 
		--
		libgfx.setColor(libgfx.kColorBlack)
		libgfx.fillRect(0, 0, screen_width, screen_height)
		-- draw part of map visible on screen
		for x = 1, self.grid_width do
			for y = 1, self.grid_height do
				-- get the tile to draw
				local tile = self.current_level_tiles[ self.grid_width * (y - 1) + x ]
				-- get the image tile and draw to level map
				local im = self.img_table:getImage(tile)
				-- adjust for image being 0-indexed
				local col = x + self.private_map_offset.x
				local row = y + self.private_map_offset.y
				im:drawAt((col-1)*grid_size,(row-1)*grid_size)
			end
		end
	--
	libgfx.unlockFocus()
	self:markDirty() -- Map inherits sprite object!
end

function Map:draw_map()
	if self.is_level_loaded == false then return end

	playdate.graphics.lockFocus(self.img)
		playdate.graphics.setColor(playdate.graphics.kColorBlack)
		playdate.graphics.fillRect(0, 0, screen_width, screen_height)
		-- draw part of map visible on screen
		for x = 1, self.grid_width do
			for y = 1, self.grid_height do
				-- game grid (not pixel grid):
				local col = x + self.private_map_offset.x
				local row = y + self.private_map_offset.y
				
				-- screen boundary check:
				if col < 0 or row < 0 then goto continue end
				if col > tile_render_max_x or row > tile_render_max_y then goto continue end
				
				if not self:player_is_within(x, y, 3) then goto continue end
				
				-- is line of sight?
				local p1 = {x=x, y=y}
				if self:line_of_sight(p1, self.player.current_pos) then
					-- get the tile to draw
					local tile = self.current_level_tiles[ self.grid_width * (y - 1) + x ]
					-- get the image tile and draw to level map
					local im = self.img_table:getImage(tile)
					-- adjust for image being 0-indexed
					local col = x + self.private_map_offset.x
					local row = y + self.private_map_offset.y
					im:drawAt((col-1) * global_grid_size,(row-1) * global_grid_size)
					
					-- add shadow
					--playdate.graphics.setDitherPattern(self:get_normalized_distance(p1,self.player.current_pos))
					--playdate.graphics.fillRect((col-1)*grid_size,(row-1)*grid_size,16,16)
					
				end
				
				::continue::
			end
		end
	--
	playdate.graphics.unlockFocus()
	self:markDirty() -- Map inherits sprite object!
end

function Map:player_is_within(x, y, n)
	if x < self.player.current_pos.x - n or x > self.player.current_pos.x + n then return false end
	if y < self.player.current_pos.y - n or y > self.player.current_pos.y + n then return false end
	return true
end

function Map:get_normalized_distance(tile_pos, player_pos)
	-- this is stupid and slow
	-- and not used at the moment
	-- TODO: rewrite if used!
	
	local distance = {}
	distance.x = player_pos.x - tile_pos.x
	distance.y = player_pos.y - tile_pos.y

	local l = math.sqrt((distance.x * distance.x) + (distance.y * distance.y))
	
	if l >= 8 then
		return 0
	elseif l == 7 then
		return 0.3
	elseif l == 6 then
		return 0.5
	elseif l == 5 then
		return 0.6
	elseif l == 4 then
		return 0.7
	elseif l >= 3 then
		return 0.9
	else
		return 1
	end
	
end

function Map:update_visibility_map()
	-- if true then return null end
	-- go through all positions
	-- is pos within screen?
	-- TODO: is pos within circle of sight?
	for x = 1, self.grid_width do
		for y=1, self.grid_height do
			local max_x = screen_width / grid_size
			local max_y = screen_height / grid_size
			local col = x + self.private_map_offset.x
			local row = y + self.private_map_offset.y
			-- screen boundary check:
			if col < 0 or row < 0 then goto continue end
			if col > max_x or row > max_y then goto continue end
			-- is line of sight?
			local p1 = {x=x, y=y}
			if self:line_of_sight(p1, self.player.current_pos) then
				-- visible!
				self:draw_marker(col, row)
			end
			::continue::	
		end
	end
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
	if l > 0 and self.level_data and #self.level_data.levels >= l then
		return self.level_data.levels[l].name
	end
	return "not defined"
end

function Map:load_level_map(l)
	print("loading "..self:get_level_name(l).." data")
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
				local being_data = self.level_data.levels[l].beings[i]
				if being_data.class == "snake" then
					-- needs reference to map (self)
					local being = Snake(self) 
					being:move_to_pos(being_data.pos[1], being_data.pos[2])
					table.insert(self.current_level_beings, being)
				elseif being_data.class == "gold" then
					local being = Gold(self, being_data)
					being:move_to_pos(being_data.pos[1], being_data.pos[2])
					table.insert(self.current_level_beings, being)
				elseif being_data.class == "cig" then
					local being = Cig(self, being_data)
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

function Map:draw_line(f,t)
	playdate.graphics.lockFocus(self.img) 
		playdate.graphics.setColor(playdate.graphics.kColorXOR)
		playdate.graphics.drawLine(f.x, f.y, t.x, t.y)
	playdate.graphics.unlockFocus()
	self:markDirty()
end

function Map:draw_marker(x,y)
	local pos = {}
	pos.x = (x-1) * grid_size + grid_size/2
	pos.y = (y-1) * grid_size + grid_size/2
	playdate.graphics.lockFocus(self.img) 
		playdate.graphics.setColor(playdate.graphics.kColorXOR)
		playdate.graphics.drawCircleAtPoint(pos.x, pos.y,6)
	playdate.graphics.unlockFocus()
	self:markDirty()
end

function Map:can_see_player(being)	
	return self:line_of_sight(being.current_pos, self.player.current_pos)
end

function Map:line_of_sight(tile_pos, player_pos)
	-- p1 = tile
	-- p2 = player
	local distance = {}
	distance.x = player_pos.x - tile_pos.x
	distance.y = player_pos.y - tile_pos.y

	local direction = {}
	if distance.x < 0 then direction.x = -1 else direction.x = 1 end
	if distance.y < 0 then direction.y = -1 else direction.y = 1 end

	-- special case: all tiles one tile or closer are visible
	if math.abs(distance.x)<=1 and math.abs(distance.y)<=1 then
		return true
	end
	
	-- special case: is the tile one step from player in x
	if math.abs(distance.x) == 1 then
		for tile_y = (tile_pos.y + direction.y), player_pos.y, direction.y do
			if not self:is_tile_passable(player_pos.x, tile_y) then
				return false
			end
		end
		return true
	end
	
	-- special case: is the tile one step from player in y
	if math.abs(distance.y) == 1 then
		for tile_x = (tile_pos.x + direction.x), player_pos.x, direction.x do
			if not self:is_tile_passable(tile_x, player_pos.y) then
				return false
			end
		end
		return true
	end
	
	-- no special cases, run full check:
	local steps = math.max(math.abs(distance.x), math.abs(distance.y))

	local delta = {x=1, y=1}
	if steps > 0 then
		delta.x = distance.x/steps
		delta.y = distance.y/steps
	end
	
	local tile = {}

	for step = 1, steps do
		tile.x = math.ceil(tile_pos.x + (step * delta.x) - 0.5)
		tile.y = math.ceil(tile_pos.y + (step * delta.y) - 0.5)

		if not self:is_tile_passable(tile.x, tile.y) then
			-- line of sight is blocked!
			return false
		end
	end

	return true -- if p1 can see p2
end

