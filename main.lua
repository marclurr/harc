local walls = {}
local floors = {}
local ceillings = {}
local mapData = {}
mapsize=16
for i=1,mapsize*mapsize do
    local x = (i-1)% mapsize
    local y = math.floor((i-1)/mapsize)

    local wall = {type=-1}
    local floor = {tileId=-1}
    local ceilling = {tileId=-1}
    
    if y == 0 or y == mapsize-1 then 
        wall = {type=1, tileId=1}
    else
        if x == 0 or x == mapsize-1 then
            wall = {type=1, tileId=1}
        else
            floor = {tileId=0}
            ceilling = {tileId=0}  
        end
    end

    mapData[i]=wall
    mapData[i+(mapsize*mapsize)]=floor
    mapData[i+(mapsize*mapsize*2)]=ceilling
end


love.graphics.setDefaultFilter("nearest", "nearest")
local width, height= 320,200 --love.graphics.getWidth(), love.graphics.getHeight()
local width, height= love.graphics.getWidth(), love.graphics.getHeight()
local drawCanvas = love.graphics.newCanvas(width, height)

local debugTexture = love.graphics.newArrayImage({"assets/textures/debug.png", "assets/textures/danger-wall.png", "assets/textures/door.png"})
local zombie = love.graphics.newImage("assets/textures/zombie.png")

require("funcs")
local Camera = require("camera")
local vector = require("lib.hump.vector")
local raycast = require("raycast")
local Map = require("map")


local map = Map(16, 16, debugTexture, mapData)
raycast.init(width, height, 50, 45, drawCanvas)

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
    love.graphics.setColor(0,0,0,1)
    local y = 5
    for k,v in pairs(raycast.timings) do
        if k:sub(-#"Time") == "Time" then
            v = v * 1000
        end
        local str = string.format("%s=%.4f",k,v)
        debugPrint(str, 5, y)
        -- love.graphics.setColor(0,0,0,1)
        -- love.graphics.print(str, 5-1, y)
        -- love.graphics.print(str, 5+1, y)
        -- love.graphics.print(str, 5, y+1)
        -- love.graphics.print(str, 5, y-1)
        -- love.graphics.print(str, 5, y)
        -- love.graphics.setColor(1,1,1,1)

        -- love.graphics.print(str, 5, y)
        y = y + 18
    end
    
    debugPrint(string.format("frameTime=%.2fms, drawCalls=%d",totalTime* 1000, dc), 5, y)
    love.graphics.setColor(1,1,1,1)
end

function debugPrint(str, x, y)
    local fnt = love.graphics.getFont()
    local w,h = fnt:getWidth(str), fnt:getHeight(str)
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill", x-2, y-2, w+4, h+4)
    -- love.graphics.print(str, x-1, y)
    -- love.graphics.print(str, x+1, y)
    -- love.graphics.print(str, x, y+1)
    -- love.graphics.print(str, x, y-1)
    -- love.graphics.print(str, x, y)
    love.graphics.setColor(1,1,1,1)

    love.graphics.print(str, x, y)
    
end