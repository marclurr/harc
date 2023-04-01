-- local ffi = require("ffi")
local Object = require("lib.classic")

local Map = Object:extend()

-- ffi.cdef[[
--     typedef struct {uint8_t type, tileId;} wall;
--     typedef struct {uint8_t tileId, nu1, nu2, nu3; } surface;
-- ]]

-- because the floors are queried using a GPU texture, maps ideally should have square, power of 2 dimensions 
function Map:new(width,height, texturePack, data)
    self.width = width
    self.height = height
    self.dimensions = {width, height}
    self.floorOffset = (width*height)
    self.ceillingOffset = (width*height)*2
    self.texturePack = texturePack
    
    if data then
        self.data = data
        assert(#data == 3*width*height, "Data buffer should be 3x" .. (width*height))
        self:rebuildFloorAndCeiling()
    else
        self.data = {}
        for i=1,width*height do 
            self.data[i] = {type=-1, tileId=-1}
            self.data[i+width*height] = {tileId=-1}
            self.data[i+width*height*2] = {tileId=-1}
        end
        self:rebuildFloorAndCeiling()
    end
end

function Map:rebuildFloorAndCeiling()
    local width, height, data = self.width, self.height, self.data


    local floorImageData = love.image.newImageData(width, height, "rgba16f")
    local ceillingImageData = love.image.newImageData(width, height, "rgba16f")

    if not self.floorsTexture then self.floorsTexture = love.graphics.newImage(floorImageData) end
    if not self.ceillingsTexture then self.ceillingsTexture = love.graphics.newImage(ceillingImageData) end

    for y=0,height-1 do
        for x=0,width-1 do
            local floorTile = self:getFloorTileAt(x,y)
            local ceillingTile = self:getCeillingTileAt(x,y)
            floorImageData:setPixel(x, y, floorTile.tileId, 0,0,0)
            ceillingImageData:setPixel(x, y, ceillingTile.tileId, 0,0,0)
        end
    end

    self.floorsTexture:replacePixels(floorImageData)
    self.ceillingsTexture:replacePixels(ceillingImageData)
    floorImageData:release()
    ceillingImageData:release()
end

function Map:getWallTileAt(x, y)
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return nil
    end
    local i = (y * self.width + x) + 1
    return self.data[i]
end

function Map:getFloorTileAt(x, y)
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return nil
    end
    local i = (y * self.width + x) + 1 + self.floorOffset
    return self.data[i]
end

function Map:getCeillingTileAt(x, y)
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return nil
    end
    local i = (y * self.width + x) + 1 + self.ceillingOffset
    return self.data[i]
end

return Map