local Actor = require 'actor'
local Effects = require 'effects'

local min, max = math.min, math.max
local floor = math.floor
local cos, sin = math.cos, math.sin
local TURN = 2*math.pi

function Bolt(Spell, args)
		local x, y = unpack(args.origin)
		local w = max(20, min(5 + args.w/3, 60))
		local speed = max(200, min(100+3*args.l, 800))
		local bolt = Actor(x, y, speed/5, w, I[Spell.imgName or 'energyPink'])
		bolt.damage = floor(0.5 + (w - 20)/10)
		bolt.bullet = true
		bolt.dir = 1 + (1 + args.dir) % 4
		local th = TURN * (bolt.dir-1)/4
		bolt.vx, bolt.vy = speed*cos(th), speed*sin(th)
		bolt.lifetime = 7.5  -- seconds
		bolt.owner = args.owner
		bolt.hit = Spell.hit or Effects.hurt
		bolt.hitScale = 0.8
		addTo(bolt, bolt.owner.group)
end

return Bolt
