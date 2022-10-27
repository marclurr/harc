local Object = require("lib.classic")

local wallShader = love.graphics.newShader("walls.glsl")

WallSide = {
    North = 1,
    East = 2,
    South = 3,
    West = 4
}


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


sin = math.sin
cos = math.cos

local raycast = {}

raycast.init = function(width, height, maxDepth, shadeDepth)
    raycast.width = width
    raycast.height = height

    
    raycast.rayDir = vector()
    --[[ 
        data buffer is an image the width of the render canvas, with a height of 2. Wall render data is pushed here before being rendered
        by the wall shader. A height of 2 allows up to 8 values per column (2*rgba) to be sent to the shader. More rows can be added to allow more data transfer
        but the point of using a shader is to minimise the number of 'pixels' written to by the CPU, so it's best that this be kept to just what's
        necessary. 

        pixel format rgba16f allows values to have a range of [-65504, +65504], which should be more than ample. See https://love2d.org/wiki/PixelFormat
        data layout:
        __________________________________________________________
        |     | r         | g             | b         | a         |
        |=====|===========|===============|===========|===========|
        | 0   | textureId | wallHeight    | texture U | shade     |
        | 1   | rayLength | not used      | not used  | not used  |
        |_____|___________|_______________|___________|___________|
    ]]
    if raycast.dataBuffer then raycast.dataBuffer:release() end
    raycast.dataBuffer = love.image.newImageData(width, 2, "rgba16f") 
    raycast.dataBufferTexture = love.graphics.newImage(raycast.dataBuffer)

    raycast.result = RayCastResult()
    raycast.maxDepth = maxDepth
    raycast.shadeDepth = shadeDepth    

    wallShader:send("drawDimensions", {width, height})
    wallShader:send("drawDepth", maxDepth)
    wallShader:send("dataBuffer", raycast.dataBufferTexture)
    wallShader:send("textures", debugTexture)
end

local function rayCastDDA(rayStart, rayDir, map, result)
    result:reset()

    local rayUnitStepSize = vector(math.sqrt(1+(rayDir.y/rayDir.x)*(rayDir.y/rayDir.x)), math.sqrt(1+(rayDir.x/rayDir.y)*(rayDir.x/rayDir.y)))
    local mapCheck = vector(math.floor(rayStart.x), math.floor(rayStart.y))
    local rayLength  = vector(0, 0)
    local step = vector(0, 0)

    if rayDir.x < 0 then
        step.x = -1
        rayLength.x = (rayStart.x - mapCheck.x) * rayUnitStepSize.x
    else
        step.x = 1
        rayLength.x = (mapCheck.x + 1 - rayStart.x) * rayUnitStepSize.x
    end

    if rayDir.y < 0 then
        step.y = -1
        rayLength.y = (rayStart.y - mapCheck.y) * rayUnitStepSize.y
    else
        step.y = 1
        rayLength.y = (mapCheck.y + 1 - rayStart.y) * rayUnitStepSize.y
    end

    local tileFound = false
    local maxDistance = raycast.maxDepth
    local distance = 0
    local side = -1
    local numChecks = 0
    
    raycast.visibleTiles[(mapCheck.y * 16) + mapCheck.x +1] = true
    while distance < maxDistance do
        numChecks = numChecks + 1
        if rayLength.x < rayLength.y then
            mapCheck.x = mapCheck.x + step.x
            distance = rayLength.x
            rayLength.x = rayLength.x + rayUnitStepSize.x
            side = 1
        else
            mapCheck.y = mapCheck.y + step.y
            distance = rayLength.y
            rayLength.y = rayLength.y + rayUnitStepSize.y
            side = 0
        end

        if mapCheck.x >= 0 and mapCheck.x < 16 and mapCheck.y >= 0 and mapCheck.y < 16 then
            local i = (mapCheck.y * 16) + mapCheck.x
            
            local id = map[i+1]
            if id > 0 then
                result.tileId = id
                result.x = mapCheck.x
                result.y = mapCheck.y
                result.rayLength = distance
                result.totalChecks = numChecks
                result.side = side
                result.collisionOccurred = true
                result.collisionPoint.x = rayStart.x + (rayDir.x * distance)
                result.collisionPoint.y = rayStart.y + (rayDir.y * distance)
            
                if side == 1 then 
                    if rayDir.x >= 0 then
                        result.collisionSide = WallSide.West
                        result.u = math.remainder(result.collisionPoint.y)
                    elseif rayDir.x <= 0 then
                        result.collisionSide = WallSide.East
                        result.u = 1- math.remainder(result.collisionPoint.y)
                    end
                end
            
                if side == 0 then
                    if rayDir.y >= 0 then
                        result.collisionSide = WallSide.North
                        result.u =  1- math.remainder(result.collisionPoint.x)
                    elseif rayDir.y <= 0 then
                        result.collisionSide = WallSide.South
                        result.u = math.remainder(result.collisionPoint.x)
                    end
                end
            
                   
                if id == 2  then -- horizontal thin, animatable wall
                    --[[
                        - determine x-axis gradient of ray direction 
                        - extend the ray by the amount required to reach the centre of the tile on the y-axis
                        - recalculate collision point
                        - if the extended ray is still within the horizontal bounds of this tile then collision occurred
                        -- horizontal bounds can be truncated, this allows for animatable objects like doors
                    --]]
                    local m = rayDir.x / rayDir.y
                    local dy = 0.5
                    local dx =  0
                    if side == 1 then
                        --[[
                            if the ray entered the tile on the y-axis we need to readjust the y-delta to reach the mid-point of the tile
                            We just remove the collision point's fractional y value from the mid-point
                        --]]
                        if rayDir.y <= 0 then
                            dy = (1-dy) -  math.remainder(result.collisionPoint.y)
                        elseif rayDir.y >= 0 then
                            dy = (dy) -  math.remainder(result.collisionPoint.y)
                        end    
                    end
                    dx = m * dy

                    distance = distance + vector(dx, dy):len()
                    result.rayLength = distance 
                    result.collisionPoint.x = rayStart.x + (rayDir.x * distance)
                    result.collisionPoint.y = rayStart.y + (rayDir.y * distance)
                    local offset=0.5
                    result.u =  math.remainder(result.collisionPoint.x) - offset

                    if  result.collisionPoint.x >= mapCheck.x+offset and result.collisionPoint.x < mapCheck.x+1 then
                        return true
                    end
            
                elseif id == 3  then -- vertical thin, animatable wall
                    --[[
                        - determine y-axis gradient of ray direction
                        - extend the ray by the amount required to reach the centre of the tile on the x-axis
                        - recalculate collision point
                        - if the extended ray is still within the vertical bounds of this tile then collision occurred
                        -- vertical bounds can be truncated, this allows for animatable objects like doors
                    --]]
                    local m = rayDir.y / rayDir.x
                    local dx =0.5
                    local dy =  0
                    if side == 0 then
                        --[[
                            if the ray entered the tile on the x-axis we need to readjust the x-delta to reach the mid-point of the tile
                            We just remove the collision point's fractional x value from the mid-point
                        --]]
                        if rayDir.x <= 0 then
                            dx = (1-dx) -  math.remainder(result.collisionPoint.x)
                        elseif rayDir.x >= 0 then
                            dx = (dx) -  math.remainder(result.collisionPoint.x)
                        end    
                    end
                    dy = m * dx

                    distance = distance + vector(dx, dy):len()
                    result.rayLength = distance 
                    result.collisionPoint.x = rayStart.x + (rayDir.x * distance)
                    result.collisionPoint.y = rayStart.y + (rayDir.y * distance)
                    local offset=0
                    result.u = math.remainder(result.collisionPoint.y) - offset
                                     
                    if  result.collisionPoint.y >= mapCheck.y+offset and result.collisionPoint.y < mapCheck.y+1 then
                        return true
                    end
                else -- just a normal wall
                    return true
                end
            else
                raycast.visibleTiles[i+1] = true
            end
        end
    end
    result.totalChecks = numChecks
    
    return false
