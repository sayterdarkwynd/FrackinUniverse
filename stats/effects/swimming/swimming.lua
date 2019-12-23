function init()
  -- params
  self.applyToTypes = config.getParameter("applyToTypes") or {"player", "npc"}   --what gets the effect?
  self.mouthPosition = status.statusProperty("mouthPosition") or {0,0}  --mouth position
  self.mouthBounds = {self.mouthPosition[1], self.mouthPosition[2], self.mouthPosition[1], self.mouthPosition[2]}
  self.setWet = false -- doesnt start wet
  animator.setParticleEmitterOffsetRegion("bubbles", self.mouthBounds)

  --basic water locomotion stats
  self.shoulderHeight = 0.65  						-- roughly shoulder depth
  self.fishHeight = 0.85 						-- almost all of the creature is submerged
  self.baseSpeed = 5.735						-- base liquid speed outside of a controlModifier call
  self.defaultSpeed = { speedModifier = 1 } 				-- the default movement speed
  self.defaultWaterSpeed = { speedModifier = 5.735 } 			-- the basic water speed
  self.basicMonsterSpeed = { speedModifier = 2.65 } 			-- most monsters speed
  self.jellyfishMonsterSpeed = { speedModifier = 0.1 } 			-- jellyfish are slow as molasses
  self.bossMonsterSpeed = { speedModifier = 4.735 } 			-- Veilendrex and Deep Seer speed
  
  self.boostAmount = status.stat("boostAmount")
  self.riseAmount = status.stat("riseAmount")

  applyBonusSpeed()

  self.basicWaterParameters = {  					-- generic values
	gravityMultiplier = 0,
	liquidImpedance = 0,
	liquidForce = 100 * self.finalValue  				-- get more swim force the better your boost is? 
  }   
  
  self.monsterWaterParameters = {  					-- most monsters use these values , simulating slow movement and such
	gravityMultiplier = 0.6,
	liquidImpedance = 0.5,
	liquidForce = 80.0
  }
  
  self.bossWaterParameters = {  					-- Veilendrex and Deep Seer
	gravityMultiplier = 1,
	liquidImpedance = 0.5,
	liquidForce = 80.0
  }  
  
  self.spawnedWaterParameters = {  					-- Atropal Eyes
	gravityMultiplier = 1,
	liquidImpedance = 0.5,
	liquidForce = 30.0
  }
  
  self.jellyfishWaterParameters = {  					-- Jellyfish
	gravityMultiplier = -2,
	liquidImpedance = 0.5,
	liquidForce = 2.0
  } 
  
  self.submergedParameters = {  					-- generic values in water for non-specials
	gravityMultiplier = 1.5,
	liquidImpedance = 0.5,
	liquidForce = 80.0,
	airFriction = 0,
	airForce = 0
  }  
  		
end

function applyBonusSpeed() --apply Speed Booost
  self.boostAmount = status.stat("boostAmount",1)
  if self.boostAmount > 2.5 then
    self.boostAmount = 2.5
  end
  
  self.finalValue = self.baseSpeed * (status.stat("boostAmount",1) or 1)  
  
end

function allowedType() -- check entity type from provided list
  local entityType = entity.entityType()
  for _,applyType in ipairs(self.applyToTypes) do
    if entityType == applyType then
      return true
    end
  end
end

function update(dt)
  -- params
  applyBonusSpeed() -- check if bonus speed is active

  
  local position = mcontroller.position()   
  local worldMouthPosition = {self.mouthPosition[1] + position[1],self.mouthPosition[2] + position[2]}
  local liquidAtMouth = world.liquidAt(worldMouthPosition)
  
  checkLiquidType()
  
  if (status.stat("breathProtection") < 1) then
	  if liquidAtMouth and (liquidAtMouth[1] == 1 or liquidAtMouth[1] == 2 or liquidAtMouth[1] == 6 or liquidAtMouth[1] == 40) then  --activate bubble particles if at mouth level with water
	    animator.setParticleEmitterActive("bubbles", true)
	    self.setWet = true
	  else
	    animator.setParticleEmitterActive("bubbles", false)
	  end  

  end
  
  if not (allowedType()) then  -- if not the allowed type of entity (a monster that isn't a fish)
    setMonsterAbilities()	    
  else
  
    if (mcontroller.liquidPercentage() >= self.shoulderHeight) or ((mcontroller.liquidPercentage() > 0.4) and (status.stat("boostAmount") > 1)) then  --if the player is shoulder depth, or shallow depth+boosted
	mcontroller.controlModifiers({speedModifier = self.finalValue})			
	mcontroller.controlParameters(self.basicWaterParameters)
    elseif (mcontroller.liquidPercentage() < self.shoulderHeight) and (status.stat("boostAmount") < 1) then --are half submerged and not boosted
      mcontroller.controlModifiers({speedModifier = self.basicMonsterSpeed})	
      mcontroller.controlParameters(self.monsterWaterParameters)	
    elseif (mcontroller.liquidPercentage() < 0.25) and (status.stat("boostAmount") < 1) then --are we barely in the water?
      mcontroller.controlParameters(self.submergedParameters)
    else
      effect.expire()
    end    
  end  
end

function checkLiquidType()
  local position = mcontroller.position()   
  local worldMouthPosition = {self.mouthPosition[1] + position[1],self.mouthPosition[2] + position[2]}
  local liquidAtMouth = world.liquidAt(worldMouthPosition)
  
  if liquidAtMouth and (liquidAtMouth[1] == 40) then -- check if the Blood effect for Wet needs to play
    self.isBlood = 1
  end  
end

function onExpire()
  if self.setWet then
    if not self.isBlood then
    	status.addEphemeralEffect("wet")
    else
    	status.addEphemeralEffect("wetblood")
    end
  end
end

function setMonsterAbilities()
	if (status.stat("isWaterCreature")) then
	  if (mcontroller.liquidPercentage() >= self.fishHeight) then
		if (status.stat("isBossCreature"))==1 then
		    mcontroller.controlModifiers(self.bossMonsterSpeed)  
		    mcontroller.controlParameters(self.bossWaterParameters)	
		elseif (status.stat("isSpawnedCreature"))==1 then
		    mcontroller.controlModifiers(self.basicMonsterSpeed)   
		    mcontroller.controlParameters(self.spawnedWaterParameters)		    
		elseif (status.stat("isJellyfishCreature"))==1 then
		    mcontroller.controlModifiers(self.jellyfishMonsterSpeed)   
		    mcontroller.controlParameters(jellyfishWaterParameters)	
		end
	  else
	    if not mcontroller.baseParameters().gravityEnabled then
	      mcontroller.setYVelocity(-5)
	    end	 
	    mcontroller.controlModifiers(self.defaultSpeed)  	    
	    mcontroller.controlParameters(self.submergedParameters)  
	  end

	else
	    mcontroller.controlModifiers(self.basicMonsterSpeed)   
	    mcontroller.controlParameters(self.monsterWaterParameters)
	end
end
