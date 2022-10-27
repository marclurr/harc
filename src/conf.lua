require("const")

function love.conf(t)
    t.window.title = "Raycast Shooter"
    t.window.width = DARW_WIDTH
    t.window.height = DRAW_HEIGHT
    t.window.vsync = 1
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    
    t.console = false
    t.modules.physics = false
end