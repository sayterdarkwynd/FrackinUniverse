require("/scripts/FRHelper.lua")
require "/scripts/status.lua" --for damage listener

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

	self.newValue = 0

	end

-- **************************************************
-- FU EFFECTS

    primaryItem = world.entityHandItem(entity.id(), "primary")  --check what they have in hand
    altItem = world.entityHandItem(entity.id(), "alt")
    self.rapierTimerBonus = 0
    self.effectTimer = 0

    self.hitsListener = damageListener("inflictedHits", checkDamage)  --listen for damage
    self.damageListener = damageListener("inflictedDamage", checkDamage)  --listen for damage
    self.killListener = damageListener("Kill", checkDamage)  --listen for kills
    --self.hitsListener = damageListener("damageTaken", checkDamage)  --listen for kills
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

function checkDamage(notifications)
  for _,notification in pairs(notifications) do

  	-- defense
  	--if notification.targetEntityId then
  	--	if notification.hitType == "ShieldHit" or notification.hitType == "Knockback" then
    --			sb.logInfo("i blocked with a shield")
  	--	end
  	--	if notification.damageType == "Damage" then
  	--		sb.logInfo("i was hit")
  	--		--reset special counters when hit
	--		self.rapierTimerBonus = 0	
	--		self.inflictedHitCounter = 0  
  	--	end
  	--end
    --check for individual combo hits
    if notification.sourceEntityId == entity.id() or notification.targetEntityId == entity.id() then
	    if not status.resourcePositive("health") then --count total kills
	    	notification.hitType = "Kill"
	    end  
	    local hitType = notification.hitType
	    --sb.logInfo(hitType)

        --kill computation
	    if notification.hitType == "Kill" or notification.hitType == "kill" and world.entityType(notification.targetEntityId) == ("monster" or "npc") and world.entityCanDamage(notification.targetEntityId, entity.id()) then
	    	--each consequtive kill in rapid succession increases damage for weapons in this grouping. Per kill. Resets automatically very soon after to prevent abuse.
	        if (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem, "longsword")) or (primaryItem and root.itemHasTag(primaryItem, "dagger")) or (altItem and root.itemHasTag(altItem, "dagger")) then 
	        	if not self.inflictedHitCounter then self.inflictedHitCounter = 0 end
	        	self.totalKillsValue = 1 + self.inflictedHitCounter/50
		 	    status.setPersistentEffects("listenerBonus", {
		 	    	{stat = "powerMultiplier", effectiveMultiplier = self.totalKillsValue}	    	
		 	    })       	
	        end	
	        -- broadswords increase defense on consecutive kills
	        if (primaryItem and root.itemHasTag(primaryItem, "broadsword")) or (altItem and root.itemHasTag(altItem, "broadsword"))  then 
	        	if not self.inflictedHitCounter then self.inflictedHitCounter = 0 end
	        	self.totalKillsValue = 1 + self.inflictedHitCounter/20
	        	if self.totalKillsValue > 1.35 then
	        		self.totalKillsValue = 1.35
	        	end
		 	    status.setPersistentEffects("listenerBonus", {
		 	    	{stat = "protection", effectiveMultiplier = self.totalKillsValue}	    	
		 	    })         	
	        end		        
	    end  

	    --hit computation 
	    if notification.hitType == "Hit" and world.entityType(notification.targetEntityId) == ("monster" or "npc") and world.entityCanDamage(notification.targetEntityId, entity.id()) then
       		--check hit types and calculate any that apply
	        if not self.inflictedHitCounter then self.inflictedHitCounter = 0 end
	        self.inflictedHitCounter = self.inflictedHitCounter + 1
	        if self.inflictedHitCounter > 0 then
		        if (primaryItem and root.itemHasTag(primaryItem, "katana")) or (altItem and root.itemHasTag(altItem, "katana")) then 
		        	--each hit with a combo using a katana increases its knockback resistance
			 	    status.setPersistentEffects("listenerBonus", {
			 	    	{stat = "grit", effectiveMultiplier = 1 + self.inflictedHitCounter/20}	    	
			 	    })          	
		        end
		        if (primaryItem and root.itemHasTag(primaryItem, "shortsword")) or (altItem and root.itemHasTag(altItem, "shortsword")) then 
		        	--each hit with a combo using a shortsword increases its crit damage
			 	    status.setPersistentEffects("listenerBonus", {
			 	    	{stat = "critDamage", amount = ((self.inflictedHitCounter/100) * 5)}	    	
			 	    })          	
		        end        
		        if (primaryItem and root.itemHasTag(primaryItem, "quarterstaff")) or (altItem and root.itemHasTag(altItem, "quarterstaff")) then 
		        	--each hit with a combo using a quarterstaff increases its defense output
		        	self.finalBonus = self.inflictedHitCounter / 5

		        	if self.finalBonus < 1.5 then
				 	    status.setPersistentEffects("listenerBonus", {
				 	    	{stat = "protection", effectiveMultiplier = 1 + self.finalBonus}	    	
				 	    })  
				 	else 
				 	    status.setPersistentEffects("listenerBonus", {
				 	    	{stat = "protection", effectiveMultiplier = 1.5}	--cap the bonus so they cant spin it forever    	
				 	    }) 		 		
			 	    end       	
		        end        
		        if (primaryItem and root.itemHasTag(primaryItem, "mace")) or (altItem and root.itemHasTag(altItem, "mace")) then 
		        	--each hit with a combo using a mace increases its stun chance
			 	    status.setPersistentEffects("listenerBonus", {
			 	    	{stat = "stunChance", amount = self.inflictedHitCounter*2}	    	
			 	    })          	
		        end   
	    	end
	    end 

      return
    end
  end
