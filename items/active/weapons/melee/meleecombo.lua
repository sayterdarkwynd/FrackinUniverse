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
		self.foodValue = 60  --never at max power if Food is disabled. Max effects (70 food) are for Survival and Hardcore only.
	end
	attackSpeedUp = 0 -- base attackSpeed. This acts as the timer between *combos* , not individual attacks

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
    else
    	--attackSpeedUp = attackSpeedUp + status.stat("attackSpeedUp")
    	attackSpeedUp = status.stat("attackSpeedUp")
	end

     --rapiers are fast and furious
    if (primaryItem and root.itemHasTag(primaryItem, "rapier")) or (altItem and root.itemHasTag(altItem, "rapier")) then --shortspear check (is worn)
      --rapier check (1 handed) : +15% Crit Damage, +35% Dash and Dodge Tech Efficiency
      if not (altItem) then 
 	    status.setPersistentEffects("rapierbonus", {
 	    	{stat = "critDamage", amount = 0.15},
	        --tech bonuses
	        {stat = "dodgetechBonus", amount = 0.35},
	        {stat = "dashtechBonus", amount = 0.35} 	    	
 	    })     		
      else
    	-- rapier check (rapier + dagger) : +5% Move Speed, +15% Dash and Dodge Tech Efficiency, +15% Protection
    	if (primaryItem and root.itemHasTag(primaryItem, "rapier")) and (altItem and root.itemHasTag(altItem, "dagger")) or 
    	   (altItem and root.itemHasTag(altItem, "rapier")) and (primaryItem and root.itemHasTag(primaryItem, "dagger")) then
    	    status.setPersistentEffects("rapierbonus", {
		    	{stat = "protection", effectiveMultiplier = 1.15},
		        --tech bonuses
		        {stat = "dodgetechBonus", amount = 0.15},
		        {stat = "dashtechBonus", amount = 0.15}
	      	})  
    	end      	   	    	
      end		
	end

    --shortspears are THE weapon for shield users
    if (primaryItem and root.itemHasTag(primaryItem, "shortspear")) or (altItem and root.itemHasTag(altItem, "shortspear")) then --shortspear check (is worn)
      --shortspear check (1 handed) : +30% Crit Damage
      if not (altItem) then 
 	    status.setPersistentEffects("shortspearbonus", {
 	    	{stat = "critDamage", amount = 0.3}
 	    })     		
      else
      	--shortspear check (w / shield) : +10 Shield Bash, +50% Efficiency to Defensive Techs, +5% Damage, 20% Shield Regen
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("shortspearbonus", {
		    	{stat = "shieldBash", amount = 10},
		    	{stat = "shieldBashPush", amount = 2},
		    	{stat = "shieldStaminaRegen", effectiveMultiplier = 1.2},
		    	--tech bonuses
		        {stat = "defensetechBonus", amount = 0.50}
	        })     		
    	end  
    	-- shortspear check (dual shortspear) : -20% Protection, -50% Crit Chance
    	if (primaryItem and root.itemHasTag(primaryItem, "shortspear")) and (altItem and root.itemHasTag(altItem, "shortspear")) then
    	    status.setPersistentEffects("shortspearbonus", {
		    	{stat = "protection", effectiveMultiplier = 0.80},
		    	{stat = "critChance", effectiveMultiplier = 0.5}
	      	})  
    	end      	   	    	
      end		
	end

     --daggers are super close-in, and dangerous
    if (primaryItem and root.itemHasTag(primaryItem, "dagger")) or (altItem and root.itemHasTag(altItem, "dagger")) then --dagger check (is worn)
 	    status.setPersistentEffects("dodgebonus", {
	        {stat = "dodgetechBonus", amount = 0.25}	    	
 	    })        
 	    
	    if self.comboStep > 1 then --daggers increase defense through combos, as well as incrementally increase Crit chance
	      	self.valueModifier = 1 + (1 / self.comboStep)
	 	    status.setPersistentEffects("multiplierbonus", {
	 	    	{stat = "protection", effectiveMultiplier = self.valueModifier},
	 	    	{stat = "critChance", amount = self.comboStep}
	 	    })	
	 	else   
	 	    status.setPersistentEffects("multiplierbonus", {
	 	    	{stat = "protection", effectiveMultiplier = 1},
	 	    	{stat = "critChance", amount = self.comboStep}
	 	    })		 	          	
	    end      
      --daggers check (1 handed) : +5% speed, +10% protection
		if (primaryItem and root.itemHasTag(primaryItem, "dagger")) and (altItem and root.itemHasTag(altItem, "melee")) or 
		   (altItem and root.itemHasTag(altItem, "dagger")) and (primaryItem and root.itemHasTag(primaryItem, "melee")) then
		    status.setPersistentEffects("daggerbonus", {
		    	{stat = "protection", effectiveMultiplier = 1.10},
	      	})  
	      	status.addEphemeralEffects{{effect = "runboost5", duration = 0.02}} 
		end      	   	    	
	
	end

    --scythes are all about crits
    if (primaryItem and root.itemHasTag(primaryItem, "scythe")) or (altItem and root.itemHasTag(altItem, "scythe")) then --longsword check (is worn)
      if self.comboStep == 1 then
 	    status.setPersistentEffects("scythebonus", {
 	    	{stat = "critDamage", amount = 0.15},
 	    	{stat = "critChance", amount = 2}
 	    })
      elseif self.comboStep == 2 then
 	    status.setPersistentEffects("scythebonus", {
 	    	{stat = "critDamage", amount = 0.25},
 	    	{stat = "critChance", amount = 3}
 	    })	            
 	  else
 	    status.setPersistentEffects("scythebonus", {
 	    	{stat = "critDamage", amount = 0.05},
 	    	{stat = "critChance", amount = 1}
 	    }) 	       	
      end
	end

    --longswords are way less effective when dual wielding, and much more effective when using with a shield
    if (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem, "longsword")) then --longsword check (is worn)
      if self.comboStep >=3 then
 	    status.setPersistentEffects("multiplierbonus", {
 	    	{stat = "critDamage", amount = 0.15}
 	    })
 	  else
 	    status.setPersistentEffects("multiplierbonus", {
 	    	{stat = "critDamage", amount = 0}
 	    }) 	         	
      end
      --longsword check (1 handed) : 70% Combo Cooldown
      if not (altItem) then 
 	    status.setPersistentEffects("longswordbonus", {
 	    	{stat = "attackSpeedUp", amount = 0.7}
 	    })     		
      else
      	--longsword check (w / shield) : +4 Shield Bash and +1 Push, +0.5% crit chance increase, +25% Efficiency to Defensive Techs and +15% Efficiency to Heal techs
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("longswordbonus", {
		    	{stat = "shieldBash", amount = 4},
		    	{stat = "shieldBashPush", amount = 1},
		    	--tech bonuses
		        {stat = "defensetechBonus", amount = 0.25},
		        {stat = "healtechBonus", amount = 0.15}
	        })     		
    	end  
    	-- longsword check (dual wielded) : -20% Protection, -50% Crit Chance, +5% movement speed
    	if (primaryItem and root.itemHasTag(primaryItem, "longsword")) and (altItem and root.itemHasTag(altItem, "weapon")) or 
    	   (altItem and root.itemHasTag(altItem, "longsword")) and (primaryItem and root.itemHasTag(primaryItem, "weapon")) then
    	    status.setPersistentEffects("longswordbonus", {
		    	{stat = "protection", effectiveMultiplier = 0.80}
	      	}) 
	      	status.addEphemeralEffects{{effect = "runboost5", duration = 0.02}}  
    	end      	   	    	
      end		
	end

    --maces are way less effective when dual wielding, and much more effective when using with a shield
    if (primaryItem and root.itemHasTag(primaryItem, "mace")) or (altItem and root.itemHasTag(altItem, "mace")) then --mace check (is worn)
      --mace check (1 handed) : +2% Stun Chance 
      if not (altItem) then 
 	    status.setPersistentEffects("macebonus", {
 	    	{stat = "stunChance", amount = 2}
 	    })     		
      else
      	--mace check (w / shield) : +7 Shield Bash and +3 Push, +10% Protection
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("macebonus", {
		    	{stat = "shieldBash", amount = 3},
		    	{stat = "shieldBashPush", amount = 1},
		    	{stat = "protection", effectiveMultiplier = 1.10}
	        })     		
    	end  
    	--mace check (dual wielded) : -15% Crit Chance, -50% Stun Chance, +5% Movement Speed
    	if (primaryItem and root.itemHasTag(primaryItem, "mace")) and (altItem and root.itemHasTag(altItem, "weapon")) or 
    	   (altItem and root.itemHasTag(altItem, "mace")) and (primaryItem and root.itemHasTag(primaryItem, "weapon")) then
    	    status.setPersistentEffects("macebonus", {
		    	{stat = "critChance", effectiveMultiplier = 0.85},
		    	{stat = "stunChance", effectiveMultiplier = 0.50}
	      	})  
	      	status.addEphemeralEffects{{effect = "runboost5", duration = 0.02}} 
    	end      	   	    	
      end		
	end   

    if (primaryItem and root.itemHasTag(primaryItem, "katana")) or (altItem and root.itemHasTag(altItem, "katana")) then --mace check (is worn)
      if self.comboStep >=1 then  --katanas increase movement speed with each combo strike
 	  	mcontroller.controlModifiers({speedModifier = 1 + (self.comboStep / 10)})       	
      end 
      if not (altItem) then --katana check (1 handed)
 	    status.setPersistentEffects("katanabonus", { {stat = "defensetechBonus", amount = 0.15} })     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem, "longsword")) or  --suck with large dual-wields
    	   (primaryItem and root.itemHasTag(primaryItem, "katana")) or (altItem and root.itemHasTag(altItem, "katana")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "axe")) or (altItem and root.itemHasTag(altItem, "axe")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "flail")) or (altItem and root.itemHasTag(altItem, "flail")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "shortspear")) or (altItem and root.itemHasTag(altItem, "shortspear")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "mace")) or (altItem and root.itemHasTag(altItem, "mace")) then
    	    status.setPersistentEffects("katanabonus", {
		        {stat = "powerMultiplier", amount = 0.80},
		        {stat = "protection", effectiveMultiplier = 0.90}
	      	}) 
    	end     	
    	if (primaryItem and root.itemHasTag(primaryItem, "shortsword")) or (altItem and root.itemHasTag(altItem, "shortsword")) or  --increased crit damage and energy
    	   (primaryItem and root.itemHasTag(primaryItem, "dagger")) or (altItem and root.itemHasTag(altItem, "dagger")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "rapier")) or (altItem and root.itemHasTag(altItem, "rapier")) then
    	    status.setPersistentEffects("katanabonus", {
		        {stat = "maxEnergy", effectiveMultiplier =  1.15},
		        {stat = "critDamage", amount = 0.2},
		        --tech bonuses
		        {stat = "dodgetechBonus", amount = 0.25},
		        {stat = "dashtechBonus", amount = 0.25}
	      	})
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

-- *** FU ------------------------------------
-- FU adds an encapsulating check in Windup, for energy. If there is no energy to consume, the combo weapon cannot attack
function MeleeCombo:windup()
	self.energyTotal = (status.stat("maxEnergy") * 0.01)
	if status.overConsumeResource("energy", self.energyTotal) then  
		
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
	else
		return
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
	self.cooldownTimer = math.max(0, self.cooldownTimer * attackSpeedUp)
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
	-- **** FR cooldown adjustment
    	self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep] * ( 1 - attackSpeedUp))
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
	status.clearPersistentEffects("katanabonus")
	status.clearPersistentEffects("rapierbonus")
	status.clearPersistentEffects("shortspearbonus")
	status.clearPersistentEffects("daggerbonus")
	status.clearPersistentEffects("scythesbonus")

	status.clearPersistentEffects("multiplierbonus")
	status.clearPersistentEffects("dodgebonus")
    if self.helper then
        self.helper:clearPersistent()
    end
	self.weapon:setDamage()
end
