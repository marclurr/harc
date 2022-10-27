local floorShader = love.graphics.newShader("floor.glsl")
local ceillingShader = love.graphics.newShader("ceilling.glsl")

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
-- local width, height= love.graphics.getWidth(), love.graphics.getHeight()
local width, height= 320,200

local drawCanvas = love.graphics.newCanvas(width, height)
local depthBuffer = love.graphics.newCanvas(width, height, { type = "2d", format = "depth16", readable = true })

debugTexture = love.graphics.newArrayImage({"assets/textures/debug.png", "assets/textures/danger-wall.png"})


require("funcs")
Object = require("lib.classic")
vector = require("lib.hump.vector")
local raycast = require("raycast")
local maxDepth = 16
local shadeDepth = 12
raycast.init(width, height, maxDepth, shadeDepth)

local position = vector(1.5, 1.5)
local headOffset = 0
local angle = math.pi/4
local tilt = 0
local fov = 1.04

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

function love.update(dt)
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
    -- floorShader:send("cameraOffset", headOffset)
    -- floorShader:send("cameraTilt", tilt)
   
    love.graphics.rectangle("fill",0,top,width,h)
end

function love.draw()
    

    --position, headOffset, angle, tilt, fov, map
    love.graphics.setCanvas({drawCanvas, depthstencil = depthBuffer})
    
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)
    local start = love.timer.getTime()

    love.graphics.setDepthMode("always", false)
    drawTexturedPlane(ceillingShader, 0, height/2)
    drawTexturedPlane(floorShader, height/2, height/2)
    local floorCeillingT = love.timer.getTime() - start

    love.graphics.setDepthMode("always", true)
    local totalChecks, raycastTime, renderTime = raycast.renderWalls(position, headOffset, angle, tilt, fov, map)

    local totalTime = (love.timer.getTime() - start) 
    local dc = love.graphics.getStats().drawcalls
    love.graphics.reset()
    
    love.graphics.draw(drawCanvas,0,0,0,4,4)
    love.graphics.draw(depthBuffer,0,height-height*0.25,0,0.25,0.25)
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(string.format("totalChecks=%d, rayCastTime=%0.fus, renderTime=%0.fus",totalChecks, raycastTime, renderTime), 5, 5)
    love.graphics.print(string.format("frameTime=%0.f, floorCeilingRenderTime=%d, drawCalls=%d",totalTime* 1000000, floorCeillingT*1000000, dc), 5, 25)
    love.graphics.setColor(1,1,1,1)
end