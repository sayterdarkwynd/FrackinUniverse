function init()

	
	nightFearEffects=effect.addStatModifierGroup({})
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
	if lightLevel <= 10 then
		effect.setStatModifierGroup(nightFearEffects,{
			{stat = "maxHealth", baseMultiplier = 0.95},
			{stat = "powerMultiplier", baseMultiplier = 0.95}
		})
		mcontroller.controlModifiers({speedModifier=1.1})
	else
		effect.setStatModifierGroup(nightFearEffects,{})
	end
end

function uninit()
	effect.removeStatModifierGroup(nightFearEffects)
end
