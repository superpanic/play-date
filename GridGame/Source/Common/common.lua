import "CoreLibs/graphics"

playdate.display.setScale(1)

grid_size = 16
screen_width = playdate.display.getWidth()
screen_height = playdate.display.getHeight()

libgfx = playdate.graphics
libspr = playdate.graphics.sprite
libpnt = playdate.geometry.point

function table_to_string(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. table_to_string(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end
