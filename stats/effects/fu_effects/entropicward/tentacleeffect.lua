local eType

function update(dt)
	if not eType then
		eType=world.entityType(entity.id())
	elseif eType ~= "player" then
		if not status.statPositive("shadowImmunity") then
			status.addEphemeralEffect("l6doomed", 6, entity.id())
			status.addEphemeralEffect("blacktarslow", 6, entity.id())
			status.addEphemeralEffect("insanity", 6, entity.id())
			animator.setAnimationState("aura", "on")
		elseif status.statPositive("shadowImmunity") then
			animator.setAnimationState("aura", "off")
		end
	end
end
