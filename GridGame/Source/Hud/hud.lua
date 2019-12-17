class('Hud').extends(playdate.graphics.sprite)

function Hud:init(plr)
	Hud.super.init(self)
	self.parent = Hud.super.super
	self.player = plr
end

function Hud:update()
	-- update if inventory has changed?
end

function Hud:setup()
	print("setup hud")
end
