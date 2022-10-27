require("const")
require("types")
require("funcs")

local raycast = require("raycast")
textureClurr = Texture("assets/textures/zombie.png")
textureDebug = Texture("assets/textures/debug.png")
textureThing = Texture("assets/textures/thing.png")

texturesCpu = {
    [WallSide.North] =  Texture("assets/textures/danger-wall.png"),
    [WallSide.East] =  Texture("assets/textures/danger-wall.png"),
    [WallSide.South] =  Texture("assets/textures/danger-wall.png"),
    [WallSide.West] =  Texture("assets/textures/danger-wall.png"),
    clurr = Texture("assets/textures/door.png")
}


viewportScaling = 0
viewportX = 0
viewportY = 0

local mode = true

ix = 0

local map = {
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,1,
    1,0,0,0,0,1,1,2,1,1,0,0,1,0,0,1,
    1,0,1,0,0,0,0,0,0,0,0,0,0,1,0,1,
    1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,1,1,0,0,0,0,0,1,1,1,0,0,0,1,
    1,0,0,1,1,1,1,0,1,1,1,0,0,0,0,1,
    1,0,0,0,0,0,0,0,3,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,1,1,1,0,0,0,0,1,
    1,0,0,0,1,1,1,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
}

-- map = {
--     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
--     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
-- }


local player = {
    position = vector(1.5, 1.5),
    angle = math.pi/4,
    tilt  = 0
}


local sprs = {}


offset = 0
local t= 0


function configureViewport()
    if viewportCanvas then
        viewportCanvas:release()
    end

    viewportCanvas = love.graphics.newCanvas(DARW_WIDTH, DRAW_HEIGHT)
    viewportScaling = math.floor(math.min(love.graphics.getWidth()/DARW_WIDTH, love.graphics.getHeight()/DRAW_HEIGHT))
    viewportX = (love.graphics.getWidth()-(DARW_WIDTH*viewportScaling))/2
    viewportY = (love.graphics.getHeight()-(DRAW_HEIGHT*viewportScaling))/2
end


function love.load()
    local w, h = love.window.getDesktopDimensions()
    local windowScale = math.floor(math.min(w/DARW_WIDTH, h/DRAW_HEIGHT))

    print(w .. ", "..h)
    love.window.setMode(DARW_WIDTH*windowScale, DRAW_HEIGHT*windowScale,{})
        

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")

    configureViewport()

    love.mouse.setRelativeMode(true)

    screenImageData = love.image.newImageData(DARW_WIDTH, DRAW_HEIGHT)
    screenImage = love.graphics.newImage(screenImageData)
    raycast.init(screenImageData)


    dbid = love.image.newImageData(DARW_WIDTH, DRAW_HEIGHT)
    dbi = love.graphics.newImage(dbid)

    for i=1,25 do
        table.insert(sprs, {
            -- position= vector(math.random(1,14) +math.random(), math.random(1,14)+math.random()),
            position= vector(math.random(1,14) +0.5, math.random(1,14)+0.5),
            getTexture = function()
                return textureClurr
            end
        })
    end
end



local i = 0
headOffset = 0
function love.update(dt)
    t = t + dt
    local js = love.joystick.getJoysticks()[1]
    local lx, ly, rx, ry = js:getAxes()

    local speed = 5
    
    local moving = false
    local playerDir = vector(math.cos(player.angle), math.sin(player.angle))
    if love.keyboard.isDown("w") then
        player.position = player.position + playerDir * speed * dt
        moving = true
    elseif love.keyboard.isDown("s") then
        player.position = player.position - playerDir * speed * dt
        moving = true
    end

    if ly ~= 0 then 
        player.position = player.position - playerDir * speed * dt * ly
        moving = true
    end

    local strafeDir = vector(math.sin(player.angle), -math.cos(player.angle))
    if love.keyboard.isDown("a") then
        player.position = player.position + strafeDir * speed * dt
        moving = true
    elseif love.keyboard.isDown("d") then
        player.position = player.position - strafeDir * speed * dt
        moving = true
    end

    if lx ~= 0 then 
        player.position = player.position - strafeDir * speed * dt * lx
        moving = true
    end

    -- headOffset = -16
    if not moving then
        headOffset = math.lerp(headOffset, 0,  20 * dt) 
        
    else
        headOffset =    (math.sin(t*12) * 10 )
    end
    offset =  math.min(0.95,(1+math.sin(t*2))/2)
      

    if love.keyboard.isDown("left") then
        player.angle = player.angle - math.pi * dt
    elseif love.keyboard.isDown("right") then
        player.angle = player.angle + math.pi * dt
    end



    player.angle = player.angle + math.pi * dt * rx * 1.5

 
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        mode = not mode
        if not mode then
            player.tilt = 0
        end
    end
