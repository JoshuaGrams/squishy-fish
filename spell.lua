local Object = require 'base-class'

local ceil = math.ceil
local max = math.max

local Spell = Object:extend()

function Spell.set(S, shape, fn)
	S.shape = {unpack(shape)}
	S.fn = fn
end

local turns = { F = 0, R = 1, B = 2, L = 3 }
Spell.turns = turns

function Spell.match(S, path)
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
		args[key] = max(args[key] or 0, edge.length)
	end
	return args
end

function Spell.cast(S, args) S.fn(S, args) end


return Spell