end

-- Ticks on every update regardless if this is the active ability
function MeleeCombo:update(dt, fireMode, shiftHeld)
    
	WeaponAbility.update(self, dt, fireMode, shiftHeld)
    
	setupHelper(self, "meleecombo-fire")
    self.hitsListener:update()
    self.damageListener:update()
    self.killListener:update()
    --self.hitsListener:update()

	if not attackSpeedUp then
        attackSpeedUp = 0 
    else
    	--attackSpeedUp = attackSpeedUp + status.stat("attackSpeedUp")
    	attackSpeedUp = status.stat("attackSpeedUp")
	end

     --rapiers are fast and furious
    if (primaryItem and root.itemHasTag(primaryItem, "rapier")) or (altItem and root.itemHasTag(altItem, "rapier")) then 
      if self.rapierTimerBonus > 5 then
      	self.rapierTimerBonus = 5 
      	
      else
      	self.rapierTimerBonus = self.rapierTimerBonus + 0.05
      end

	  if self.comboStep > 1 then
	  	status.clearPersistentEffects("multiplierbonus")
	  	status.clearPersistentEffects("daggerbonus")  
	  end	
      if not (altItem) then 
 	    status.setPersistentEffects("rapierbonus", {
 	    	{stat = "critChance", amount = self.rapierTimerBonus},
	        {stat = "dodgetechBonus", amount = 0.35},
	        {stat = "dashtechBonus", amount = 0.35} 	    	
 	    })     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "rapier")) and (altItem and root.itemHasTag(altItem, "dagger")) or 
    	   (altItem and root.itemHasTag(altItem, "rapier")) and (primaryItem and root.itemHasTag(primaryItem, "dagger")) then
    	    status.setPersistentEffects("rapierbonus", {
		        {stat = "dodgetechBonus", amount = 0.25},
		        {stat = "protection", effectiveMultiplier = 1.12},
		        {stat = "dashtechBonus", amount = 0.25}
	      	})  
    	end      	   	    	
      end		
	end

    if (primaryItem and root.itemHasTag(primaryItem, "shortspear")) or (altItem and root.itemHasTag(altItem, "shortspear")) then 
      if not (altItem) then 
 	    status.setPersistentEffects("shortspearbonus", {
 	    	{stat = "critDamage", amount = 0.3}
 	    })     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("shortspearbonus", {
		    	{stat = "shieldBash", amount = 10},
		    	{stat = "shieldBashPush", amount = 2},
		    	{stat = "shieldStaminaRegen", effectiveMultiplier = 1.2},
		        {stat = "defensetechBonus", amount = 0.50}
	        })     		
    	end  
    	if (primaryItem and root.itemHasTag(primaryItem, "shortspear")) and (altItem and root.itemHasTag(altItem, "shortspear")) then
    	    status.setPersistentEffects("shortspearbonus", {
		    	{stat = "protection", effectiveMultiplier = 0.80},
		    	{stat = "critChance", effectiveMultiplier = 0.5}
	      	})  
    	end      	   	    	
      end		
	end

    if (primaryItem and root.itemHasTag(primaryItem, "dagger")) or (altItem and root.itemHasTag(altItem, "dagger")) then 
 	    status.setPersistentEffects("dodgebonus", {
	        {stat = "dodgetechBonus", amount = 0.25}	    	
 	    })         
	    if self.comboStep > 1 then 
	    	self.valueModifier = 1 + (1 / (self.comboStep * 2))
	        if (primaryItem and root.itemHasTag(primaryItem, "dagger")) and (altItem and root.itemHasTag(altItem, "melee")) then
	        	if self.valueModifier > 1.125 then self.valueModifier = 1.125 end
		 	    status.setPersistentEffects("daggerbonus"..activeItem.hand(), {
		 	    	{stat = "protection", effectiveMultiplier = self.valueModifier},
		 	    	{stat = "critChance", amount = self.comboStep}
		 	    })	
	        else
	        	if self.valueModifier > 1.25 then self.valueModifier = 1.25 end
		 	    status.setPersistentEffects("daggerbonus", {
		 	    	{stat = "protection", effectiveMultiplier = self.valueModifier},
		 	    	{stat = "critChance", amount = self.comboStep}
		 	    })	
	        end
	 	elseif self.comboStep == 1 or self.comboStep == 0 or not self.comboStep then
	 	    status.setPersistentEffects("daggerbonus"..activeItem.hand(), {
	 	    	{stat = "critChance", amount = self.comboStep}
	 	    })		 		 	          	
	    end      
		if (primaryItem and root.itemHasTag(primaryItem, "dagger")) and (altItem and root.itemHasTag(altItem, "melee")) or 
		   (altItem and root.itemHasTag(altItem, "dagger")) and (primaryItem and root.itemHasTag(primaryItem, "melee")) then
	      	status.addEphemeralEffects{{effect = "runboost5", duration = 0.02}} 	      	
		end      	   	    	
	end

    if (primaryItem and root.itemHasTag(primaryItem, "scythe")) or (altItem and root.itemHasTag(altItem, "scythe")) then
 	    status.setPersistentEffects("scythebonus", {
 	    	{stat = "critDamage", amount = 0.05+(self.comboStep*0.1)},
 	    	{stat = "critChance", amount = 1+(self.comboStep)}
 	    })	
	  if self.comboStep then
 	    status.setPersistentEffects("scythebonus", {
 	    	{stat = "critDamage", amount = 0.05+(self.comboStep*0.1)},
 	    	{stat = "critChance", amount = 1+(self.comboStep)}
 	    })
	  else
		status.setPersistentEffects("scythebonus", {
 	    	{stat = "critDamage", amount = 0.05},
 	    	{stat = "critChance", amount = 1}
 	    })
	  end

	end

    if (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem, "longsword")) then 
      if self.comboStep >=3 then
 	    status.setPersistentEffects("multiplierbonus", {
 	    	{stat = "critDamage", amount = 0.15}
 	    })
 	  else
 	    status.setPersistentEffects("multiplierbonus", {
 	    	{stat = "critDamage", amount = 0}
 	    }) 	         	
      end
      if not (altItem) then 
 	    status.setPersistentEffects("longswordbonus", {
 	    	{stat = "attackSpeedUp", amount = 0.7}
 	    })     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("longswordbonus", {
		    	{stat = "shieldBash", amount = 4},
		    	{stat = "shieldBashPush", amount = 1},
		        {stat = "defensetechBonus", amount = 0.25},
		        {stat = "healtechBonus", amount = 0.15}
	        })     		
    	end  

    	if (primaryItem and root.itemHasTag(primaryItem, "longsword")) and (altItem and root.itemHasTag(altItem, "weapon")) or 
    	   (altItem and root.itemHasTag(altItem, "longsword")) and (primaryItem and root.itemHasTag(primaryItem, "weapon")) then
    	    status.setPersistentEffects("longswordbonus", {
		    	{stat = "protection", effectiveMultiplier = 0.80}
	      	}) 
	      	status.addEphemeralEffects{{effect = "runboost5", duration = 0.02}}  
    	end      	   	    	
      end		
	end

    if (primaryItem and root.itemHasTag(primaryItem, "mace")) or (altItem and root.itemHasTag(altItem, "mace")) then 
      if not (altItem) then 
 	    status.setPersistentEffects("macebonus", {
 	    	{stat = "stunChance", amount = 2}
 	    })     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "shield")) or (altItem and root.itemHasTag(altItem, "shield")) then
 	        status.setPersistentEffects("macebonus", {
		    	{stat = "shieldBash", amount = 3},
		    	{stat = "shieldBashPush", amount = 1},
		    	{stat = "protection", effectiveMultiplier = 1.10}
	        })     		
    	end  
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

    if (primaryItem and root.itemHasTag(primaryItem, "katana")) or (altItem and root.itemHasTag(altItem, "katana")) then 
      if self.comboStep >=1 then 
 	  	mcontroller.controlModifiers({speedModifier = 1 + (self.comboStep / 10)})       	
      end 
      if not (altItem) then 
 	    status.setPersistentEffects("katanabonus", { {stat = "defensetechBonus", amount = 0.15} })     		
      else
    	if (primaryItem and root.itemHasTag(primaryItem, "longsword")) or (altItem and root.itemHasTag(altItem, "longsword")) or  
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
    	if (primaryItem and root.itemHasTag(primaryItem, "shortsword")) or (altItem and root.itemHasTag(altItem, "shortsword")) or  
    	   (primaryItem and root.itemHasTag(primaryItem, "dagger")) or (altItem and root.itemHasTag(altItem, "dagger")) or
    	   (primaryItem and root.itemHasTag(primaryItem, "rapier")) or (altItem and root.itemHasTag(altItem, "rapier")) then
    	    status.setPersistentEffects("katanabonus", {
		        {stat = "maxEnergy", effectiveMultiplier =  1.15},
		        {stat = "critDamage", amount = 0.2},
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
	
	if (primaryItem and root.itemHasTag(primaryItem, "melee")) and (altItem and root.itemHasTag(altItem, "melee")) then 
		self.energyTotal = (status.stat("maxEnergy") * 0.025)											
	else
		self.energyTotal = (status.stat("maxEnergy") * 0.01)
	end

		if status.resource("energy") <= 1 then 
			status.modifyResource("energy",1) 
			cancelEffects()
			self.comboStep = 1	

		end 
		if status.resource("energy") == 1 then 
			cancelEffects() 
		end
	if status.consumeResource("energy",math.min((status.resource("energy")-1), self.energyTotal)) then 
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
	if status.resource("energy") < 1 then
		self.cooldownTimer = self.cooldownTimer + 0.1
	end	
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

-- ***********************************************************************************************************
-- FR SPECIALS	Functions for projectile spawning
-- ***********************************************************************************************************
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
	-- ***********************************************************************************************************
	-- END FR SPECIALS
	-- ***********************************************************************************************************


-- State: fire
function MeleeCombo:fire()
	local stance = self.stances["fire"..self.comboStep]

	self.weapon:setStance(stance)
	self.weapon:updateAim()

	if self.helper then
        self.helper:runScripts("meleecombo-fire", self)
    end

    self.rapierTimerBonus = 0
	local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
	animator.setAnimationState("swoosh", animStateKey)
	if animator.hasSound(animStateKey) then
		animator.playSound(animStateKey)
	elseif animator.hasSound("fire") then
		animator.playSound("fire")
	end

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
	cancelEffects()
    if self.helper then
        self.helper:clearPersistent()
    end
    status.clearPersistentEffects("floranFoodPowerBonus")
	status.clearPersistentEffects("slashbonusdmg")
	self.weapon:setDamage()
end

function cancelEffects()
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
	self.rapierTimerBonus = 0	
	self.inflictedHitCounter = 0
end