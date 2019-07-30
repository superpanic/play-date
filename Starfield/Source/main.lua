
-- 1. draw a pixel on screen
-- 2. arrange an array of pixels
-- 3. random position of pixels
-- 4. multiply pixel position with velocity

-- 5. do the same with C
	
import "CoreLibs/graphics"

local pos = 0
local velocity = 1.05
local star_x = {}
local star_y = {}

function playdate.update()
	playdate.graphics.clear()
	for i = 1, 20 do
		playdate.graphics.fillCircleInRect(star_x[i],star_y[i],5,5)
	end
end

function setup()
	for i = 1, 20 do
		star_x[i] = math.random(200)
		star_y[i] = math.random(200)
	end
end

setup()
