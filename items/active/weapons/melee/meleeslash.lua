require "/scripts/FRHelper.lua"
require "/scripts/status.lua" --for damage listener

-- Melee primary ability
MeleeSlash = WeaponAbility:new()

function MeleeSlash:init()
	self.damageConfig.baseDamage = self.baseDps * self.fireTime
	self.energyUsage = self.energyUsage or 0
	self.weapon:setStance(self.stances.idle)
	self.cooldownTimer = self:cooldownTime()
	self.weapon.onLeaveAbility = function()
		self.weapon:setStance(self.stances.idle)
	end
    -- **************************
    -- FR and FU values
	attackSpeedUp = 0 -- base attackSpeed bonus
end

-- Ticks on every update regardless of whether this is the active ability
function MeleeSlash:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	-- velocity check
    velocityAdded = mcontroller.xVelocity()
    if velocityAdded > 0.01 or velocityAdded < 0 then
        activeHoldDamage = 1
    else
        activeHoldDamage = 0
    end

	self.lowEnergy=((status.resource("energy") <= 1) or (status.resourceLocked("energy")))
	-- FR
	setupHelper(self, "meleeslash-fire")

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
	if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
        self:setState(self.windup)
	end
end

-- State: windup
function MeleeSlash:windup()
	self.energyMax = math.max(status.resourceMax("energy"),0) -- due to weather and other cases it is possible to have a maximum of under 0.
	status.setStatusProperty(activeItem.hand().."Firing",true)
	local item
	if world.entityType(activeItem.ownerEntityId()) then
		item=world.entityHandItemDescriptor(activeItem.ownerEntityId(),activeItem.hand())
	end
	item=item and item.name

	if not item or not root.itemHasTag(item, "weapon") then --it isnt a weapon or we can't figure out what kind it is right now.
		 self.energyTotal = 0.00
	else
		self.energyTotal = math.min(math.max(0,(status.resource("energy")-1.0)), (self.energyMax * 0.05))
	end

	self.lowEnergy=(status.resource("energy") <= 1) or (not status.consumeResource("energy",self.energyTotal))

	self.weapon:setStance(self.stances.windup)

	if self.stances.windup.hold then
		while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
			coroutine.yield()
		end
	else
		util.wait(self.stances.windup.duration)
	end

	if self.energyUsage then
		status.overConsumeResource("energy", self.energyUsage)
	end

	if self.stances.preslash then
		self:setState(self.preslash)
	else
		self:setState(self.fire)
	end
end

-- State: preslash
-- brief frame in between windup and fire
function MeleeSlash:preslash()
	self.weapon:setStance(self.stances.preslash)
	self.weapon:updateAim()

	util.wait(self.stances.preslash.duration)
	self:setState(self.fire)
end

-- ***********************************************************************************************************
-- FR SPECIALS	Functions for projectile spawning
-- ***********************************************************************************************************
function MeleeSlash:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function MeleeSlash:aimVector()	-- fires straight
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle )
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function MeleeSlash:aimVectorRand() -- fires wherever it wants
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end
-- ***********************************************************************************************************
-- END FR SPECIALS
-- ***********************************************************************************************************

-- State: fire
function MeleeSlash:fire()

	self.weapon:setStance(self.stances.fire)
	self.weapon:updateAim()

    if self.helper then
        self.helper:runScripts("meleeslash-fire", self)
    end

	animator.setAnimationState("swoosh", "fire")
	animator.playSound(self.fireSound or "fire")
	animator.burstParticleEmitter((self.elementalType or self.weapon.elementalType) .. "swoosh")

	util.wait(self.stances.fire.duration,
		function()
			local damageArea = partDamageArea("swoosh")
			local damageConfigCopy=copy(self.damageConfig)
			if self.lowEnergy then
				damageConfigCopy.baseDamage=damageConfigCopy.baseDamage*0.8
			end
			self.weapon:setDamage(damageConfigCopy, damageArea, self.fireTime)
		end
	)

	--vanilla cooldown rate
	self.cooldownTimer = self:cooldownTime()

	-- FR cooldown modifiers
	self.cooldownTimer = math.max(0, self.cooldownTimer * attackSpeedUp )	-- subtract FR bonus from total
	status.setStatusProperty(activeItem.hand().."Firing",nil)
end

function MeleeSlash:cooldownTime()
	return self.fireTime - self.stances.windup.duration - self.stances.fire.duration
end

function MeleeSlash:uninit()--this function is almost never called. so persistent status effects based on it are...dodo.
	self.weapon:setDamage()
	status.setStatusProperty(activeItem.hand().."Firing",nil)
end
