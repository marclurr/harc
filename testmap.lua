local Map = require("map")

local mapData = {}
mapsize=24
for i=0,(mapsize*mapsize)-1 do
    local x = (i)% mapsize
    local y = math.floor((i)/mapsize)

    local wall = {type=-1}
    local floor = {tileId=-1}
    local ceilling = {tileId=-1}
    
    if y == 0 or y == mapsize-1 or x == 0 or x == mapsize-1 then 
        wall = {type=1, tileId=math.random(0,2)}
    else
        

        if y > 4 and math.random() > 0.85 then
            wall = {type=1, tileId=math.random(0,2)}
        end
        
        floor = {tileId=math.random(0,2)}
        ceilling = {tileId=math.random(0,2)}  
        
        if x == 1 or y == 1 then
            floor.tileId=2
            ceilling.tileId=2
        end
    end

    mapData[i+1]=wall
    mapData[i+1+(mapsize*mapsize)]=floor
    mapData[i+1+(mapsize*mapsize*2)]=ceilling
end

local texturePack = love.graphics.newArrayImage({"assets/textures/debug.png", "assets/textures/danger-wall.png", "assets/textures/door.png"})
local map = Map(mapsize, mapsize, texturePack, mapData)
map:getWallTileAt(3,0).type = 2
map:getFloorTileAt(3,0).tileId = 0
map:getCeillingTileAt(3,0).tileId = 0
map:getWallTileAt(3,0).offset = 0.5

map:getWallTileAt(6,0).type = 2
map:getWallTileAt(6,0).tileId = 0
map:getWallTileAt(6,0).offset = 0
map:getFloorTileAt(6,0).tileId = 0
map:getCeillingTileAt(6,0).tileId = 0

map:getWallTileAt(0,3).type = 3
map:getFloorTileAt(0,3).tileId = 0
map:getCeillingTileAt(0,3).tileId = 0
map:getWallTileAt(0,3).offset = 0.75
map:rebuildFloorAndCeiling()

return map