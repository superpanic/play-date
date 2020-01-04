class('Hud').extends(playdate.graphics.sprite)

local padding = 2
local hud_height = global_grid_size + padding * 2
local hud_z_index = 2000

function Hud:init(plr)
	Hud.super.init(self)
	self.parent = Hud.super.super
	self.player = plr
end

function Hud:setup()
	print("setup hud")
	self.img = libgfx.image.new(screen_width, hud_height)
	self:setImage(self.img)
	self:add()
	self:setZIndex(hud_z_index)
	libgfx.lockFocus(self.img)
		libgfx.setColor(libgfx.kColorWhite)
		libgfx.fillRect( 0, 0, screen_width, hud_height)
	libgfx.unlockFocus()
	self:moveTo( screen_width/2, screen_height-hud_height/2 )
	self:markDirty()
end

function Hud:update()
	-- update if inventory has changed?
	if self.player.inventory_updated then
		print("updating hud")
		libgfx.lockFocus(self.img)
		for index, item in ipairs(self.player.inventory) do
			im = item:get_image()
			im:drawAt(padding + global_grid_size * (index-1), padding)
		end
		libgfx.unlockFocus()
		self:markDirty()
		self.player.inventory_updated = false
	end
end