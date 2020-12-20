local Player = require 'player'
local Spell = require 'spell'

function love.load()
	font = love.graphics.newFont('assets/Lora-Regular.ttf', 24)
	header = love.graphics.newFont('assets/Lora-Regular.ttf', 48)
	love.graphics.setFont(header)

	shell = love.graphics.newImage('assets/shell.png')
	coral = love.graphics.newImage('assets/coral.png')

	local w, h = love.graphics.getDimensions()
	player = Player(w/2, h/2, 135, 18)
	table.insert(player.hand, Spell(
		{'l', 'R', 'w', 'L', 'w'},
		function(S, args) print('FRL', args.l, args.w) end
	))

	cx, cy = w/2, h/2

	bgx, bgy = math.random(), math.random()
	bgsz = math.random()
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

function drawScenery(x0, y0, x1, y1)
	local size = 600
	love.graphics.setColor(1, 1, 1, 0.5)
	for x=math.floor(x0/size)-2,math.ceil(x1/size)+2 do
		for y=math.floor(y0/size)-2, math.ceil(y1/size)+2 do
			local n = love.math.noise(bgx + x*bgsz, bgy + y*bgsz)
			local a = math.floor(10*n)
			local b, c = math.floor(100*n%10), math.floor(1000*n%10)
			local d = 10000*n%10
			if a <= 6 then
				local img = a<3 and shell or coral
				love.graphics.draw(img, (x + b/20)*size, (y + c/20)*size,  0,  0.2+d/15)
			end
		end
	end
end

function love.draw()
	local w, h = love.graphics.getDimensions()
	love.graphics.translate(w/2, h/2)
	love.graphics.translate(-cx, -cy)

	drawScenery(cx - w/2, cy - h/2, cx + w/2, cy + h/2)

	love.graphics.setColor(0.5, 1, 0.9)
	love.graphics.printf('Squishy Fish and the Magic Doubloons', 10, 10, w - 20, 'center')
	player:draw()

	love.graphics.origin()

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

	-- Scroll the screen.
	local px, py = player:center()
	local dx, dy = px - cx, py - cy
	if dx*dx + dy*dy > 1 then
		local cf, ct = 0.95, 0.9  -- Converge to 95% in 0.9 seconds.
		local k = 1 - (1 - cf)^(dt/ct)
		dx, dy = k*dx, k*dy
	end
	cx, cy = cx + dx, cy + dy

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
