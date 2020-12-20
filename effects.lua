return {

	hurt = function(bolt, actor)
		if actor.health then
			actor.health = actor.health - bolt.damage
		end
		bolt.dead = true
	end,

	swap = function(bolt, actor)
		local ox, oy = bolt.owner:center()
		bolt.owner:setPos(actor:center())
		actor:setPos(ox, oy)
		bolt.dead = true
	end

}
