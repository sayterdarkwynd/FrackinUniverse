require "/scripts/vec2.lua"
require "/scripts/util.lua"

AimedProjectile = WeaponAbility:new()

function AimedProjectile:init()
	self.elementalType = self.elementalType or self.weapon.elementalType

	self.baseDamageFactor = config.getParameter("baseDamageFactor", 1.0)
	self.stances = self.stances

	activeItem.setCursor("/cursors/reticle0.cursor")
	self.weapon:setStance(self.stances.idle)

	self.weapon.onLeaveAbility = function()
		self:reset()
	end
end

function AimedProjectile:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	world.debugPoint(self:focusPosition(), "blue")

	if self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and not self.weapon.currentAbility
		and not status.resourceLocked("energy") then

		self:setState(self.charge)
	end
end

-- charge
function AimedProjectile:charge()
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

-- charged
function AimedProjectile:charged()
	self.weapon:setStance(self.stances.charged)

	animator.playSound(self.elementalType.."fullcharge")
	animator.playSound(self.elementalType.."chargedloop", -1)
	animator.setParticleEmitterActive(self.elementalType .. "charge", true)
	activeItem.setCursor("/cursors/chargeready.cursor")

	while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
		mcontroller.controlModifiers({runningSuppressed=true})

		coroutine.yield()
	end

	self:setState(self.discharge)
end

-- discharge
function AimedProjectile:discharge()
	self.weapon:setStance(self.stances.discharge)

	activeItem.setCursor("/cursors/reticle0.cursor")

	animator.playSound(self.elementalType.."activate")
	--sb.logInfo("%s",self)
	if status.overConsumeResource("energy", self.energyCost * self.baseDamageFactor) then

	self:createProjectiles()
	util.wait(self.stances.discharge.duration, function(dt)
		status.setResourcePercentage("energyRegenBlock", 1.0)
		end)
	animator.playSound(self.elementalType.."discharge")
	animator.stopAllSounds(self.elementalType.."chargedloop")
	end

	self:setState(self.cooldown)
end

-- cooldown
function AimedProjectile:cooldown()
	self.weapon:setStance(self.stances.cooldown)
--	self.weapon.aimAngle = 0

	animator.setAnimationState("charge", "discharge")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")

	util.wait(self.stances.cooldown.duration, function() end)
	self:reset()
end

-- create projectile
function AimedProjectile:createProjectiles()
	local position = self.focusPosition()
	local aim = self.weapon.aimAngle
	
	local pCount = self.projectileCount or 1
	-- bonus projectiles
	local bonus=status.stat("focalProjectileCountBonus")
	local flooredBonus=math.floor(bonus)
	if bonus~=flooredBonus then bonus=flooredBonus+(((math.random()<(bonus-flooredBonus)) and 1) or 0) end
	local initiallySingle=(pCount==1)
	local singleMultiplier=1+((initiallySingle and 0.1*bonus) or 0)
	pCount=((self.disableProjectileCountBonus and 0) or bonus)+pCount
	local pParams = copy(self.projectileParameters)

	pParams.power = singleMultiplier * self.baseDamageFactor * pParams.baseDamage * config.getParameter("damageLevelMultiplier") / pCount
	pParams.powerMultiplier = activeItem.ownerPowerMultiplier()

	if not world.lineTileCollision(mcontroller.position(), position) then
		for i=1,pCount do
			if i>1 then
				util.wait(self.stances.cooldown.duration/((1+status.stat("focalCastTimeMult"))), function() end)
				aim = self.weapon.aimAngle
			end
			world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(aim), math.sin(aim)}, false, pParams)
		end
	end
end

-- stone offset
function AimedProjectile:focusPosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

-- stop sounds and particles
function AimedProjectile:reset()
	self.weapon:setStance(self.stances.idle)
	animator.stopAllSounds(self.elementalType.."chargedloop")
	animator.stopAllSounds(self.elementalType.."fullcharge")
	animator.setAnimationState("charge", "idle")
	animator.setParticleEmitterActive(self.elementalType .. "charge", false)
	activeItem.setCursor("/cursors/reticle0.cursor")
end

-- reset
function AimedProjectile:uninit(weaponUninit)
	self:reset()
end
