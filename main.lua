local Player = require 'player'

function love.load()
	font = love.graphics.newFont('assets/Lora-Regular.ttf', 24)
	header = love.graphics.newFont('assets/Lora-Regular.ttf', 48)
	love.graphics.setFont(header)
	player = Player(50, 50, 135, 18)
	table.insert(player.hand, { 'l', 'R', 'w', 'L', 'w', fn = function(args)
		print('FRL', args.l, args.w)
	end})
end

function love.draw()
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0.5, 1, 0.9)
	love.graphics.printf('Squishy Fish and the Magic Doubloons', 10, 10, w - 20, 'center')
	player:draw()
end

function love.update(dt)
	local d
	if love.keyboard.isScancodeDown('space', 'lshift', 'rshift') then d = 0
	elseif love.keyboard.isScancodeDown('right', 'd') then d = 1
	elseif love.keyboard.isScancodeDown('down', 's') then d = 2
	elseif love.keyboard.isScancodeDown('left', 'a') then d = 3
	elseif love.keyboard.isScancodeDown('up', 'w') then d = 4
	end
	player:update(dt, d)
end

function toggleFullscreen()
	local wasFull = love.window.getFullscreen()
	love.window.setFullscreen(not wasFull, 'desktop')
end

function love.keypressed(k, s)
	local alt = love.keyboard.isDown('lalt', 'ralt')
	if k == 'f11' or (alt and k == 'return') then
		toggleFullscreen()
	elseif k == 'escape' then
		love.event.quit()
	end
end
