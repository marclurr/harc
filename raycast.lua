local Object = require("lib.classic")
local vector = require("lib.hump.vector")

local wallShader = love.graphics.newShader("shaders/walls.glsl")
local floorShader = love.graphics.newShader("shaders/floor.glsl")
local ceillingShader = love.graphics.newShader("shaders/ceilling.glsl")
local spriteShader = love.graphics.newShader("shaders/sprite.glsl")

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

raycast.init = function(width, height, maxDepth, shadeDepth, drawCanvas)
    raycast.width = width
    raycast.height = height

    raycast.drawCanvas = drawCanvas
    raycast.sprDepthBuffer = love.graphics.newCanvas(width, height, {type = "2d", format = "depth16", readable = true})
    raycast.spriteMode = {raycast.drawCanvas, depthstencil = raycast.sprDepthBuffer}
    raycast.justDepthBuffer = {depthstencil = raycast.sprDepthBuffer}
    raycast.rayDir = vector()
    --[[ 
        data buffer is an image the width of the render canvas, with a height of 2. Wall render data is pushed here before being rendered
        by the wall shader. A height of 2 allows up to 8 values per column (2*rgba) to be sent to the shader. More rows can be added to allow more data transfer
        but the point of using a shader is to minimise the number of 'pixels' written to by the CPU, so it's best that this be kept to just what's
        necessary. 

        pixel format rgba16f allows values to have a range of [-65504, +65504], which should be more than ample. See https://love2d.org/wiki/PixelFormat
        data layout:
        ________________________________________________________________________
        |     | r         | g                           | b         | a         |
        |=====|===========|=============================|===========|===========|
        | 0   | textureId | wallHeight                  | texture U | shade     |
        | 1   | rayLength | normalised ray length       | not used  | not used  |
        |_____|___________|_____________________________|___________|___________|
    ]]
    if raycast.dataBuffer then raycast.dataBuffer:release() end
    raycast.dataBuffer = love.image.newImageData(width, 2, "rgba16f") 
    raycast.dataBufferTexture = love.graphics.newImage(raycast.dataBuffer)

    raycast.result = RayCastResult()
    raycast.maxDepth = maxDepth
    raycast.shadeDepth = shadeDepth    

    wallShader:send("dataBuffer", raycast.dataBufferTexture)

    raycast.spriteProjectionMatrix = ortho(0, width, height, 0, 0, maxDepth)
    spriteShader:send("spriteProjectionMatrix", raycast.spriteProjectionMatrix)
    spriteShader:send("shadeDepth", raycast.shadeDepth)

    ceillingShader:send("width", raycast.width)
    ceillingShader:send("height", raycast.height/2)
    ceillingShader:send("shadeDepth", raycast.shadeDepth)
    
    floorShader:send("width", raycast.width)
    floorShader:send("height", raycast.height/2)
    floorShader:send("shadeDepth", raycast.shadeDepth)
    

    raycast.stats = {
        floorRenderTime = 0,
        ceillingRenderTime = 0,
        wallsRenderTime = 0,
        spritesRenderTime = 0,
        numChecks = 0
    }
end


local rayUnitStepSize = vector()
local mapCheck = vector()
local rayLength  = vector(0, 0)
local step = vector(0, 0)

