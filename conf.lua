
function love.conf(t)
    t.window.title = "Raycast Shooter"
    t.window.width =  1280
    t.window.height = 800
    t.window.vsync = 0
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    
    t.console = false
    t.modules.physics = false
end