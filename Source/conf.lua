function love.conf(t)
	t.title = "Tiny Armada"
	t.author = "Almost"
	t.screen.width = 800
	t.screen.height = 600
	t.modules.joystick = false
	t.modules.physics = false
	t.modules.audio = false
	t.modules.sound = false
	t.console = false           -- Attach a console (boolean, Windows only)
    t.vsync = true
end