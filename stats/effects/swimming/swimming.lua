function init()
  -- params
  self.applyToTypes = config.getParameter("applyToTypes") or {"player", "npc"}   --what gets the effect?
  self.mouthPosition = status.statusProperty("mouthPosition") or {0,0}  --mouth position
  self.mouthBounds = {self.mouthPosition[1], self.mouthPosition[2], self.mouthPosition[1], self.mouthPosition[2]}
  self.setWet = false -- doesnt start wet
  
  animator.setParticleEmitterOffsetRegion("bubbles", self.mouthBounds)
end

function applyBonusSpeed() --apply Speed Booost
  if status.statPositive("boostAmount") then --this value gets applied in update to the player speedModifier when in water, to calc the total speed + boost
    self.finalValue = 5.735 * (status.stat("boostAmount",1) or 1)   --this does not get passed fine
   -- sb.logInfo("the current swim speed is "..self.finalValue)    
  else
    effect.addStatModifierGroup({{stat = "boostAmount", effectiveMultiplier = 1}}) -- add the swim boost stat if it isn't present so we never multiply by 0
    self.finalValue = 5.735   -- this gets passed fine.
  end
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
  
  if liquidAtMouth and (liquidAtMouth[1] == 1 or liquidAtMouth[1] == 2) then  --activate bubble particles if at mouth level with water
    animator.setParticleEmitterActive("bubbles", true)
    self.setWet = true
  else
    animator.setParticleEmitterActive("bubbles", false)
  end
	  
  if not (allowedType()) then  -- if not the allowed type of entity (a monster that isnt a fish), different effects play
    setMonsterAbilities()	    
  else
    if mcontroller.liquidPercentage() >= 0.62 then  --approximately shoulder height
	effect.modifyDuration(script.updateDt())
	mcontroller.controlModifiers( 
	  { speedModifier = self.finalValue }   -- we have to increase player speed or they wont move fast enough. add the boost value to it. 
	) 
	mcontroller.controlParameters(
	    {
		gravityMultiplier = 0,
		liquidImpedance = 0,
		liquidForce = 100 * self.finalValue  -- get more swim force the better your boost is?
	    }
	)



    else
	effect.expire() -- we could do effect.expire here, but its probably pointless
    end    
  end  
end

function onExpire()
  if self.setWet then
    status.addEphemeralEffect("wet")
  end
end

function setMonsterAbilities()
	if (entity.id("atropusfish")) or (entity.id("veilendrex")) or (entity.id("dolphin1")) then
	    mcontroller.controlModifiers( 
	      {speedModifier = 5.735}    -- slower than players in water
	    )   
	    mcontroller.controlParameters({  --sets monster movement to be floaty but otherwise identical to player on land
		gravityMultiplier = 1,
		liquidImpedance = 0.5,
		liquidForce = 80.0
	    })	
	elseif entity.id("atropuseye") then
	    mcontroller.controlModifiers( 
	      {speedModifier = 2.735}    -- slower than players in water
	    )   
	    mcontroller.controlParameters({  --sets monster movement to be floaty but otherwise identical to player on land
		gravityMultiplier = 0,
		liquidImpedance = 0.5,
		liquidForce = 30.0
	    })		    
	elseif entity.id("deathjelly") then
	    mcontroller.controlModifiers( 
	      {speedModifier = 2.735}    -- slower than players in water
	    )   
	    mcontroller.controlParameters({  --sets monster movement to be floaty but otherwise identical to player on land
		gravityMultiplier = 0,
		liquidImpedance = 0.5,
		liquidForce = 80.0
	    })	
	else
	    mcontroller.controlModifiers( 
	      {speedModifier = 2.735}    -- slower than players in water
	    )   
	    mcontroller.controlParameters({  --sets monster movement to be floaty but otherwise identical to player on land
		gravityMultiplier = 0.6,
		liquidImpedance = 0.5,
		liquidForce = 80.0
	    })
	end
end
