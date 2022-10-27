local floorShader = love.graphics.newShader("floor.glsl")
local ceillingShader = love.graphics.newShader("ceilling.glsl")
local spriteShader = love.graphics.newShader("sprite.glsl")

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

love.graphics.setDefaultFilter("nearest", "nearest")
local width, height= love.graphics.getWidth(), love.graphics.getHeight()
-- local width, height= 320,180

local drawCanvas = love.graphics.newCanvas(width, height)
local depthBuffer = love.graphics.newCanvas(width, height)
local sprDepthBuffer = love.graphics.newCanvas(width, height, {type = "2d", format = "depth16", readable = true})

debugTexture = love.graphics.newArrayImage({"assets/textures/debug.png", "assets/textures/danger-wall.png", "assets/textures/clurr-lo.png"})
zombie = love.graphics.newImage("assets/textures/zombie.png")

require("funcs")
Object = require("lib.classic")
vector = require("lib.hump.vector")
local raycast = require("raycast")
local maxDepth = 25
local shadeDepth = 12
raycast.init(width, height, maxDepth, shadeDepth)

local position = vector(1.5, 1.5)
local headOffset = 0
local angle = math.pi/4
local tilt = 0
local fov = 1.04

sprs = {}

for i=1,200 do
    table.insert(sprs, {
        position= vector(math.random(1,14) +0.5, math.random(1,14)+0.5)
    })
end



love.mouse.setRelativeMode(true)
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

local mouseSensitivity = 1.
function love.mousemoved(x,y,dx,dy,istouch)
    angle = angle + (dx * 0.001 * mouseSensitivity)
    -- tilt = math.max(-height, math.min(height, tilt - dy * 1.5  ))
end

t = 0

function love.update(dt)
    t = t + dt 
    headOffset = math.sin(t*12) * 16
    local speed = 5
    local moving = false
    local playerDir = vector(math.cos(angle), math.sin(angle))
    if love.keyboard.isDown("w") then
        position = position + playerDir * speed * dt
        moving = true
    elseif love.keyboard.isDown("s") then
        position = position - playerDir * speed * dt
        moving = true
    end

    local strafeDir = vector(math.sin(angle), -math.cos(angle))
    if love.keyboard.isDown("a") then
        position = position + strafeDir * speed * dt
        moving = true
    elseif love.keyboard.isDown("d") then
        position = position - strafeDir * speed * dt
        moving = true
    end

end

function drawTexturedPlane(shader, top, h)
    love.graphics.setShader(shader)
    shader:send("width", width)
    shader:send("height", height/2)
    shader:send("position", {position.x, position.y})
    shader:send("textures", debugTexture)
    shader:send("fov", fov)
    shader:send("angle", angle)
    shader:send("cameraOffset", headOffset)
    -- floorShader:send("cameraTilt", tilt)
   
    love.graphics.rectangle("fill",0,top,width,h)
end

function love.draw()
    local start = love.timer.getTime()
    -- clear all the buffers
    love.graphics.setCanvas({drawCanvas, depthBuffer, depthstencil=sprDepthBuffer})
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)

    
    -- draw floor and ceilling
    love.graphics.setCanvas(drawCanvas)
    drawTexturedPlane(ceillingShader, 0, height/2)
    drawTexturedPlane(floorShader, height/2, height/2)
    local floorCeillingT = love.timer.getTime() - start

    -- draw walls
    love.graphics.setCanvas(drawCanvas, depthBuffer)
    local totalChecks, raycastTime, renderTime = raycast.renderWalls(position, headOffset, angle, tilt, fov, map)

    -- draw sprites

    local sprStart = love.timer.getTime()
    love.graphics.setCanvas({drawCanvas, depthstencil = sprDepthBuffer})
    love.graphics.setDepthMode("lequal", true)

    love.graphics.setShader(spriteShader)
    spriteShader:send("depthBuffer", depthBuffer)
    spriteShader:send("maxDepth", maxDepth)
    spriteShader:send("shadeDepth", shadeDepth)

    for i=1,#sprs do
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

        local visible = (vector(sprX, sprY):normalized() * vector(eyeX, eyeY) ) >= 0.5

        if visible then
            local texture = zombie
            local perpDistance = dst * math.cos( objAngle )
            local fullHeight = height / perpDistance

            local objHeight =  (math.min(1,texture:getHeight()/32)* height) / perpDistance
            
            local floor = (height/2) + (fullHeight*0.5) + (headOffset/perpDistance)  + tilt
            local ceilling = floor - objHeight
            local aspectRatio = texture:getHeight() / texture:getWidth()
            local objWidth = objHeight / aspectRatio
            local objMiddle = ((0.5 * (objAngle/(fov/2)))+0.5) * width
            local startY = ceilling
            local startX = math.floor(objMiddle - (objWidth/2))

            spriteShader:send("depth", perpDistance)
            love.graphics.draw(texture,startX, startY, 0, objWidth / texture:getWidth(), objHeight/ texture:getHeight())
            
        end
    end
    local sprT = love.timer.getTime() - sprStart
    love.graphics.setColor(1,1,1,1)



    local totalTime = (love.timer.getTime() - start) 
    local dc = love.graphics.getStats().drawcalls
    love.graphics.reset()
    
    love.graphics.draw(drawCanvas,0,0,0,math.floor(love.graphics.getWidth()/width),math.floor(love.graphics.getHeight()/height))
    -- love.graphics.draw(depthBuffer,0,love.graphics.getHeight()-height,0)
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(string.format("totalChecks=%d, rayCastTime=%0.fus, renderTime=%0.fus",totalChecks, raycastTime, renderTime), 5, 5)
    love.graphics.print(string.format("frameTime=%0.f, floorCeilingRenderTime=%0.f, spriteRenderTime=%0.f drawCalls=%d",totalTime* 1000000, floorCeillingT*1000000,sprT*1000000, dc), 5, 25)
    love.graphics.setColor(1,1,1,1)
end