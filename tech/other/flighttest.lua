require "/scripts/vec2.lua"
require "/stats/effects/fu_statusUtil.lua"
local foodThreshold=15--used by checkFood

function init()
	if not world.entitySpecies(entity.id()) then return end
	self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
	self.active=false
	self.available = true
	self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())
	self.timer = 0
	self.maxFallSpeed=config.getParameter("maxFallSpeed")
	self.fallingParameters=config.getParameter("fallingParameters")
	self.didInit=true
end

function uninit()
	animator.setParticleEmitterActive("feathers", false)
	animator.setParticleEmitterActive("butterflies", false)
	animator.stopAllSounds("activate")
end

function activeFlight()
	if config.getParameter("removesFallDamage",0) == 1 then
		status.addEphemeralEffects{{effect = "nofalldamage", duration = 0.1}}
	end
	mcontroller.controlParameters(self.fallingParameters or {})
	mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed or -100))
	animateFlight()
end

function animateFlight()
	if self.species == "saturn" then
		animator.setParticleEmitterOffsetRegion("butterflies", mcontroller.boundBox())
		animator.setParticleEmitterActive("butterflies", true)
	else
		animator.setParticleEmitterOffsetRegion("feathers", mcontroller.boundBox())
		animator.setParticleEmitterActive("feathers", true)
	end

	animator.setFlipped(mcontroller.facingDirection() < 0)
end

function update(args)
	if not self.didInit then init() end
	if args.moves["special1"] and not mcontroller.onGround() and not mcontroller.zeroG() and status.overConsumeResource("energy", 0.001) then
		status.removeEphemeralEffect("wellfed")
		if self.timer then
			self.timer = math.max(0, self.timer - args.dt)
			if self.timer == 0 then
				animator.playSound("activate")
				self.timer = 1
			end
		end
		if (checkFood() or foodThreshold) > foodThreshold then
			status.addEphemeralEffects{{effect = "foodcost", duration = 0.1}}
		else
			status.overConsumeResource("energy", (self.energyCostPerSecond or 0)*args.dt)
		end
		activeFlight()
	else
		idle()
	end
end

function idle()
	animator.setParticleEmitterActive("feathers", false)
	animator.setParticleEmitterActive("butterflies", false)
	animator.stopAllSounds("activate")
end