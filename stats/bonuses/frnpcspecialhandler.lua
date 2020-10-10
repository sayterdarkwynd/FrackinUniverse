
function update(dt)
	--sb.logInfo("ree")
	if not world.isNpc(entity.id()) then return end
	if status.resource("health")<1.0 then
		if not done then
			effect.addStatModifierGroup({{stat="healthRegen",effectiveMultiplier=0}})
		end
		status.setResource("health",0)
	end
end