end



local mouseSensitivity = 1.
function love.mousemoved(x,y,dx,dy,istouch)
    player.angle = player.angle + (dx * 0.001 * mouseSensitivity)
    if mode then
        player.tilt = math.max(-200, math.min(200, player.tilt - dy * 0.25  ))
    end
    
end

function clear(x,y)
    return 0.5,0.5,0.5,1
end

function love.draw()
    love.graphics.setCanvas(viewportCanvas)
    love.graphics.clear()

    screenImageData:mapPixel(clear)
    local fov = 1.04
    local totalChecks, raycastTime, renderTime = raycast.renderWalls(player.position, headOffset, player.angle, player.tilt, fov, map)

    local srs = love.timer.getTime()
    local renderedSprites = 0
    for i=1,#sprs do
        local spr = sprs[i]
        local vi = math.floor(spr.position.y) * 16 + math.floor(spr.position.x)
        if raycast.visibleTiles[vi+1] == true then
            renderedSprites = renderedSprites + 1
            local sprX = spr.position.x - player.position.x
            local sprY = spr.position.y - player.position.y
            local dst = math.sqrt(sprX*sprX + sprY*sprY)
            local eyeX = math.cos(player.angle)
            local eyeY = math.sin(player.angle)
            local objAngle =  math.atan2(sprY, sprX)- math.atan2(eyeY, eyeX)
            
            if objAngle < -math.pi then
                objAngle = objAngle + 2* math.pi
            end

            if objAngle > math.pi then
                objAngle = objAngle - 2* math.pi
            end

            -- is the object in front of the camera
            local visible = (vector(sprX, sprY):normalized() * vector(eyeX, eyeY) ) >= 0.5

            if visible then
                
                local texture = spr:getTexture()
                local perpDistance = dst * math.cos( objAngle )
                local fullHeight = DRAW_HEIGHT / perpDistance

                local objHeight = (math.min(1,texture.height/64)* DRAW_HEIGHT) / perpDistance

                local floor = (DRAW_HEIGHT/2) + (fullHeight*0.5) + (headOffset/perpDistance) + player.tilt
                local ceilling = floor - objHeight
                 
                local aspectRatio = texture:getHeight() / texture:getWidth()
                local objWidth = objHeight / aspectRatio
                local objMiddle = ((0.5 * (objAngle/(fov/2)))+0.5) * DARW_WIDTH
                local startY = ceilling
                local startX = math.floor(objMiddle - (objWidth/2))
                local s = 1 - (dst/12) 
                

                for x=math.max(0,startX),math.min(DARW_WIDTH-1,startX+objWidth) do
                    for y=math.max(0,startY),math.min(DRAW_HEIGHT-1,startY+objHeight) do
                        local i = (math.floor(y) * DARW_WIDTH) + x + 1
                        local depth = raycast.zBuffer[i]
                        if dst <  depth then
                            
                            local u,v = math.min(0.99,(x - startX)/objWidth), (y-startY)/objHeight
                            local px = texture:getPixel(math.floor(texture:getWidth()*u), math.floor(texture:getHeight()*v))
                            
                            if px and px.a > 0 then
                                raycast.zBuffer[i] = dst
                                
                                screenImageData:setPixel(x, y, px.r*s, px.g*s, px.b*s, px.a)
                            end
                        end
                    end
                end
            end
        end
    end

    sre = (love.timer.getTime() - srs)*1000
    screenImage:replacePixels(screenImageData)
    love.graphics.draw(screenImage,0,0)
    

    

    love.graphics.setColor(1,1,1,1)


    love.graphics.setCanvas()
    love.graphics.clear()
    love.graphics.draw(viewportCanvas, viewportX, viewportY, 0, viewportScaling, viewportScaling)

    -- love.graphics.setColor(0,0,0,1)
    -- for y= 0,15 do
    --     for x = 0,15 do
    --         local i = (y*16)+x
    --         local t = map[i+1]
        
    --         if t == 2 then
    --             local sx = x * 8
    --             local sy = y * 8 + 4
    --             love.graphics.line(sx+16, sy+16, sx+8+15, sy+16)
    --         elseif raycast.visibleTiles[i+1] == true then
    --             love.graphics.setColor(0,0.5,0,1)
    --             local sx = x * 8
    --             local sy = y * 8
    --             love.graphics.rectangle("fill", sx+16, sy+16, 8, 8)
    --             love.graphics.setColor(0,0,0,1)
    --         else 
    --             if t == 1 then
    --                 love.graphics.setColor(1, 0.5, 0.5, 1)
    --             else
    --                 love.graphics.setColor(0,0,0,1)
    --             end
    --             local sx = x * 8
    --             local sy = y * 8
    --             love.graphics.rectangle("line", sx+16, sy+16, 8, 8)
    --         end
    --     end
    -- end



    -- local px = (player.position.x * 8) + 16
    -- local py = (player.position.y * 8) + 16
    -- love.graphics.setColor(1,1,0,1)
    -- love.graphics.circle("fill", px, py, 2)

    -- local result = RayCastResult()
    -- local sa = player.angle - fov/2
    -- local ss = fov/DARW_WIDTH
    -- for i=0,DARW_WIDTH-1 do
    --     local a = sa + (ss * i)
    --     local rayDir = vector(math.cos(a), math.sin(a))
    --     local abc = raycast.rayCastDDA(player.position, rayDir, map, result)
    
    --     local ex = (result.collisionPoint.x * 8) + 16
    --     local ey = (result.collisionPoint.y * 8) + 16
    --     love.graphics.setColor(1,0,0,1)
    --     love.graphics.line(px, py, ex, ey)
    --     love.graphics.setColor(1,1,1,1)
    -- end

    -- for i=1,#sprs do
    --     local spr = sprs[i]
    --     local ii = math.floor(spr.position.y) * 16 + math.floor(spr.position.x) + 1
    --     if raycast.visibleTiles[ii] ==true then
    --         love.graphics.setColor(0,0,1,1)
    --     else
    --         love.graphics.setColor(1,1,1,1)
    --     end
    --     local sx = sprs[i].position.x * 8 + 16
    --     local sy = sprs[i].position.y * 8 + 16
        
    --     love.graphics.circle("fill", math.floor(sx), math.floor(sy), 1)
    -- end
   


    -- showDbi(1280-320,960-200)
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(string.format("raycastTime: %.2fms    spriteRenderTime: %.2fms    renderedSprites: %d/%d", raycastTime, sre, renderedSprites, #sprs), 5, 5)
    love.graphics.print(string.format("screenUpdateTime: %.2fms    totalREnderTime: %.2fms    theoreticalRenderFps: %d", renderTime,  renderTime+sre,1000.0 / (renderTime+sre) ), 5, 5+15)
    love.graphics.print("totalChecks: " .. totalChecks , 5, 5+15+15)
    love.graphics.print("playerPos: " .. player.position:__tostring() , 5, 5+15+15+15)
    love.graphics.print(string.format("windowResolution: %dx%d", love.graphics.getWidth(),  love.graphics.getHeight()),5,5+15+15+15+15)
    love.graphics.setColor(1,1,1,1)
    
end