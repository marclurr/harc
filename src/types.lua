Object = require("lib.classic")
vector = require("lib.hump.vector")

WallSide = {
    North = 1,
    East = 2,
    South = 3,
    West = 4
}



-- originally an experiment to check whether ImageData was stored GPU side and sampling was slow due to communication overhead.
-- It turns out that wasn't the case but this is marginally quicker, possibly due to the assertions in ImageData, 
-- or mabye multi-return functions are slow in lua - not 100% sure.
-- The performace small improvement enough to make a difference to screen update time so I'm keeping it until I find something better.
-- The drop off scales with image size.
Texture = Object:extend()
function Texture:new(path)
    local imageData = love.image.newImageData(path)
    self.width = imageData:getWidth()
    self.height = imageData:getHeight()
    self.data = {}

    for x=0,self.width-1 do
        for y=0,self.height-1 do
            local i = y * self.width + x
            local r,g,b,a = imageData:getPixel(x,y)
            self.data[i+1] = {r=r,g=g,b=b,a=a}
        end
    end
    imageData:release()
end

function Texture:getWidth() return self.width end
function Texture:getHeight() return self.height end

function Texture:getPixel(x, y) 
    local i = y * self.width + x
    return self.data[i+1]
end



RayCastResult = Object:extend()

function RayCastResult:new()
    self.collisionOccurred = false
    self.collisionPoint = vector()
    self.collisionSide = 0
    self.rayLength = 0
    self.totalChecks = 0
    self.v = 0
end

function RayCastResult:reset()
    self.collisionOccurred = false
    self.collisionPoint.x = 0
    self.collisionPoint.y = 0
    self.collisionSide = 0
    self.rayLength = 0
    self.totalChecks = 0
    self.v = 0
end

