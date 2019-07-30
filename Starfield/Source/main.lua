-- 5. do the same with C
	
import "CoreLibs/graphics"

playdate.display.setScale(1)
local screen_width = playdate.display.getWidth() + .0
local screen_height = playdate.display.getHeight() + .0

local nstars = 1000

local velocity = 1.2
local star_x = {}
local star_y = {}

local star = {
	xpos = 0,
	ypos = 0,
	velocity = 0
}

function playdate.update()
	playdate.graphics.clear()
	for i = 1, nstars do
		local x = star_x[i] + screen_width / 2.0
		local y = star_y[i] + screen_height / 2.0
		playdate.graphics.fillCircleInRect(x, y, 5, 5)
		star_x[i] *= velocity
		star_y[i] *= velocity
		
		if x < 0 or x > screen_width then
			star_x[i] = (math.random(screen_width) - screen_width / 2) / 100.0
		end
		if y < 0 or y > screen_height then
			star_y[i] = (math.random(screen_height) - screen_height / 2.0) / 100.0
		end
		
	end
end

function setup()
	for i = 1, nstars do
		star_x[i] = (math.random(screen_width) - screen_width / 2.0) / 100.0
		star_y[i] = (math.random(screen_height) - screen_height / 2.0) / 100.0
	end
end

setup()
