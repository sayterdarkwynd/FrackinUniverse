require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	self.stances = config.getParameter("stances")
	activeItem.setCursor("/cursors/reticle0.cursor")
	setStance(self.stances.idle)
end

function update(dt, fireMode, shiftHeld)
	if (fireMode == "primary") and not status.resourceLocked("energy") and not state then state=charge end
	if state then state(dt,fireMode,shiftHeld) end
end

function charge(dt)
	setStance(self.stances.charge)
	animator.setAnimationState("charge", "charge")
	activeItem.setCursor("/cursors/charge2.cursor")
	chargeTimer = self.stances.charge.duration
	state=charging
end

function charging(dt,fireMode)
	if chargeTimer > 0 and fireMode == "primary" then
		chargeTimer = chargeTimer - dt

		mcontroller.controlModifiers({runningSuppressed=true})
	elseif chargeTimer <= 0 then
		activeItem.setCursor("/cursors/chargeready.cursor")
		state=charged
	else
		chargeTimer=0
		state=cooldown
	end
end

function charged(dt,fireMode)
	setStance(self.stances.charged)

	if fireMode == "primary" then
		mcontroller.controlModifiers({runningSuppressed=true})
	else
		state=discharge
	end
end

function discharge(dt,_,shiftHeld)
	setStance(self.stances.discharge)

	activeItem.setCursor("/cursors/reticle0.cursor")

	if status.overConsumeResource("energy", status.stat("maxEnergy")) then
		if shiftHeld then
			world.sendEntityMessage(activeItem.ownerEntityId(),"recruits.summon")
		else
			world.sendEntityMessage(activeItem.ownerEntityId(),"pets.summon")
		end
		chargeTimer=self.stances.discharge.duration
		state=discharging
	else
		state=cooldown
		return
	end
end

function discharging(dt)
	status.setResourcePercentage("energyRegenBlock", 1.0)
	if chargeTimer > 0 then
		chargeTimer = chargeTimer - dt

		mcontroller.controlModifiers({runningSuppressed=true})
	else
		state=cooldown
	end
end

function cooldown(dt)
	status.setResourcePercentage("energyRegenBlock", 1.0)
	setStance(self.stances.cooldown)

	animator.setAnimationState("charge", "discharge")
	activeItem.setCursor("/cursors/reticle0.cursor")

	chargeTimer=self.stances.cooldown.duration
	state=coolingDown
end

function coolingDown(dt)
	status.setResourcePercentage("energyRegenBlock", 1.0)
	if chargeTimer > 0 then
		chargeTimer = chargeTimer - dt
	else
		state=reset
	end
end

function reset(dt)
	status.setResourcePercentage("energyRegenBlock", 1.0)
	setStance(self.stances.idle)
	animator.setAnimationState("charge", "idle")
	activeItem.setCursor("/cursors/reticle0.cursor")
	state=nil
end

function uninit()
	reset()
end

function setStance(stance)
	stance=stance or {}
	self.stance = stance
	self.weaponOffset = stance.weaponOffset or {0,0}
	self.relativeWeaponRotation = util.toRadians(stance.weaponRotation or 0)
	self.relativeWeaponRotationCenter = stance.weaponRotationCenter or {0, 0}
	self.relativeArmRotation = util.toRadians(stance.armRotation or 0)
	self.armAngularVelocity = util.toRadians(stance.armAngularVelocity or 0)
	self.weaponAngularVelocity = util.toRadians(stance.weaponAngularVelocity or 0)

	for stateType, state in pairs(stance.animationStates or {}) do
		animator.setAnimationState(stateType, state)
	end

	for _, soundName in pairs(stance.playSounds or {}) do
		animator.playSound(soundName)
	end

	for _, particleEmitterName in pairs(stance.burstParticleEmitters or {}) do
		animator.burstParticleEmitter(particleEmitterName)
	end

	activeItem.setFrontArmFrame(self.stance.frontArmFrame)
	activeItem.setBackArmFrame(self.stance.backArmFrame)
	activeItem.setTwoHandedGrip(stance.twoHanded or false)
	activeItem.setRecoil(stance.recoil == true)
end