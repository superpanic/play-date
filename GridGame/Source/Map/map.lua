class('Map').extends()

function Map:init()
	Map.super.init(self)
	self.maps = {}
	self.maxWidth = 10
	self.maxHeight = 10
	self.legend = {
		FLOOR     = 1,
		WALL      = 2,
		WALL_EDGE = 3,
		DOOR      = 4
	}
end

function Map:generate()
	
end

-- all maps have an entry
-- not all maps have an exit
-- start generating in the middle
-- start with a floor type
-- extend out
-- if we reach edge add wall
