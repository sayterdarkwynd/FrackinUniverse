require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"

function init()
	self.healingRate = 1.01 / config.getParameter("healTime", 420)
	script.setUpdateDelta(10)
	self.healTime=config.getParameter("healTime", 180)
	bonusHandler=effect.addStatModifierGroup({})
end

function activateVisualEffects()
	local lightLevel = getLight()
	if lightLevel <= 25 then
		animator.setParticleEmitterOffsetRegion("blood", mcontroller.boundBox())
		animator.setParticleEmitterActive("blood", true)
	end
end

function update(dt)
	nighttime = nighttimeCheck()
	underground = undergroundCheck()
	local lightLevel = getLight()
	if nighttime or underground then
		if lightLevel <= 25 then
			self.healingRate=((((26.0-lightLevel)/125.0)+1.0)/self.healTime)
		else
			self.healingRate=0.0
		end
	end
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.resourceMax("health")*self.healingRate*math.max(0,1+status.stat("healingBonus"))}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end