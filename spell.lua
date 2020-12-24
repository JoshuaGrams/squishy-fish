local Object = require 'base-class'

local ceil = math.ceil
local min, max = math.min, math.max
local function clamp(x, lo, hi) return max(lo, min(x, hi)) end


local Spell = Object:extend()

function Spell.set(S, shape, fn, options)
	S.shape = {unpack(shape)}
	S.shape.origin = shape.origin or ceil(#shape/2)
	S.fn = fn
	for k,v in pairs(options or {}) do S[k] = v end
end

local turns = { F = 0, R = 1, B = 2, L = 3 }
local dirs = { F = {1,0}, R = {0,1}, B = {-1,0}, L = {0,-1} }
Spell.turns = turns

-- path is { finish={x,y}, {turn=<int 0..3>,length=<float>,p={x,y}}, ... }
-- First turn is casting direction, rest are relative to that.
-- Returns table with dir, origin, and any keys the spell specifies.
function Spell.match(S, path, maxEdgeLength)
	local len = ceil(#S.shape/2)
	if #path ~= len then return false end
	local expected, args = S.shape, {}
	for i,edge in ipairs(path) do
		local turn, key = turns[expected[2*i-2]], expected[2*i-1]
		if not turn then
			-- First edge sets the casting direction
			args.dir = edge.turn
		elseif edge.turn ~= turn then
			-- Turns must match the spell
			return false
		end
		if i == S.shape.origin+1 then args.origin = {unpack(edge.p)} end
		args[key] = clamp(edge.length/maxEdgeLength, args[key] or 0, 1)
	end
	if S.shape.origin == #path then args.origin = {unpack(path.finish)} end
	return args
end

function Spell.cast(S, args) S.fn(S, args) end

function Spell.path(S)
	local r = 6
	local dir, len = 'F', 1
	local p = { 0,0,  2,0 }
	for i=2,#S.shape,2 do
		local d = S.shape[i]
		local x, y = unpack(p, #p-1)
		local dx, dy = unpack(dirs[d])
		if d ~= dir and (turns[d] - turns[dir]) % 2 == 0 then
			-- Doubling back: offset it a little.
			x, y = x + dy/r, y - dx/r
			table.insert(p, x)
			table.insert(p, y)
		end
		x, y = x + dx*len, y + dy*len
		table.insert(p, x)
		table.insert(p, y)
		len = len + 4/r
		dir = d
	end
	return p
end

function bounds(p)
	local xMin, yMin, xMax, yMax
	for i=1,#p,2 do
		local x, y = p[i], p[i+1]
		xMin, xMax = min(x, xMin or x), max(x, xMax or x)
		yMin, yMax = min(y, yMin or y), max(y, yMax or y)
	end
	return xMin, yMin, xMax, yMax
end

function scale(p, s)
	local q = {}
	for _,c in ipairs(p) do
		table.insert(q, c*s)
	end
	return q
end

function Spell.draw(S, x, y, size)
	local p = S:path()
	local x0,y0, x1,y1 = bounds(p)
	local w, h = x1-x0, y1-y0
	local sc
	if w == 0 then sc = size/h
	elseif h == 0 then sc = size/w
	else sc = min(size/w, size/h) end
	local coords = scale(p, sc)
	love.graphics.push()
	love.graphics.translate(x - sc*(x0 + w/2), y - sc*(y0 + h/2))
	love.graphics.polygon('fill', coords[1], coords[2]-4, coords[1]+7, coords[2], coords[1], coords[2]+4)
	love.graphics.line(coords)
	love.graphics.pop()
end

return Spell