local function rayCastDDA(rayStart, rayDir, map, result)
    result:reset()

    rayUnitStepSize.x = math.sqrt(1+(rayDir.y/rayDir.x)*(rayDir.y/rayDir.x))
    rayUnitStepSize.y =  math.sqrt(1+(rayDir.x/rayDir.y)*(rayDir.x/rayDir.y))
    mapCheck.x = math.floor(rayStart.x)
    mapCheck.y =  math.floor(rayStart.y)
    rayLength.x, rayLength.y = 0, 0
    step.x, step.y = 0, 0

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

    result.dx = rayDir.x
    result.dy = rayDir.y
    
    -- raycast.visibleTiles[(mapCheck.y * 256) + mapCheck.x +1] = true
    while distance <= maxDistance do
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

  
        local wall = map:getWallTileAt(mapCheck.x, mapCheck.y)
        if wall then
            local i = (mapCheck.y * mapsize) + mapCheck.x
            
            local id = wall.type
            if wall.type > 0 then
                result.tileId = wall.tileId
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
            
                
                if wall.type == 2  then -- horizontal thin, animatable wall
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
                    local doCheck = true
                    if side == 1 then
                        --[[
                            if the ray entered the tile on the y-axis we need to readjust the y-delta to reach the mid-point of the tile
                            We just remove the collision point's fractional y value from the mid-point
                        --]]
                        if rayDir.y < 0 then
                            doCheck = math.remainder(result.collisionPoint.y) > 0.5
                            dy = (1-dy) -  math.remainder(result.collisionPoint.y)
                        elseif rayDir.y > 0 then
                            doCheck = math.remainder(result.collisionPoint.y) < 0.5
                            dy = (dy) -  math.remainder(result.collisionPoint.y)
                        end    
                    end

                    if doCheck then
                        dx = m * dy

                        local tmpDistance = distance + vector(dx, dy):len()
                        local colX = rayStart.x + (rayDir.x * tmpDistance)
                        local colY = rayStart.y + (rayDir.y * tmpDistance)
                        local offset=wall.offset or 0    

                        if  colX >= mapCheck.x+offset and colX < mapCheck.x+1 then
                            distance = tmpDistance
                            result.rayLength = tmpDistance 
                            result.collisionPoint.x = colX
                            result.collisionPoint.y = colY
                            result.side = 0
                            result.u =  math.remainder(colX) - offset
                            return true
                        end
                    end
                elseif wall.type == 3  then -- vertical thin, animatable wall
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
                    local doCheck = true
                    if side == 0 then
                        --[[
                            if the ray entered the tile on the x-axis we need to readjust the x-delta to reach the mid-point of the tile
                            We just remove the collision point's fractional x value from the mid-point
                        --]]
                        if rayDir.x <= 0 then
                            doCheck = math.remainder(result.collisionPoint.x) > 0.5
                            dx = (1-dx) -  math.remainder(result.collisionPoint.x)
                        elseif rayDir.x >= 0 then
                            doCheck = math.remainder(result.collisionPoint.x) < 0.5
                            dx = (dx) -  math.remainder(result.collisionPoint.x)
                        end    
                    end
                    if doCheck then
                        dy = m * dx

                        local tmpDistance = distance + vector(dx, dy):len()
                        local colX = rayStart.x + (rayDir.x * tmpDistance)
                        local colY = rayStart.y + (rayDir.y * tmpDistance)
                        local offset=wall.offset or 0
                                        
                        if  colY >= mapCheck.y+offset and colY < mapCheck.y+1 then
                            result.rayLength = tmpDistance
                            result.collisionPoint.x = colX
                            result.collisionPoint.y = colY
                            result.side = 1
                            
                            result.u = math.remainder(colY) - offset
                            return true
                        end
                    end
                else -- just a normal wall
                    return true
                end
            else
                -- raycast.visibleTiles[i+1] = true
            end
        end

    end
    result.totalChecks = numChecks
    
    return false
end

local function renderWalls(camera, map)
    local position = camera.position
    local headOffset = camera.height
    local angle = camera.angle
    local fov = camera.fov

    -- raycast.visibleTiles = {}

    local totalChecks = 0
    
    
    local angleStep = fov / raycast.width
    local startAngle = angle - (fov/2)

    local rayDir = raycast.rayDir

    local start = love.timer.getTime()

    local result = raycast.result
    -- collect wall data
    for x = 0,raycast.width-1 do
        local rayAngle = startAngle + (x * angleStep)
        
        rayDir.x = cos(rayAngle)
        rayDir.y = sin(rayAngle)
       
        -- cast ray into the scene for this screen column
        if rayCastDDA(position, rayDir, map, result) then
            -- collect data pertinent to render step and push into a texture to be read by the wall shader 
            local correctedRayLength = result.rayLength * cos(rayAngle - angle)
            local wallHeight = raycast.width/correctedRayLength
            local shade = (1 - (0.5 * result.side)) * (1 - (correctedRayLength/raycast.shadeDepth))
            raycast.dataBuffer:setPixel(x, 0, result.tileId or 0, wallHeight, result.u, shade)
            raycast.dataBuffer:setPixel(x, 1, correctedRayLength,correctedRayLength * (1/raycast.maxDepth),result.dx,result.dy)     
        else
            -- ray reached max length without hitting anything
            raycast.dataBuffer:setPixel(x, 0, 0, 0, 0, 0)
            raycast.dataBuffer:setPixel(x, 1, raycast.maxDepth, 1,result.dx,result.dy)     
        end

        totalChecks = totalChecks + result.totalChecks
    end
    local raycastTime = (love.timer.getTime() - start)
    start = love.timer.getTime()

    raycast.dataBufferTexture:replacePixels(raycast.dataBuffer)


    -- do render
    wallShader:send("cameraOffset", headOffset)
    wallShader:send("textures", map.texturePack)

    love.graphics.setCanvas({raycast.drawCanvas, depthstencil = raycast.sprDepthBuffer})
    love.graphics.setDepthMode("always", true)
    love.graphics.setShader(wallShader)
    love.graphics.rectangle("fill", 0, 0, raycast.width, raycast.height)
    love.graphics.setShader()
    
    local renderTime = (love.timer.getTime() - start) 

    local stats = raycast.stats
    stats.raycastTime = raycastTime
    stats.wallsRenderTime = renderTime
    stats.numChecks = totalChecks
