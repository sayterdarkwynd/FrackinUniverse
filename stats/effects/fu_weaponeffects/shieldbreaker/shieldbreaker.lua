function init()
	shatter()
	handler=effect.addStatModifierGroup({
		{stat = "shieldHealth", effectiveMultiplier = 0},
		{stat = "shieldStamina", effectiveMultiplier = 0},
		{stat = "shieldStaminaRegen", effectiveMultiplier = 0},
		{stat = "perfectBlockLimitRegen", effectiveMultiplier = 0}
	})
end

function update(dt)
	shatter()
end

function shatter()
	if status.isResource("shieldHealth") then
		status.consumeResource("shieldHealth",status.resource("shieldHealth"))
	end
	if status.isResource("damageAbsorption") then
		status.consumeResource("damageAbsorption",status.resource("damageAbsorption"))
	end
	if status.isResource("perfectBlock") then
		status.consumeResource("perfectBlock",status.resource("perfectBlock"))
	end
	if status.isResource("perfectBlockLimit") then
		status.consumeResource("perfectBlockLimit",status.resource("perfectBlockLimit"))
	end
	if status.isResource("shieldStamina") then
		status.consumeResource("shieldStamina",status.resource("shieldStamina"))
	end
	if status.isResource("shieldStaminaRegenBlock") then
		status.modifyResource("shieldStamina",status.resourceMax("shieldStaminaRegenBlock"))
	end
end
