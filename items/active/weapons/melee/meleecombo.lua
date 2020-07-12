require("/scripts/FRHelper.lua")

-- Melee primary ability
MeleeCombo = WeaponAbility:new()

function MeleeCombo:init()
status.clearPersistentEffects("combobonusdmg")
	self.comboStep = 1

	self.energyUsage = self.energyUsage or 0

	self:computeDamageAndCooldowns()

	self.weapon:setStance(self.stances.idle)

	self.edgeTriggerTimer = 0
	self.flashTimer = 0
	self.cooldownTimer = self.cooldowns[1]

	self.animKeyPrefix = self.animKeyPrefix or ""

	self.weapon.onLeaveAbility = function()
	self.weapon:setStance(self.stances.idle)
	end

-- **************************************************
-- FU EFFECTS

    primaryItem = world.entityHandItem(entity.id(), "primary")  --check what they have in hand
    altItem = world.entityHandItem(entity.id(), "alt")

-- **************************************************
-- FR EFFECTS
-- **************************************************
	self.species = world.sendEntityMessage(activeItem.ownerEntityId(), "FR_getSpecies")
	if status.isResource("food") then
		self.foodValue = status.resource("food")	--check our Food level
	else
		self.foodValue = 60
	end
	attackSpeedUp = 0 -- base attackSpeed

	if self.meleeCount == nil then
		self.meleeCount = 0
	end
	if self.meleeCount2 == nil then
		self.meleeCount2 = 0
	end

end
-- **************************************************