end

local function drawTexturedPlane(shader, top, h, camera, textures, map, dimensions)
    local position = camera.position
    local headOffset = camera.height
    local angle = camera.angle
    local fov = camera.fov

    love.graphics.setShader(shader)
    shader:send("position", camera.positionArray)
    shader:send("textures", textures)
    shader:send("fov", fov)
    shader:send("angle", angle)
    shader:send("cameraOffset", headOffset)
    shader:send("map", map)
    shader:send("mapDimensions", dimensions)
   
    love.graphics.rectangle("fill",0,top,raycast.width,h)
end

local function renderCeillingAndFloor(camera, map)
    local stats = raycast.stats

    love.graphics.setCanvas(raycast.drawCanvas)
    local start = love.timer.getTime()
    drawTexturedPlane(ceillingShader, 0, raycast.height/2, camera, map.texturePack, map.ceillingsTexture, map.dimensions)
    stats.ceillingRenderTime = love.timer.getTime() - start

    start = love.timer.getTime()
    drawTexturedPlane(floorShader, raycast.height/2, raycast.height/2, camera, map.texturePack, map.floorsTexture, map.dimensions)
    stats.floorRenderTime = love.timer.getTime() - start
end

local toSpr = vector(0,0)
local eyeDir = vector(0,0)

local function renderSprites(camera, sprites)
    local position = camera.position
    local headOffset = camera.height
    local angle = camera.angle
    local fov = camera.fov

    love.graphics.setCanvas(raycast.spriteMode)
    love.graphics.setDepthMode("lequal", true)

    love.graphics.setShader(spriteShader)
    
    local start = love.timer.getTime()
    for i=1,#sprites do
        local spr = sprs[i]
        local sprX = spr.position.x - position.x
        local sprY = spr.position.y - position.y
        local dst = math.sqrt(sprX*sprX + sprY*sprY)
        local eyeX = math.cos(angle)
        local eyeY = math.sin(angle)
        local objAngle =  math.atan2(sprY, sprX)- math.atan2(eyeY, eyeX)

        if objAngle < -math.pi then
            objAngle = objAngle + 2* math.pi
        end

        if objAngle > math.pi then
            objAngle = objAngle - 2* math.pi
        end

        toSpr.x, toSpr.y = sprX, sprY
        eyeDir.x, eyeDir.y = eyeX, eyeY
        local visible = (toSpr * eyeDir) >= 0.5 

        if visible then
            local texture = spr.texture
            local perpDistance = dst * math.cos( objAngle )
            local fullHeight = raycast.width / perpDistance

            local objHeight =  (math.min(1,texture:getHeight()/32)* raycast.width) / perpDistance
            
            local floor = (raycast.height/2) + (fullHeight*0.5) + (headOffset/perpDistance) 
            local ceilling = floor - objHeight
            local aspectRatio = texture:getHeight() / texture:getWidth()
            local objWidth = objHeight / aspectRatio
            local objMiddle = ((0.5 * (objAngle/(fov/2)))+0.5) * raycast.width
            local startY = ceilling
            local startX = math.floor(objMiddle - (objWidth/2))

            spriteShader:send("depth", perpDistance)
            love.graphics.draw(texture,startX, startY, 0, objWidth / texture:getWidth(), objHeight/ texture:getHeight())
            
        end
    end
    raycast.stats.spritesRenderTime = love.timer.getTime() - start
end

raycast.rayCastDDA = rayCastDDA
raycast.renderScene = function(camera, map, sprites)
    -- clear all raycast specific buffers, but not the draw buffer as it doesn't belong to us
    love.graphics.setCanvas(raycast.justDepthBuffer)
    love.graphics.clear()
    love.graphics.reset()

    renderCeillingAndFloor(camera, map)
    renderWalls(camera, map)
    renderSprites(camera, sprites)
    local stats = raycast.stats
    raycast.stats.renderTime = stats.ceillingRenderTime + stats.floorRenderTime + stats.wallsRenderTime + stats.spritesRenderTime
end

return raycast