end

local function renderWalls(position, headOffset, angle, tilt, fov, map)
    raycast.visibleTiles = {}

    local totalChecks = 0
    
    local zBuffer = raycast.zBuffer
    local angleStep = fov / raycast.width
    local startAngle = angle - (fov/2)

    local rayDir = raycast.rayDir

    local start = love.timer.getTime()

    local result = raycast.result
    for x = 0,raycast.width-1 do
        local rayAngle = startAngle + (x * angleStep)
        
        rayDir.x = cos(rayAngle)
        rayDir.y = sin(rayAngle)
       
        -- cast ray into the scene for this screen column
        if rayCastDDA(position, rayDir, map, result) then
            -- collect data pertinent to render step and push into a texture to be read by the wall shader 
            local correctedRayLength = result.rayLength * cos(rayAngle - angle)
            local wallHeight = raycast.height/correctedRayLength
            local shade = (1 - (0.2 * result.side)) * (1 - (correctedRayLength/raycast.shadeDepth))

            raycast.dataBuffer:setPixel(x, 0, result.tileId, wallHeight, result.u, shade)
            raycast.dataBuffer:setPixel(x, 1, correctedRayLength,correctedRayLength/raycast.maxDepth,0,0)      
        end

        totalChecks = totalChecks + result.totalChecks
    end
    local raycastTime = (love.timer.getTime() - start)
    start = love.timer.getTime()

    raycast.dataBufferTexture:replacePixels(raycast.dataBuffer)


    wallShader:send("cameraOffset", headOffset)
    wallShader:send("cameraTilt", tilt)

    love.graphics.setShader(wallShader)
    love.graphics.rectangle("fill", 0, 0, raycast.width, raycast.height)
    love.graphics.setShader()
    
    local renderTime = (love.timer.getTime() - start) 

    return totalChecks, raycastTime*1000000, renderTime*1000000
end


raycast.renderWalls = renderWalls
raycast.rayCastDDA = rayCastDDA
return raycast