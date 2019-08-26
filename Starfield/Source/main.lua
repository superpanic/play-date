import "CoreLibs/graphics"
import "CoreLibs/utilities/fps"

playdate.display.setScale(1)
local screen_width = playdate.display.getWidth()
local screen_height = playdate.display.getHeight()

local nstars_list = {10,50,100,250,500,750,1000,1500}
local nstars_list_len = 8
local nstars_index = 1
local nstars = nstars_list[nstars_index]

local libgfx = playdate.graphics

local speed = 0.0
local stars = {}

local circle_flag = true

playdate.display.setRefreshRate(0)

function star()
	-- return a star 'struct'
	return {
		xpos = (math.random(screen_width)  - screen_width / 2.0) / 100.0,
		ypos = (math.random(screen_height) - screen_height / 2.0) / 100.0,
		velocity = math.random(110,130) / 100.0
	}
end

function playdate.update()
	libgfx.clear()
	for i = 1, nstars do
		local x = stars[i].xpos + screen_width  / 2.0
		local y = stars[i].ypos + screen_height / 2.0
		local size = (math.abs(stars[i].xpos) + math.abs(stars[i].ypos)) * 0.025 + 2.0
		if circle_flag == true then
			libgfx.fillCircleInRect(x, y, size, size)
		else
			libgfx.drawPixel(x,y)
		end
		stars[i].xpos *= (stars[i].velocity + speed)
		stars[i].ypos *= (stars[i].velocity + speed)
		if x < 0 or x > screen_width or y < 0 or y > screen_height then
			stars[i] = star()
		end
	end
	fps(10,10)
	libgfx.drawText(nstars_list[nstars_index].." stars locked to "..math.floor(playdate.display.getRefreshRate()).." fps", 10,screen_height-30 )
end

function playdate.cranked(change, acceleratedChange)
	speed += change * 0.0001
end

function playdate.AButtonDown()
	-- invert color
	playdate.display.setInverted(not playdate.display.getInverted())
end

function playdate.BButtonDown()
	-- increase number of stars
	if nstars_index < nstars_list_len then
		nstars_index++
	else
		nstars_index = 1
	end
	nstars = nstars_list[nstars_index]
	setup()
end

function playdate.upButtonDown()
	playdate.display.setRefreshRate(30)
end

function playdate.downButtonDown()
	playdate.display.setRefreshRate(0)
end

function playdate.leftButtonDown()
	circle_flag = not circle_flag
end

function setup()
	playdate.graphics.setColor(playdate.graphics.kColorXOR)
	for i = 1, nstars do
		stars[i] = star()
	end
end

setup()
