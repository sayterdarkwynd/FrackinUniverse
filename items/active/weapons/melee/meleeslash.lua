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
    --self.hitsListener = damageListener("inflictedHits", checkDamage)  --listen for damage
    --self.damageListener = damageListener("inflictedDamage", checkDamage)  --listen for damage
    --self.killListener = damageListener("Kill", checkDamage)  --listen for kills
end

--[[function calculateMasteries()
	self.shortswordMastery = 1 + status.stat("shortswordMastery")
	self.longswordMastery = 1 + status.stat("longswordMastery")
	self.rapierMastery = 1 + status.stat("rapierMastery")
	self.katanaMastery = 1 + status.stat("katanaMastery")
	self.daggerMastery = 1 + status.stat("daggerMastery")
	self.broadswordMastery = 1 + status.stat("broadswordMastery")
	self.quarterstaffMastery = 1 + status.stat("quarterstaffMastery")
	self.maceMastery = 1 + status.stat("maceMastery")
	self.shortspearMastery = 1 + status.stat("shortspearMastery")
	self.hammerMastery = 1 + status.stat("hammerMastery")
	self.axeMastery = 1 + status.stat("axeMastery")
	self.spearMastery = 1 + status.stat("spearMastery")
end]]
--[[
function checkDamage(notifications)

  for _,notification in pairs(notifications) do
    --check for individual hits
    if notification.sourceEntityId == entity.id() or notification.targetEntityId == entity.id() then
	    if not status.resourcePositive("health") then --count total kills
	    	notification.hitType = "Kill"
	    end
	    local hitType = notification.hitType
	    --sb.logInfo(hitType)

        --kill computation
	    if notification.hitType == "Kill" or notification.hitType == "kill" and world.entityType(notification.targetEntityId) == ("monster" or "npc") and world.entityCanDamage(notification.targetEntityId, entity.id()) then

	    end

	    --hit computation
	    if notification.hitType == "Hit" and world.entityType(notification.targetEntityId) == ("monster" or "npc") and world.entityCanDamage(notification.targetEntityId, entity.id()) then

	    end
      return
    end
  end
end
]]

-- Ticks on every update regardless of whether this is the active ability
function MeleeSlash:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.lowEnergy=((status.resource("energy") <= 1) or (status.resourceLocked("energy")))

	status.clearPersistentEffects("meleeEnergyLowPenalty")



	-- FR
	setupHelper(self, "meleeslash-fire")
    --self.hitsListener:update()
    --self.damageListener:update()
    --self.killListener:update()

	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
	if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
        self:setState(self.windup)
	end
end

-- State: windup
function MeleeSlash:windup()
	self.energyMax = math.max(status.resourceMax("energy"),0) -- due to weather and other cases it is possible to have a maximum of under 0.

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

	status.clearPersistentEffects("meleeEnergyLowPenalty")


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
				damageConfigCopy.baseDamage=damageConfigCopy.baseDamage*0.75
			end
			self.weapon:setDamage(damageConfigCopy, damageArea, self.fireTime)
		end
	)

	--vanilla cooldown rate
	self.cooldownTimer = self:cooldownTime()

	-- FR cooldown modifiers
	self.cooldownTimer = math.max(0, self.cooldownTimer * attackSpeedUp )	-- subtract FR bonus from total
end

function MeleeSlash:cooldownTime()
	return self.fireTime - self.stances.windup.duration - self.stances.fire.duration
end

function MeleeSlash:uninit()--this function is almost never called. so persistent status effects based on it are...dodo.
	self.weapon:setDamage()
	cancelEffects()
end

function cancelEffects()
	status.clearPersistentEffects("meleeEnergyLowPenalty")
	status.clearPersistentEffects("longswordbonus")
	status.clearPersistentEffects("macebonus")
	status.clearPersistentEffects("katanabonus")
	status.clearPersistentEffects("rapierbonus")
	status.clearPersistentEffects("shortspearbonus")
	status.clearPersistentEffects("daggerbonus")
	status.clearPersistentEffects("scythebonus")
    status.clearPersistentEffects("axebonus")
    status.clearPersistentEffects("hammerbonus")
	status.clearPersistentEffects("multiplierbonus")
	status.clearPersistentEffects("dodgebonus")
	status.clearPersistentEffects("listenerBonus")
	status.clearPersistentEffects("floranFoodPowerBonus")
	status.clearPersistentEffects("slashbonusdmg")
	status.clearPersistentEffects("masteryBonus")
	self.meleeCountslash = 0
	self.rapierTimerBonus = 0
	self.inflictedHitCounter = 0
end