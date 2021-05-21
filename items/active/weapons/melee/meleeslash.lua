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
	    cancelEffects(true)
		self.weapon:setStance(self.stances.idle)
		calculateMasteries() --determine any active Masteries
	end
    -- **************************
    -- FR and FU values
	-- FU EFFECTS

	primaryItem = world.entityHandItem(entity.id(), "primary")	--check what they have in hand
	altItem = world.entityHandItem(entity.id(), "alt")
	if primaryTagCacheItem~=primaryItem then
		primaryTagCache=primaryItem and tagsToKeys(fetchTags(root.itemConfig(primaryItem))) or {}
		primaryTagCacheItem=primaryItem
	elseif not primaryItem then
		primaryTagCache={}
	end
	if altTagCacheItem~=altItem then
		altTagCache=altItem and tagsToKeys(fetchTags(root.itemConfig(altItem))) or {}
		altTagCacheItem=altItem
	elseif not altItem then
		altTagCache={}
	end

	attackSpeedUp = 0 -- base attackSpeed bonus
end

function calculateMasteries()
	self.hammerMastery = 1 + status.stat("hammerMastery")
	self.axeMastery = 1 + status.stat("axeMastery")
	self.spearMastery = 1 + status.stat("spearMastery")
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

	status.clearPersistentEffects("meleeEnergyLowPenalty")
	-- FR
	setupHelper(self, "meleeslash-fire")


	-- *****************************************Passive Weapon Masteries and Item Tag Caching ***************************
	-- ******************************************************************************************************************
	-- only apply the following if the character has a Mastery trait. These are ONLY obtained from specific types of gear or loot.
	-- this section also primes the code for later blocks. all loading of mastery variables should be done here. this is also one of two places where item tag caching occurs.
	-- this is also a good place to put simple, nonconditional mastery bonuses.

	--cache tag data for use
	if primaryTagCacheItem~=primaryItem then
		primaryTagCache=primaryItem and tagsToKeys(fetchTags(root.itemConfig(primaryItem))) or {}
		primaryTagCacheItem=primaryItem
	elseif not primaryItem then
		primaryTagCache={}
	end
	if altTagCacheItem~=altItem then
		altTagCache=altItem and tagsToKeys(fetchTags(root.itemConfig(altItem))) or {}
		altTagCacheItem=altItem
	elseif not altItem then
		altTagCache={}
	end
	local hand=activeItem.hand()
	local masterybonus={}

	if primaryTagCache["axe"] or altTagCache["axe"] or primaryTagCache["greataxe"] or altTagCache["greataxe"] then
		self.axeMastery = 1 + status.stat("axeMastery")
		self.axeMasteryHalved = ((self.axeMastery -1) / 2) + 1
	end	
	if primaryTagCache["hammer"] or altTagCache["hammer"] then
		self.hammerMastery = 1 + status.stat("hammerMastery")
		self.hammerMasteryHalved = ((self.hammerMastery -1) / 2) + 1
	end	
	if primaryTagCache["spear"] or altTagCache["spear"] then
		self.spearMastery = 1 + status.stat("spearMastery")
		self.spearMasteryHalved = ((self.spearMastery -1) / 2) + 1
	end	

	if primaryTagCache["spear"] or altTagCache["spear"] then
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","spearbonus")
		status.setPersistentEffects("spearbonus", {
			{stat = "critChance", amount = 2 * self.spearMastery},
			{stat = "powerMultiplier", effectiveMultiplier = 1.01 * self.spearMasteryHalved},
			{stat = "dashtechBonus", amount = 0.08 * self.spearMastery}
		})
	end
	if primaryTagCache["hammer"] or altTagCache["hammer"] then
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","hammerbonus")
		status.setPersistentEffects("hammerbonus", {
			{stat = "powerMultiplier", effectiveMultiplier = 1.01 * self.hammerMasteryHalved}
		})
	end

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
				damageConfigCopy.baseDamage=damageConfigCopy.baseDamage*0.8
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
	cancelEffects(true)
	self.weapon:setDamage()
end

function cancelEffects()
	status.clearPersistentEffects("meleeEnergyLowPenalty")
	status.setPersistentEffects("meleeEnergyLowPenalty",{})
	status.clearPersistentEffects("spearbonus")
	status.setPersistentEffects("spearbonus",{})
	status.clearPersistentEffects("scythebonus")
	status.setPersistentEffects("scythebonus",{})
    status.clearPersistentEffects("axebonus")
    status.setPersistentEffects("axebonus",{})
    status.clearPersistentEffects("hammerbonus")
    status.setPersistentEffects("hammerbonus",{})
	status.clearPersistentEffects("multiplierbonus")
	status.setPersistentEffects("multiplierbonus",{})
	status.clearPersistentEffects("dodgebonus")
	status.setPersistentEffects("dodgebonus",{})
	status.clearPersistentEffects("listenerBonus")
	status.setPersistentEffects("listenerBonus",{})
	status.clearPersistentEffects("floranFoodPowerBonus")
	status.setPersistentEffects("floranFoodPowerBonus",{})
	status.clearPersistentEffects("slashbonusdmg")
	status.setPersistentEffects("slashbonusdmg",{})
	status.clearPersistentEffects("masteryBonus")
	status.setPersistentEffects("masteryBonus",{})
	self.meleeCountslash = 0
	self.rapierTimerBonus = 0
	self.inflictedHitCounter = 0
end


function fetchTags(iConf)
	if not iConf or not iConf.config then return {} end
	local tags={}
	for k,v in pairs(iConf.config or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,copy(v))
		end
	end
	for k,v in pairs(iConf.parameters or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,copy(v))
		end
	end
	return tags
end

function tagsToKeys(tags)
	local buffer={}
	for _,v in pairs(tags) do
		buffer[v]=true
	end
	return buffer
end