-- Ticks on every update regardless if this is the active ability
function MeleeCombo:update(dt, fireMode, shiftHeld)

	WeaponAbility.update(self, dt, fireMode, shiftHeld)
	if not attackSpeedUp then
        attackSpeedUp = 0
	end

    --longswords are way less effective when dual wielding, and much more effective when using with a shield
    if (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem, "longsword")) then --longsword check (is worn)
      if not (altItem) then --longsword check (1 handed)
 	    status.setPersistentEffects("longswordbonus", {{stat = "powerMultiplier", effectiveMultiplier = 1.05},{stat = "critChance", amount = 1}})     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("longswordbonus", {
		    	{stat = "shieldBash", amount = 4},
		    	{stat = "shieldBashPush", amount = 1},
		    	{stat = "protection", effectiveMultiplier = 1.15},
		    	{stat = "critChance", amount = 0.5}
	        })     		
    	end  
    	if (primaryItem and root.itemHasTag(primaryItem, "longsword")) and (altItem and root.itemHasTag(altItem, "weapon")) or 
    	   (altItem and root.itemHasTag(altItem, "longsword")) and (primaryItem and root.itemHasTag(primaryItem, "weapon")) then
    	    status.setPersistentEffects("longswordbonus", {
		        {stat = "powerMultiplier", effectiveMultiplier = 0.80},
		        {stat = "maxEnergy", effectiveMultiplier =  1.12},
		    	{stat = "protection", effectiveMultiplier = 0.80},
		    	{stat = "critChance", baseMultiplier = 0.50}
	      	}) 
	      	status.addEphemeralEffects{{effect = "runboostdebuff10", duration = 0.02}}  
    	end      	   	    	
      end		
	end

    --maces are way less effective when dual wielding, and much more effective when using with a shield
    if (primaryItem and root.itemHasTag(primaryItem, "mace")) or (altItem and root.itemHasTag(altItem, "mace")) then --mace check (is worn)
      if not (altItem) then --longsword check (1 handed)
 	    status.setPersistentEffects("macebonus", {{stat = "powerMultiplier", effectiveMultiplier = 1.10},{stat = "stunChance", amount = 2}})     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("macebonus", {
		    	{stat = "shieldBash", amount = 7},
		    	{stat = "shieldBashPush", amount = 3},
		    	{stat = "protection", effectiveMultiplier = 1.10},
		    	{stat = "maxHealth", effectiveMultiplier = 1.15}
	        })     		
    	end  
    	if (primaryItem and root.itemHasTag(primaryItem, "mace")) and (altItem and root.itemHasTag(altItem, "weapon")) or 
    	   (altItem and root.itemHasTag(altItem, "mace")) and (primaryItem and root.itemHasTag(primaryItem, "weapon")) then
    	    status.setPersistentEffects("macebonus", {
		        {stat = "powerMultiplier", effectiveMultiplier = 0.80},
		        {stat = "maxEnergy", effectiveMultiplier =  0.80},
		    	{stat = "critChance", baseMultiplier = 0.85},
		    	{stat = "stunChance", baseMultiplier = 0.50}
	      	})  
    	end      	   	    	
      end		
	end

    --katanas are not great for shield use
    if (primaryItem and root.itemHasTag(primaryItem, "katana")) or (altItem and root.itemHasTag(altItem, "katana")) then --mace check (is worn)
      if not (altItem) then --katana check (1 handed)
 	    status.setPersistentEffects("katanabonus", {{stat = "powerMultiplier", effectiveMultiplier = 1.10},{stat = "critChance", amount = 2}})     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("katanabonus", {
		    	{stat = "protection", effectiveMultiplier = 0.9},
		    	{stat = "critChance", baseMultiplier = 0.5},
		    	{stat = "powerMultiplier", effectiveMultiplier = 0.85}
	        })     		
    	end  
    	if (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem, "longsword")) or  --suck with large dual-wields
    	   (primaryItem and root.itemHasTag(primaryItem, "katana")) or (altItem and root.itemHasTag(altItem, "katana")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "axe")) or (altItem and root.itemHasTag(altItem, "axe")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "flail")) or (altItem and root.itemHasTag(altItem, "flail")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "shortspear")) or (altItem and root.itemHasTag(altItem, "shortspear")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "mace")) or (altItem and root.itemHasTag(altItem, "mace")) then
    	    status.setPersistentEffects("katanabonus", {
		        {stat = "protection", effectiveMultiplier =  0.75},
		        {stat = "powerMultiplier", amount = 0.75},
		        {stat = "protection", amount = 0.90}
	      	}) 
	      	status.addEphemeralEffects{{effect = "runboostdebuff10", duration = 0.02}} 
    	end     	
    	if (primaryItem and root.itemHasTag(primaryItem, "shortsword")) or (altItem and root.itemHasTag(altItem, "shortsword")) or  --increased crit damage and energy
    	   (primaryItem and root.itemHasTag(primaryItem, "dagger")) or (altItem and root.itemHasTag(altItem, "dagger")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "rapier")) or (altItem and root.itemHasTag(altItem, "rapier")) then
    	    status.setPersistentEffects("katanabonus", {
		        {stat = "maxEnergy", effectiveMultiplier =  1.15},
		        {stat = "critDamage", amount = 0.25}
	      	}) 
		    status.addEphemeralEffects{{effect = "runboost10", duration = 0.02}}
    	end 
    	if (primaryItem and root.itemHasTag(primaryItem, "ranged")) or (altItem and root.itemHasTag(altItem, "ranged")) then
    	    status.setPersistentEffects("katanabonus", {
		        {stat = "maxEnergy", effectiveMultiplier =  1.10},
		        {stat = "critDamage", amount = 0.125},
		    	{stat = "powerMultiplier", effectiveMultiplier = 0.85}
	      	}) 
		    status.addEphemeralEffects{{effect = "runboost5", duration = 0.02}}
    	end     	     	   	    	
      end		
	end


	if self.cooldownTimer > 0 then
        self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
        if self.cooldownTimer == 0 then
            self:readyFlash()
        end
    end

	if self.flashTimer > 0 then
        self.flashTimer = math.max(0, self.flashTimer - self.dt)
        if self.flashTimer == 0 then
            animator.setGlobalTag("bladeDirectives", "")
        end
	end

	self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
	if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
        self.edgeTriggerTimer = self.edgeTriggerGrace
	end
	self.lastFireMode = fireMode

	if not self.weapon.currentAbility and self:shouldActivate() then
        self:setState(self.windup)
	end
end


-- ******************************************
-- FR FUNCTIONS
function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = world.lightLevel(position)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function MeleeCombo:firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function MeleeCombo:aimVector()	-- fires straight
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle )
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end

function MeleeCombo:aimVectorRand() -- fires wherever it wants
	local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
	aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	return aimVector
end
-- *****************************************

