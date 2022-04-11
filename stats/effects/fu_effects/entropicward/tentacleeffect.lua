function init()
	if world.entityType(entity.id()) == "player" then
		animator.setAnimationState("aura", "on")
		effect.addStatModifierGroup({{stat = "protection", effectiveMultiplier = 1.25 }})
		if (math.random(1,100) >= 75) then
			world.spawnItem("fumadnessresource",entity.position(),math.random(1,12))
		end
	elseif not status.statPositive("shadowImmunity") then
		status.addEphemeralEffect("l6doomed", 6, entity.id())
		status.addEphemeralEffect("blacktarslow", 6, entity.id())
		status.addEphemeralEffect("insanity", 6, entity.id())
		animator.setAnimationState("aura", "on")
		effect.addStatModifierGroup({{stat = "physicalResistance", amount = config.getParameter("resistanceAmount", 0)}})
	else
		effect.expire()
		return
	end
end

function update(dt)
	if (world.entityType(entity.id()) ~= "player") and status.statPositive("shadowImmunity") then
		effect.expire()
		return
	end
end

function uninit()
	--[[if world.entityType(entity.id()) ~= "player" then
		status.removeEphemeralEffect("blacktarslow")
		status.removeEphemeralEffect("insanity")
		status.removeEphemeralEffect("l6doomed")
	end]]
end
