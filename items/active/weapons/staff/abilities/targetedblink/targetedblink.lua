require "/scripts/vec2.lua"
require "/scripts/util.lua"

TargetedBlink = WeaponAbility:new()

function TargetedBlink:init()
	--storage.projectiles = storage.projectiles or {}

	self.elementalType = self.elementalType or self.weapon.elementalType

	self.stances = config.getParameter("stances")

	activeItem.setCursor("/cursors/reticle0.cursor")
	self.weapon:setStance(self.stances.idle)

	self.weapon.onLeaveAbility = function()
		self:reset()
	end
end

function TargetedBlink:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	--self:updateProjectiles()

	world.debugPoint(self:focusPosition(), "blue")

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and not self.weapon.currentAbility
		and not status.resourceLocked("energy") then

		self:setState(self.charge)
	end
end

function TargetedBlink:charge()
	self.weapon:setStance(self.stances.charge)

	animator.playSound(self.elementalType.."charge")
	animator.setAnimationState("charge", "charge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)
	activeItem.setCursor("/cursors/charge2.cursor")

	local chargeTimer = self.stances.charge.duration * (1+status.stat("focalCastTimeMult"))
	while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		chargeTimer = chargeTimer - self.dt

		mcontroller.controlModifiers({runningSuppressed=true})

		coroutine.yield()
	end

	animator.stopAllSounds(self.elementalType.."charge")

	if chargeTimer <= 0 then
		self:setState(self.charged)
	else
		animator.playSound(self.elementalType.."discharge")
		self:setState(self.cooldown)
	end
end

function TargetedBlink:charged()
	self.weapon:setStance(self.stances.charged)

	animator.playSound(self.elementalType.."fullcharge")
	animator.playSound(self.elementalType.."chargedloop", -1)
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)

	local targetValid
	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		targetValid = self:targetValid(activeItem.ownerAimPosition())
		activeItem.setCursor(targetValid and "/cursors/chargeready.cursor" or "/cursors/chargeinvalid.cursor")

		mcontroller.controlModifiers({runningSuppressed=true})

		coroutine.yield()
	end

	self:setState(self.discharge)
end

function TargetedBlink:discharge()
	self.weapon:setStance(self.stances.discharge)

	activeItem.setCursor("/cursors/reticle0.cursor")

	if self:targetValid(activeItem.ownerAimPosition()) and status.overConsumeResource("energy", self.energyCost) then
		animator.playSound(self.elementalType.."activate")
		self:blink()
	else
		animator.playSound(self.elementalType.."discharge")
		self:setState(self.cooldown)
		return
	end

	util.wait(self.stances.discharge.duration, function(dt)
		status.setResourcePercentage("energyRegenBlock", 1.0)
	end)

	animator.playSound(self.elementalType.."discharge")
	animator.stopAllSounds(self.elementalType.."chargedloop")

	self:setState(self.cooldown)
end

function TargetedBlink:cooldown()
	self.weapon:setStance(self.stances.cooldown)
	self.weapon.aimAngle = 0

	animator.setAnimationState("charge", "discharge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")

	util.wait(self.stances.cooldown.duration, function()

	end)
end

function TargetedBlink:targetValid(aimPos)
	local focusPos = self:focusPosition()
	return world.magnitude(focusPos, aimPos) <= (self.maxCastRange*(1+status.stat("focalRangeMult")))
	--and not world.lineTileCollision(mcontroller.position(), focusPos)
	--and not world.lineTileCollision(focusPos, aimPos)
end

function TargetedBlink:focusPosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

function TargetedBlink:reset()
	self.weapon:setStance(self.stances.idle)
	animator.stopAllSounds(self.elementalType.."chargedloop")
	animator.stopAllSounds(self.elementalType.."fullcharge")
	animator.setAnimationState("charge", "idle")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")
	status.clearPersistentEffects("weaponMovementAbility")
	animator.setGlobalTag("directives", "")
end

function TargetedBlink:uninit()
	self:reset()
end

function TargetedBlink:blink()
	local blinkPosition = self.findBlinkPosition()
	status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})
	status.addEphemeralEffect("blinkout")
	util.wait(0.25)
	status.removeEphemeralEffect("blinkout")
	status.addEphemeralEffect("blinkin")
	util.wait(0.25)
	status.removeEphemeralEffect("blinkin")
	mcontroller.setPosition(blinkPosition)
end

function TargetedBlink:findBlinkPosition()
	local searchPosition = activeItem.ownerAimPosition()
	local groundPosition = findGroundPosition(searchPosition, -self.blinkYTolerance, self.blinkYTolerance, false, {"Null", "Block", "Dynamic", "Platform"})
	if groundPosition then
		return groundPosition
	end
end
