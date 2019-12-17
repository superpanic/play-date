import "CoreLibs/graphics"

playdate.display.setScale(2)

grid_size = 16
screen_width = playdate.display.getWidth()
screen_height = playdate.display.getHeight()
edge_limit = 3

libgfx = playdate.graphics
libspr = playdate.graphics.sprite
libpnt = playdate.geometry.point

global_beings_data = playdate.datastore.read('Being/beings')
if(global_beings_data == nil) then print("cound not read being data") end

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

function print_item_names(t)
	for _, i in ipairs(t) do print(i.name) end
end