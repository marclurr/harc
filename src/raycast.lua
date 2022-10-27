local Object = require("lib.classic")

sin = math.sin
cos = math.cos

local raycast = {}

raycast.init = function(screenBuffer)
    raycast.width = screenBuffer:getWidth()
    raycast.height = screenBuffer:getHeight()
    if raycast.screenImage then raycast.screenImage:release() end
    if raycast.screenImageData then raycast.screenImageData:release() end

    raycast.rayDir = vector()
    raycast.screenImageData = screenBuffer 
    raycast.result = RayCastResult()
    raycast.zBuffer = {}
    
    -- for i=1,raycast.width*raycast.height do
    --     raycast.zBuffer[i] = 0
    -- end
    
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
    local maxDistance = 50.0
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
    for i=1,raycast.width*raycast.height do
        raycast.zBuffer[i] = 10000
    end
    -- local headOffset = 0
    raycast.visibleTiles = {}

    local totalChecks = 0
    
    local zBuffer = raycast.zBuffer
    local angleStep = fov / raycast.width
    local startAngle = angle - (fov/2)

    local rayDir = raycast.rayDir

    local start = love.timer.getTime()

    local h = 64
    local result = raycast.result
    for x = 0,raycast.width-1 do
        local rayAngle = startAngle + (x * angleStep)
        
        rayDir.x = cos(rayAngle)
        rayDir.y = sin(rayAngle)
       
        -- cast ray into the scene for this screen column
        if rayCastDDA(position, rayDir, map, result) then
            -- collect data pertinent to render step, try and push as much conditional as possible here (i.e., anything that is per-column), 
            -- as conditionals will slow down the column render step
            
            local correctedRayLength = result.rayLength * cos(rayAngle - angle)
            local wallHeight = DRAW_HEIGHT/correctedRayLength
            local ceilling = (DRAW_HEIGHT/2)-(wallHeight/2)  + (headOffset /correctedRayLength) + tilt
            local floor = ceilling + wallHeight
            local shade = 1 
            local collisionSide = result.collisionSide
            
            if collisionSide == WallSide.West or collisionSide == WallSide.East then
                shade = 0.8
            end
            local shadeDepth = 16
            
            shade = shade *  1 - (correctedRayLength/shadeDepth)
            
            local u = (result.u ) % 1

            local t= textureDebug

            for y = 0, math.min(raycast.height-1,math.max(0,ceilling+1)) do
                y = math.floor(y)
                local z = ((DRAW_HEIGHT*0.5)- headOffset) / (  (DRAW_HEIGHT*0.5+tilt) -y )
                local s = 1 - (z/shadeDepth)
                local ppx = position.x + rayDir.x * (z  / cos(rayAngle-angle)) 
                local ppy = position.y + rayDir.y * (z  / cos(rayAngle-angle)) 
                local u,v = 1-math.remainder(ppx), math.remainder(ppy)
                local p = t:getPixel(math.floor((t:getWidth()*math.min(0.99,u))), math.floor((t:getHeight()) * math.min(0.99,v)))
                if p then
                    raycast.screenImageData:setPixel(x, y, p.r*s,p.g*s,p.b*s, p.a)
                end
            end

            t = texturesCpu[collisionSide]
            for y = math.max(0,ceilling),math.min(raycast.height, floor+1) do
                y = math.min(raycast.height-1,math.floor(y))
                zBuffer[(y*raycast.width) + x+1] = result.rayLength
                local v = ((y - ceilling ) / ((wallHeight+1))) % 1.1
                local p = t:getPixel(math.floor((t:getWidth()*math.min(0.99,u))), math.floor((t:getHeight()) * math.min(0.99,v)))

                if p then
                    raycast.screenImageData:setPixel(x, y, p.r * shade, p.g* shade, p.b*shade, p.a)
                end
            end
           
            
            t= textureDebug
            for y = math.max(0,floor), raycast.height do
                y = math.min(raycast.height-1,math.floor(y))
                
                local z = ((DRAW_HEIGHT*0.5)+ headOffset) / ( (y - (DRAW_HEIGHT*0.5+tilt) ))
                local s = 1 - (z/shadeDepth)
                local ppx = position.x + rayDir.x * (z   / cos(rayAngle-angle)) 
                local ppy = position.y + rayDir.y * (z   / cos(rayAngle-angle)) 
                local u,v = math.remainder(ppx), math.remainder(ppy)
                
                local p = t:getPixel(math.floor((t:getWidth()*math.min(0.99,u))), math.floor((t:getHeight()) * v))             
                if p then
                    raycast.screenImageData:setPixel(x, y, p.r*s,p.g*s,p.b*s, p.a)
                end
               

            end
        end


        totalChecks = totalChecks + result.totalChecks
    end
    local raycastTime = (love.timer.getTime() - start) * 1000
    local renderTime = (love.timer.getTime() - start) * 1000.0

    return totalChecks, raycastTime, renderTime
end


raycast.renderWalls = renderWalls
raycast.rayCastDDA = rayCastDDA
return raycast