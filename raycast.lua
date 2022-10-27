local Object = require("lib.classic")

local wallShader = love.graphics.newShader([[
    #ifdef PIXEL
    uniform vec2 drawDimensions;
    uniform ArrayImage textures;
    uniform Image dataBuffer;
    uniform float cameraOffset = 0;
    uniform float cameraTilt = 0;
    uniform float drawDepth = 1;
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec2 column = vec2(screen_coords.x/drawDimensions.x, 0);
        float middle = drawDimensions.y /2;

        vec4 data = Texel(dataBuffer, column);
        float textureId = data.r;
        float wallHeight = data.g ;
        float u = data.b;
        float shade = data.a;
        float distance = Texel(dataBuffer, vec2(screen_coords.x/drawDimensions.x, 1)).r;

        float ceilling = (drawDimensions.y/2) - (wallHeight/2) + (cameraOffset / distance) + cameraTilt;
        float floor = ceilling + wallHeight;
        float v = (screen_coords.y-ceilling) / wallHeight;

        
        if (screen_coords.y < ceilling || screen_coords.y > floor) {
            discard;
        }
        
        vec3 colour = Texel(textures, vec3(u,v, textureId)).rgb * shade;
        gl_FragDepth = distance / drawDepth;
        return vec4(colour, 1);
    }
    #endif
]])


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
    wallShader:send("drawDimensions", {width, height})
    wallShader:send("drawDepth", maxDepth)
    if raycast.dataBuffer then raycast.dataBuffer:release() end
    

    raycast.rayDir = vector()
    raycast.dataBuffer = love.image.newImageData(width, 2, "rgba16f")
    raycast.dataBufferTexture = love.graphics.newImage(raycast.dataBuffer)
    raycast.result = RayCastResult()
    raycast.zBuffer = {}
    raycast.maxDepth = maxDepth
    raycast.shadeDepth = shadeDepth

    for x=0,width-1 do
        raycast.dataBuffer:setPixel(x, 0, 0,math.random(),0,1)
    end
    
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
            side = 2
        end

        if mapCheck.x >= 0 and mapCheck.x < 16 and mapCheck.y >= 0 and mapCheck.y < 16 then
            local i = (mapCheck.y * 16) + mapCheck.x
            
            local id = map[i+1]
            if id > 0 then
                result.tileId = id
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
            
                if side == 2 then
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
                    if side == 2 then
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

    local h = 64
    local result = raycast.result
    local maxHeight = 0
    for x = 0,raycast.width-1 do
        local rayAngle = startAngle + (x * angleStep)
        
        rayDir.x = cos(rayAngle)
        rayDir.y = sin(rayAngle)
       
        -- cast ray into the scene for this screen column
        if rayCastDDA(position, rayDir, map, result) then
            -- collect data pertinent to render step, try and push as much conditional as possible here (i.e., anything that is per-column), 
            -- as conditionals will slow down the column render step
            
            local correctedRayLength = result.rayLength * cos(rayAngle - angle)
            local wallHeight = raycast.height/correctedRayLength
            local ceilling = (raycast.height/2)-(wallHeight/2)  + (headOffset /correctedRayLength) + tilt
            local floor = ceilling + wallHeight
            local shade = 1 
            local collisionSide = result.collisionSide
            
            if collisionSide == WallSide.West or collisionSide == WallSide.East then
                shade = 0.8
            end
            
            shade = shade *  1 - (correctedRayLength/raycast.shadeDepth)
            
            local u = result.u

            raycast.dataBuffer:setPixel(x, 0, result.tileId, wallHeight, u, shade)
            raycast.dataBuffer:setPixel(x, 1, correctedRayLength,0,0,0)
        
            maxHeight = math.max(maxHeight, wallHeight)
        
        end
        

        totalChecks = totalChecks + result.totalChecks
    end
    local raycastTime = (love.timer.getTime() - start)
    start = love.timer.getTime()

    raycast.dataBufferTexture:replacePixels(raycast.dataBuffer)

    wallShader:send("dataBuffer", raycast.dataBufferTexture)
    wallShader:send("textures", debugTexture)
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