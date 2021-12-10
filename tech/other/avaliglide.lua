require "/scripts/vec2.lua"
require "/stats/effects/fu_statusUtil.lua"
local foodThreshold=15--used by checkFood

function init()
	initCommonParameters()
end

function initCommonParameters()
	self.bombTimer = 0
	self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
	self.active=false
	self.available = true
	self.timer = 0
	self.active2 = 0
	self.active3 = 0
	self.forceDeactivateTime = 3
	self.fallingParameters1=config.getParameter("fallingParameters1")
	self.fallingParameters2=config.getParameter("fallingParameters2")
	self.maxFallSpeed1=config.getParameter("maxFallSpeed1")
	self.maxFallSpeed2=config.getParameter("maxFallSpeed2")
end

function uninit()
	animator.setParticleEmitterActive("feathers", false)
	animator.stopAllSounds("activate")
	animator.stopAllSounds("recharge")
	status.clearPersistentEffects("glide")
	deactivate()
end

function checkFood()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resource("food")) or foodThreshold
end

function checkStance()
	if self.pressDown and self.active2 == 0 then
		animator.playSound("slowfallMode")
		animator.setSoundVolume("slowfallMode", 2,0)
		self.active2 = 1
		self.active3 = 0
	elseif self.pressUp and self.active3 == 0 then
		animator.playSound("glideMode")
		animator.setSoundVolume("glideMode", 2,0)
		self.active2 = 0
		self.active3 = 1
	end
	self.bombTimer = 1
end


function activeFlight()
	animateFlight()
end

function animateFlight()
	animator.setParticleEmitterOffsetRegion("feathers", mcontroller.boundBox())
	animator.setParticleEmitterActive("feathers", true)
	animator.setFlipped(mcontroller.facingDirection() < 0)
end


function update(args)
	if not self.specialLast and args.moves["special1"] then
		attemptActivation()
	end

	self.specialLast = args.moves["special1"]
	self.pressSpecial = args.moves["special1"]
	self.pressJump = args.moves["jump"]
	self.pressUp = args.moves["up"]
	self.pressDown = args.moves["down"]

	if not args.moves["special1"] then
		self.forceTimer = nil
	end

	if self.active and status.overConsumeResource("energy", 0.001) then
		status.removeEphemeralEffect("wellfed")

		if self.bombTimer > 0 then
			self.bombTimer = math.max(0, self.bombTimer - args.dt)
		end

		if self.pressDown or self.pressDown and self.active2== 1 then	--slowfall stance
			if not mcontroller.onGround() and not mcontroller.zeroG() then
				status.setPersistentEffects("glide", {
					{stat = "fallDamageMultiplier", effectiveMultiplier = 0.35}--,
					--{stat = "gliding", amount = 0}
				})
			end
			if self.bombTimer == 0 then
				checkStance()
			end
		end

		if self.pressUp or self.pressUp and self.active3== 1 then	-- glide stance
			if not mcontroller.onGround() and not mcontroller.zeroG() then
				status.setPersistentEffects("glide", {
					{stat = "fallDamageMultiplier", effectiveMultiplier = 0.35},
					{stat = "gliding", amount = 1}
				})
			end
			if self.bombTimer == 0 then
				checkStance()
			end
		end

		if not mcontroller.onGround() and not mcontroller.zeroG() then
			if self.active2 == 1 then
				mcontroller.controlParameters(self.fallingParameters1 or {})
				mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed1 or -100))
			elseif self.active3 == 1 then
				mcontroller.controlParameters(self.fallingParameters2 or {})
				mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), self.maxFallSpeed2 or -100))
			end
			if checkFood() > foodThreshold then
				status.addEphemeralEffects{{effect = "foodcost", duration = 0.1}}
			else
				status.overConsumeResource("energy", (self.energyCostPerSecond or 0)*args.dt)
			end
			activeFlight()
		end

		checkForceDeactivate(args.dt)
	end
end

function attemptActivation()
	if not self.active then
		activate()
	elseif self.active then
			deactivate()
		if not self.forceTimer then
			self.forceTimer = 0
		end
	end
end

function checkForceDeactivate(dt)
	if self.forceTimer then
		self.forceTimer = self.forceTimer + dt
		if self.forceTimer >= self.forceDeactivateTime then
			deactivate()
			self.forceTimer = nil
			status.clearPersistentEffects("glide")
		else
			attemptActivation()
		end
		return true
	else
		return false
	end
end

function activate()
	if not self.active then
		animator.playSound("activate")
	else
		status.clearPersistentEffects("glide")
		deactivate()
	end
	self.active = true
end

function deactivate()
	if self.active then
		status.clearPersistentEffects("glide")
		animator.setParticleEmitterActive("feathers", false)
		animator.stopAllSounds("activate")
		animator.stopAllSounds("recharge")
	end
	self.active = false
end
