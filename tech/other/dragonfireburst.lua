require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"
local foodThreshold=15--used by checkFood

function init()
end

function checkFood()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resource("food")) or foodThreshold
end

function activeFlight(foodValue)
	status.removeEphemeralEffect("wellfed")
	animator.playSound("activate",3)
	animator.playSound("recharge")
	animator.setSoundVolume("activate", 0.5,0)
	animator.setSoundVolume("recharge", 0.375,0)
	world.spawnProjectile("flamethrower", self.mouthPosition, entity.id(), aimVector(), false, { power = ((foodValue /60) + (status.resource("energy")/150) + (status.stat("protection") /250)), damageSourceKind = "fire" })
end

function aimVector()
	local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function update(args)
	self.mouthPosition = vec2.add(mcontroller.position(), {mcontroller.facingDirection(),(args.moves["down"] and -0.7) or 0.15})

	self.firetimer = math.max(0, (self.firetimer or 0) - args.dt)
	if args.moves["special1"] and status.overConsumeResource("energy", 0.001) then
		local foodValue=checkFood()
		if foodValue > foodThreshold then
			status.addEphemeralEffects{{effect = "foodcostfire", duration = 0.02}}
		else
			status.overConsumeResource("energy", 0.6)
		end

		if self.firetimer == 0 then
			self.firetimer = 0.1
			activeFlight(foodValue)
		end

	else
		animator.stopAllSounds("activate")
	end
end