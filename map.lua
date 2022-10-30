local ffi = require("ffi")
local Object = require("lib.classic")

local Map = Object:extend()

ffi.cdef[[
    typedef struct {uint8_t type, tileId;} wall;
    typedef struct {uint8_t tileId, nu1, nu2, nu3; } surface;
]]

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
        self:rebuild()
    else
        self.data = {}
        for i=1,width*height do 
            self.data[i] = {type=-1, tileId=-1}
            self.data[i+width*height] = {tileId=-1}
            self.data[i+width*height*2] = {tileId=-1}
        end
        self:rebuild()
    end
end

function Map:rebuild()
    local width, height, data = self.width, self.height, self.data
    if self.floorsTexture then self.floorsTexture:release() end
    if self.ceillingsTexture then self.ceillingsTexture:release() end

    local floorImageData = love.image.newImageData(width, height, "rgba16f")
    local ceillingImageData = love.image.newImageData(width, height, "rgba16f")
    for y=0,height-1 do
        for x=0,width-1 do
            local floorTile = self:getFloorTileAt(x,y)
            local ceillingTile = self:getCeillingTileAt(x,y)
            floorImageData:setPixel(x, y, floorTile.tileId, 0,0,0)
            ceillingImageData:setPixel(x, y, ceillingTile.tileId, 0,0,0)
        end
    end

    self.floorsTexture = love.graphics.newImage(floorImageData)
    self.ceillingsTexture = love.graphics.newImage(ceillingImageData)
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