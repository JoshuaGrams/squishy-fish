local Object = require 'base-class'

local Trail = Object:extend()

function Trail.set(self, image, decay, color)
	self.image = image
	local w, h = image:getDimensions()
	local d = math.min(w, h)/3
	self.d2 = d*d
	self.j = 2
	self.ox, self.oy = w/2, h/2
	self.decay = decay
	self.color = color or {1,1,1}
	self.particles = {}
	self.t = 0
end

function Trail.clear(self)
	self.particles = {}
end

function Trail.add(self, x, y)
	self.t = 0
	x = x + self.j * (2*math.random() - 1)
	y = y + self.j * (2*math.random() - 1)
	self.x, self.y = x, y
	table.insert(self.particles, { t = self.decay, x = x, y = y })
end

local function distance2(ax, ay, bx, by)
	local dx, dy = ax - bx, ay - by
	return dx*dx + dy*dy
end

function Trail.update(self, dt, x, y)
	self.t = self.t + dt
	local P, d = self.particles, 0
	for i=1,#P do
		local p = P[i]
		p.t = p.t - dt
		if p.t <= 0 then d = d + 1 else P[i-d] = P[i] end
		if i > #P-d then P[i] = nil end
	end
	if x and y then
		local far = distance2(x, y, self.x or x, self.y or y) > self.d2
		local bored = false -- self.t >= self.decay/6
		if far or bored then self:add(x, y) end
		if not self.x then self.x, self.y = x, y end
	end
end

function Trail.draw(self, dt)
	local R, G, B = unpack(self.color)
	for _,p in ipairs(self.particles) do
		local A = p.t / self.decay
		love.graphics.setColor(R, G, B, A)
		love.graphics.draw(self.image, p.x, p.y,  0,  1,1,  self.ox, self.oy)
	end
end

return Trail
