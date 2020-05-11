import 'fps/font-table-6-10.png'
import 'fps/bg.png'

local ms = playdate.getCurrentTimeMilliseconds
local floor = math.floor

local bg = playdate.graphics.image.new('CoreLibs/utilities/fps/bg')
local font = playdate.graphics.imagetable.new('CoreLibs/utilities/fps/font')

local lastFrameTime = ms()
local MAXSAMPLES = 10
local tickindex = 1
local defaultFrame = 50
local ticksum = defaultFrame * MAXSAMPLES
local ticklist = {}
for i=1,MAXSAMPLES do
    ticklist[i] = defaultFrame
end

local function calcAverageTick(newtick)
	ticksum -= ticklist[tickindex]  -- subtract value falling off
	ticksum += newtick              -- add new value
	ticklist[tickindex] = newtick   -- save new value so it can be subtracted later
	tickindex += 1
	if tickindex>MAXSAMPLES then    -- inc buffer index
		tickindex -= MAXSAMPLES
	end
	-- return average
	return ticksum / MAXSAMPLES
end

function fps(x,y)
	-- draw fps
	local currentTime = ms()
	local avgTick = calcAverageTick(currentTime - lastFrameTime)
	local fps = floor((1000/avgTick) + 0.5)
	if avgTick == 0 then fps = 0 end -- every so often avgTick is 0 which leads to a crash below

	lastFrameTime = currentTime
	
	local tens = floor(fps / 10)
	local ones = fps - tens * 10
	
	bg:drawIgnoringOffsetAt(x,y)
	local tensImage = font:getImage(tens+1)
	local onesImage = font:getImage(ones+1)
	if tensImage ~= nil and onesImage ~= nil then
		tensImage:drawIgnoringOffsetAt(x+2,y+2)
		onesImage:drawIgnoringOffsetAt(x+2+7,y+2)
	end
end