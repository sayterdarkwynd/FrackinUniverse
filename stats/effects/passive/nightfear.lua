require "/stats/effects/fu_statusUtil.lua"

function init()
	nightFearEffects=effect.addStatModifierGroup({})
	script.setUpdateDelta(10)
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
