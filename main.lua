local Bolt = require 'bolt'
local Effects = require 'effects'
local MiniMap = require 'minimap'
local Patroller = require 'patroller'
local Player = require 'player'
local Spell = require 'spell'

local TURN = 2*math.pi
local sqrt = math.sqrt
local min, max = math.min, math.max
local cos, sin = math.cos, math.sin

local function generateSeedFromClock()
	local seed = os.time() + math.floor(1000*os.clock())
	seed = seed * seed % 1000000
	seed = seed * seed % 1000000
	return seed
end

function addTo(actor, group)
	table.insert(group, actor)
	actor.group = group
end

function love.load()
	math.randomseed(generateSeedFromClock())

	font = love.graphics.newFont('assets/Lora-Regular.ttf', 24)
	header = love.graphics.newFont('assets/Lora-Regular.ttf', 48)
	love.graphics.setFont(header)
	title = true

	I = {
		halfHeart = love.graphics.newImage('assets/half-heart.png'),
		fullHeart = love.graphics.newImage('assets/full-heart.png'),
		shell = love.graphics.newImage('assets/shell.png'),
		coral = love.graphics.newImage('assets/coral.png'),
		energyPink = love.graphics.newImage('assets/energy-pink.png'),
		energyGreen = love.graphics.newImage('assets/energy-green.png'),
		greenBall = love.graphics.newImage('assets/green-ball.png'),
		patroller = love.graphics.newImage('assets/patroller.png'),
		mine = love.graphics.newImage('assets/mine.png')
	}

	w, h = love.graphics.getDimensions()
	cx, cy, vScale = w/2, h/2, 0.65
	vw, vh = w/vScale, h/vScale

	player = Player(w/2, h/2, 135, 18)
	spells = {
		bolt = Spell({'l', 'R','w'}, Bolt),
		reverseBolt = Spell({'l', 'L','w'}, Bolt, {reverse = true}),
		push = Spell({'l', 'R','w', 'B','l'}, Bolt, {hit = Effects.push}),
		pull = Spell({'l', 'L','w', 'B','l'}, Bolt, {hit = Effects.push, invert = true}),
		swap = Spell({'l', 'R','w', 'F','l'}, Bolt, {hit = Effects.swap}),
		convert = Spell({'l', 'B','l'}, Bolt, {hit = Effects.convert}),
	}
	table.insert(player.deck, spells.bolt)
	table.insert(player.deck, spells.bolt)
	table.insert(player.deck, spells.reverseBolt)
	table.insert(player.deck, spells.swap)
	player:fillHand()

	bgx, bgy = math.random(), math.random()
	bgsz = math.random()

	group = {
		friends = {},
		enemies = {},
		curmudgeons = {}
	}
	addTo(player, group.friends)
	addTo(Patroller(900, 900), group.enemies)
end

function nearest(a, friend)
	local nearest, bestDist2, bdx, bdy
	for _,g in pairs(group) do
		if friend == nil or (g == a.group) == not not friend then
			for _,b in ipairs(g) do
				if not b.bullet and a ~= b then
					local ax, ay = a:center()
					local bx, by = b:center()
					local dx, dy = bx - ax, by - ay
					local d2 = dx*dx + dy*dy
					if not bestDist2 or d2 < bestDist2 then
						nearest, bestDist2, bdx, bdy = b, d2, dx, dy
					end
				end
			end
		end
	end
	return nearest, bdx, bdy
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
				local img = a<3 and I.shell or I.coral
				love.graphics.draw(img, (x + b/20)*size, (y + c/20)*size,  0,  0.2+d/15)
			end
		end
	end
end

function love.draw()
	w, h = love.graphics.getDimensions()
	vw, vh = w / vScale, h / vScale
	love.graphics.translate(w/2, h/2)
	love.graphics.scale(vScale)
	love.graphics.translate(-cx, -cy)

	drawScenery(cx - w/2, cy - h/2, cx + w/2, cy + h/2)

	if title then
		love.graphics.setColor(0.5, 1, 0.9)
		love.graphics.printf('Squishy Fish and the Magic Doubloons', 10, 10, vw - 20, 'center')
	end

	for _,a in ipairs(group.friends) do a:draw() end
	for _,a in ipairs(group.enemies) do a:draw() end
	for _,a in ipairs(group.curmudgeons) do a:draw() end

	love.graphics.origin()

	love.graphics.setLineWidth(3)
	for i,spell in ipairs(player.hand) do
		drawSpell(spell, 10, 10 + (i-1)*55, 50, 3)
	end

	love.graphics.setColor(1,1,1)
	local health = 0
	while health < player.health do
		local img = player.health - health < 1 and I.halfHeart or I.fullHeart
		local iw, ih = img:getDimensions()
		love.graphics.draw(img, w-10, 10 + health*55,  0,  50/iw, 50/ih,  iw, 0)
		health = health + 1
	end

	local mR = 0.5*math.max(vw, vh) * 4
	local mr = math.min(w, h) / 6
	local mx, my = w - 1.1*mr, h - 1.1*mr
	MiniMap(mx, my, mr, mR)
end

local function removeDead(lst)
	local i, N = 1, #lst
	local d = 0
	for i=1,N do
		local g = lst[i].group
		if g ~= lst then
			if g then addTo(lst[i], g) end
			d, lst[i] = d+1, nil
		elseif d > 0 then
			lst[i-d], lst[i] = lst[i], nil
		end
	end
end

local function collide(K, L)
	for _,k in ipairs(K) do
		if k.group then for _,l in ipairs(L) do
			if l.group and k:overlaps(l) then
				if k.hit then k:hit(l) end
				if l.hit then l:hit(k) end
			end
		end end
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

	for _,g in pairs(group) do
		for _,a in ipairs(g) do
			if a == player then
				a:update(dt, d)
			else
				a:update(dt)
			end
		end
	end
	for _,f in pairs(group) do
		for _,g in pairs(group) do
			if f ~= g then collide(f, g) end
		end
	end
	for _,g in pairs(group) do removeDead(g) end

	-- Scroll the screen.
	local px, py = player:center()
	local dx, dy = px - cx, py - cy
	if dx*dx + dy*dy > 1 then
		local cf, ct = 0.95, 0.9  -- Converge to 95% in 0.9 seconds.
		local k = 1 - (1 - cf)^(dt/ct)
		dx, dy = k*dx, k*dy
	end
	cx, cy = cx + dx, cy + dy

	if title and (cx - vw/2 > vw-10 or cx + vw/2 < 10 or cy - vh/2 > 10 + 48 or cy + vh/2 < 10) then
		title = nil
	end
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
