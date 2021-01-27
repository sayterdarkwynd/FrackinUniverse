require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.healingRate = 1.01 / config.getParameter("healTime", 420)
	script.setUpdateDelta(10)
	self.healTime=config.getParameter("healTime", 180)
end


function activateVisualEffects()
	local lightLevel = getLight()
	if lightLevel <= 25 then
		animator.setParticleEmitterOffsetRegion("blood", mcontroller.boundBox())
		animator.setParticleEmitterActive("blood", true)
	end
end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	return math.floor(math.min(world.lightLevel(position),1.0) * 100)
end

function nighttimeCheck()
	return world.timeOfDay() > 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
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
		--sb.logInfo("darkheal:"..lightLevel..":"..(self.healingRate*dt)..":".. math.max(0,1+status.stat("healingBonus"))..":"..(self.healingRate * dt * math.max(0,1+status.stat("healingBonus"))))
		status.modifyResourcePercentage("health", self.healingRate * dt * math.max(0,1+status.stat("healingBonus")))
	end
end
