local Object = require("lib.classic")
local vector = require("lib.hump.vector")

local Camera = Object:extend()

function Camera:new(fov)
    self.fov = fov
    self.angle = 0
    self.position = vector(0, 0)
    self.positionArray = {0,0}
    self.height = 0
end

function Camera:setPosition(position)
    self.position.x = position.x
    self.position.y = position.y
    self.positionArray[1] = position.x
    self.positionArray[2] = position.y
end

return Camera