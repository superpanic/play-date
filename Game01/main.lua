import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "Player/player"

playdate.display.setScale(2)

--local crabImage = playdate.graphics.image.new("source/crab.gif")
local player = Player(playdate.graphics.image.new("source/crab.gif"))
--local crabSprite = playdate.graphics.sprite.new()

--crabSprite:setImage(crabImage)
player:moveTo(10,10)
--crabSprite:add()

print("health: " .. player.health)

function playdate.update()
	-- sprite needs to update
	playdate.graphics.sprite:update()	
end

function playdate.AButtonDown()
	local kIncr = 0
	print(kIncr)
	kIncr++
end