-- State: windup
function MeleeCombo:windup()
	local stance = self.stances["windup"..self.comboStep]

	self.weapon:setStance(stance)
	self.edgeTriggerTimer = 0

	if stance.hold then
        while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
            coroutine.yield()
        end
	else
        util.wait(stance.duration)
	end

	if self.energyUsage then
        status.overConsumeResource("energy", self.energyUsage)
	end

	if self.stances["preslash"..self.comboStep] then
        self:setState(self.preslash)
	else
        self:setState(self.fire)
	end
end

-- State: wait
-- waiting for next combo input
function MeleeCombo:wait()
	local stance = self.stances["wait"..(self.comboStep - 1)]

	self.weapon:setStance(stance)

	util.wait(stance.duration, function()
        if self:shouldActivate() then
            self:setState(self.windup)
            return
        end
	end)

	self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
	-- *** FR
	self.cooldownTimer = math.max(0, self.cooldownTimer - attackSpeedUp)
	self.comboStep = 1

end

-- State: preslash
-- brief frame in between windup and fire
function MeleeCombo:preslash()
	local stance = self.stances["preslash"..self.comboStep]

	self.weapon:setStance(stance)
	self.weapon:updateAim()

	util.wait(stance.duration)

	self:setState(self.fire)
end

-- State: fire
function MeleeCombo:fire()
	local stance = self.stances["fire"..self.comboStep]

	self.weapon:setStance(stance)
	self.weapon:updateAim()

	local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
	animator.setAnimationState("swoosh", animStateKey)
	animator.playSound(animStateKey)

	local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
	animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
	animator.burstParticleEmitter(swooshKey)

    --*************************************
    -- FU/FR ABILITIES
    --*************************************
    if not self.helper and self.species:succeeded() then
		self.helper = FRHelper:new(self.species:result(), world.entityGender(activeItem.ownerEntityId()))
		self.helper:loadWeaponScripts("meleecombo-fire")
	end
	if self.helper then
    	self.helper:runScripts("meleecombo-fire", self)
	end
	--**************************************

	util.wait(stance.duration, function()
        local damageArea = partDamageArea("swoosh")
        self.weapon:setDamage(self.stepDamageConfig[self.comboStep], damageArea)
	end)

	if self.comboStep < self.comboSteps then
        self.comboStep = self.comboStep + 1
        self:setState(self.wait)
	else
    	self.cooldownTimer = self.cooldowns[self.comboStep]
		-- **** FR
		-- old	self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep] - attackSpeedUp)

    	self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep] *( 1 - attackSpeedUp))
		-- *****
    	self.comboStep = 1
	end
end

function MeleeCombo:shouldActivate()
	if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
        if self.comboStep > 1 then
            return self.edgeTriggerTimer > 0
        else
            return self.fireMode == (self.activatingFireMode or self.abilitySlot)
        end
	end
end

function MeleeCombo:readyFlash()
	animator.setGlobalTag("bladeDirectives", self.flashDirectives)
	self.flashTimer = self.flashTime
end

function MeleeCombo:computeDamageAndCooldowns()
	local attackTimes = {}
	for i = 1, self.comboSteps do
        local attackTime = self.stances["windup"..i].duration + self.stances["fire"..i].duration
        if self.stances["preslash"..i] then
            attackTime = attackTime + self.stances["preslash"..i].duration
        end
        table.insert(attackTimes, attackTime)
	end

	self.cooldowns = {}
	local totalAttackTime = 0
	local totalDamageFactor = 0
	for i, attackTime in ipairs(attackTimes) do
        self.stepDamageConfig[i] = util.mergeTable(copy(self.damageConfig), self.stepDamageConfig[i])
        self.stepDamageConfig[i].timeoutGroup = "primary"..i

        local damageFactor = self.stepDamageConfig[i].baseDamageFactor
        self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

        totalAttackTime = totalAttackTime + attackTime
        totalDamageFactor = totalDamageFactor + damageFactor

        local targetTime = totalDamageFactor * self.fireTime
        local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
        table.insert(self.cooldowns, (targetTime - totalAttackTime) * speedFactor)
	end
end



function MeleeCombo:uninit()
	status.clearPersistentEffects("longswordbonus")
	status.clearPersistentEffects("macebonus")
    if self.helper then
        self.helper:clearPersistent()
    end
	self.weapon:setDamage()
end
