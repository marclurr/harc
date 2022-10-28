
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
local width, height= 320,200 --love.graphics.getWidth(), love.graphics.getHeight()
local drawCanvas = love.graphics.newCanvas(width, height)

debugTexture = love.graphics.newArrayImage({"assets/textures/debug.png", "assets/textures/danger-wall.png", "assets/textures/door.png"})
local zombie = love.graphics.newImage("assets/textures/zombie.png")

require("funcs")
local Camera = require("camera")
local vector = require("lib.hump.vector")
local raycast = require("raycast")


raycast.init(width, height, 25, 12, drawCanvas)

local camera = Camera(1.04)
local position = vector(1.5, 1.5)
local headOffset = 0
local angle = 0 -- math.pi/4

local tilt = 0
local fov = 1.04

sprs = {}

for i=1,15 do
    table.insert(sprs, {
        position= vector(math.random(1,14) +0.5, math.random(1,14)+0.5), 
        -- position= vector(4.5, 1.5), 
        texture = zombie
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
end

t = 0

function love.update(dt)
    t = t + dt 
    -- headOffset = math.sin(t*12) * 16
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

    camera:setPosition(position)
    camera.angle = angle
    camera.height = headOffset
end

function love.draw()
    local start = love.timer.getTime()

    love.graphics.setCanvas(drawCanvas)
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)

    raycast.renderScene(camera, map, sprs)


    local totalTime = (love.timer.getTime() - start) 
    local dc = love.graphics.getStats().drawcalls
    love.graphics.reset()
    
    love.graphics.draw(drawCanvas,0,0,0,math.floor(love.graphics.getWidth()/width),math.floor(love.graphics.getHeight()/height))
    love.graphics.draw(raycast.sprDepthBuffer, 0, raycast.height - raycast.height*0.25, 0, 0.25, 0.25)
    love.graphics.setColor(0,0,0,1)
    
    love.graphics.print(string.format("frameTime=%.2fms, drawCalls=%d",totalTime* 1000, dc), 5, 25)
    love.graphics.setColor(1,1,1,1)
end