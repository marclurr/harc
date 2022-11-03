require("funcs")
local Camera = require("camera")
local vector = require("lib.hump.vector")
local raycast = require("raycast")
local Map = require("map")
local Slab = require("Slab")

local resolutions = {}
local resolutionNames = {}
table.insert(resolutions, {w=320, h=200})
table.insert(resolutions, {w=640, h=400})
table.insert(resolutions, {w=1280, h=800})
table.insert(resolutions, {w=1920, h=1200})
table.insert(resolutions, {w=3840, h=2400})

for i=1,#resolutions do
    local r= resolutions[i]
    local key = r.w .. "x" ..  r.h
    r.name = key
    resolutionNames[key]=i
end

love.graphics.setDefaultFilter("nearest", "nearest")
local width, height 
local drawCanvas 




-- "assets"
local zombie = love.graphics.newImage("assets/textures/zombie.png")
local map = require("testmap")

local mouseSensitivity = 1.

local model = {
    drawResolution = "320x200",
    drawDepth = 50,
    shadeDepth = 45,
    preview = {
        camera = Camera(1.04,1.5,1.5),
        angle = 0,
        x = 0,
        y = 0,
        clicked = false
    }
}

function configureEngine()
    local r = resolutions[resolutionNames[model.drawResolution]]
    width = r.w
    height = r.h
    if drawCanvas then drawCanvas:release() end
    drawCanvas = love.graphics.newCanvas(width, height)
    drawCanvas:setFilter("nearest", "nearest")
    print(model.shadeDepth)
    raycast.init(width, height, model.drawDepth, model.shadeDepth, drawCanvas)
end


local state


local PreviewState = {name="Preview"}
local UiState = {name = "Configure"}
function PreviewState:update(dt)
    -- rotation
    love.mouse.setRelativeMode(true)
    local dx, dy = Slab.GetMouseDelta()
    local angle = model.preview.camera.angle
    model.preview.camera.angle = angle + (dx * 0.001 * mouseSensitivity)
    

    -- movement
    local speed = 5
    local moving = false
    local playerDir = vector(math.cos(angle), math.sin(angle))
    local position = model.preview.camera.position
    if Slab.IsKeyDown("w") then
        position = position + playerDir * speed * dt
    elseif Slab.IsKeyDown("s") then
        position = position - playerDir * speed * dt
    end

    local strafeDir = vector(math.sin(angle), -math.cos(angle))
    if Slab.IsKeyDown("a") then
        position = position + strafeDir * speed * dt
    elseif Slab.IsKeyDown("d") then
        position = position - strafeDir * speed * dt
    end

    model.preview.camera:setPosition(position)
  
end

function PreviewState:keypressed(key)
    if key == "tab" then
        love.mouse.setRelativeMode(false)
        state = UiState
    end
end

function UiState:keypressed(key)
    if key == "tab" then
       
        state = PreviewState
    end
end

state = PreviewState

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
        texture = zombie
    })
end


function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    else
        if state.keypressed then
            state:keypressed(key)
        end
    end
end


function love.load()
    -- local r = resolutions[model.drawResolution]
    configureEngine()

    Slab.Initialize()
    Slab.SetVerbose(true)
    Slab.DisableDocks({"Left", "Right", "Bottom"})
end

function love.update(dt)
    Slab.Update(dt)

    local newResolution = model.drawResolution
    local newDrawDepth = model.drawDepth 
    local newShadeDepth = model.shadeDepth

	Slab.BeginWindow('RenderSettingsWindow', {NoSavedSettings=true,Title="Render Settings", AutoSizeWindow=true, ShowMinimize=false})
    Slab.BeginLayout("DebugLayout", {Columns=2})
    
    Slab.SetLayoutColumn(1)
    Slab.Text("Canvas Resolution")
    Slab.SetLayoutColumn(2)
    if Slab.BeginComboBox("ResolutionComboBox", {Selected = model.drawResolution}) then
        for i, v in ipairs(resolutions) do
            if Slab.TextSelectable(v.name) then
                newResolution = v.name
            end
        end
        
        Slab.EndComboBox()
    end 
    


    Slab.SetLayoutColumn(1)
    Slab.Text("Draw Depth")
    Slab.SetLayoutColumn(2)
    if Slab.InputNumberDrag("DrawDepth", model.drawDepth, 6, 100, 1) then
        newDrawDepth = Slab.GetInputNumber()
    end

    Slab.SetLayoutColumn(1)
    Slab.Text("Shade Depth")
    Slab.SetLayoutColumn(2)
    if Slab.InputNumberDrag("ShadeDepth", model.shadeDepth, 6, 100, 1) then
        newShadeDepth = Slab.GetInputNumber()
    end


    Slab.EndLayout()
	Slab.EndWindow()

    if newResolution ~= model.drawResolution or newDrawDepth ~= model.drawDepth or newShadeDepth ~= model.shadeDepth then
        model.drawResolution = newResolution
        model.drawDepth = newDrawDepth
        model.shadeDepth = newShadeDepth
        
        configureEngine()
    end
  
    model.preview.clicked = true
    model.preview.x, model.preview.y = 0, 0
    model.preview.w, model.preview.h = width, height

    if state.update then
        state:update(dt)
    end
end

function love.draw()
    local start = love.timer.getTime()

    love.graphics.setCanvas(drawCanvas)
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)

    raycast.renderScene(model.preview.camera, map, sprs)


    local totalTime = (love.timer.getTime() - start) 
    local dc = love.graphics.getStats().drawcalls
    love.graphics.reset()
    love.graphics.draw(drawCanvas,0,0,0,love.graphics.getWidth()/width,love.graphics.getHeight()/height)

    

    -- draw debug text
    
    debugPrint(string.format("%s Mode: Press tab to switch modes.", state.name), 5, 5, {1,0,0,1})
    local y = 5+18
    for k,v in pairs(raycast.stats) do
        if k:sub(-#"Time") == "Time" then
            v = v * 1000
        end
        local str = string.format("%s=%.4f",k,v)
        debugPrint(str, 5, y)
        y = y + 18
    end
    debugPrint(string.format("frameTime=%.2fms, drawCalls=%d, theoreticalRenderFPS=%d, resolution=%s",totalTime* 1000, dc, 1/totalTime, model.drawResolution), 5, y)

    
    
    
    Slab.Draw()

end

function debugPrint(str, x, y, clr)
    local fnt = love.graphics.getFont()
    local w,h = fnt:getWidth(str), fnt:getHeight(str)
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill", x-2, y-2, w+4, h+4)
    if not clr then
        love.graphics.setColor(1,1,1,1)
    else 
        love.graphics.setColor(clr)
    end

    love.graphics.print(str, x, y)
    
end

print(tostring(love.filesystem.getSource():sub(-#".love") == ".love"))