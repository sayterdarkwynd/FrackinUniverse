function init()
	self.powerBonus = 0.1
	script.setUpdateDelta(10)
end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = math.min(world.lightLevel(position),1.0)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function update(dt)
	local lightLevel = getLight()
	if lightLevel <= 55 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = config.getParameter("powerBonus",0) + 1.2}
		})
		mcontroller.controlModifiers({ speedModifier = 1.2 })
	elseif lightLevel <= 65 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = config.getParameter("powerBonus",0) + 1.1}
		})
		mcontroller.controlModifiers({ speedModifier = 1.1 })
	elseif lightLevel <= 75 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = config.getParameter("powerBonus",0) + 1.0}
		})
		mcontroller.controlModifiers({ speedModifier = 1.0 })
	elseif lightLevel <= 85 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = config.getParameter("powerBonus",0) + 0.9}
		})
		mcontroller.controlModifiers({ speedModifier = 0.9 })
	elseif lightLevel <= 95 then
		status.setPersistentEffects("trollEffects", {
			{stat = "maxHealth", baseMultiplier = config.getParameter("powerBonus",0) + 0.8}
		})
		mcontroller.controlModifiers({ speedModifier = 0.8 })
	else
		status.clearPersistentEffects("trollEffects")
	end
end