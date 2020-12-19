local Player = require 'player'
local Spell = require 'spell'

function love.load()
	font = love.graphics.newFont('assets/Lora-Regular.ttf', 24)
	header = love.graphics.newFont('assets/Lora-Regular.ttf', 48)
	love.graphics.setFont(header)
	player = Player(50, 50, 135, 18)
	table.insert(player.hand, Spell(
		{'l', 'R', 'w', 'L', 'w'},
		function(S, args) print('FRL', args.l, args.w) end
	))
end

function drawSpell(S, x, y, size, pad)
	if S then
		local r = size/2
		love.graphics.setColor(0.8, 0.7, 0.3)
		love.graphics.circle('fill', x+r, y+r, r)
		love.graphics.setColor(0.2, 0.2, 0.2)
		S:draw(x+r, y+r, math.sqrt(2)*r - 2*pad)
	end
end

function love.draw()
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0.5, 1, 0.9)
	love.graphics.printf('Squishy Fish and the Magic Doubloons', 10, 10, w - 20, 'center')
	player:draw()

	love.graphics.setLineWidth(3)
	for i,spell in ipairs(player.hand) do
		drawSpell(spell, 10 + (i-1)*55, 10, 50, 3)
	end
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
