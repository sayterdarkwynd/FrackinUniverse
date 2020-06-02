require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.active=false
  self.available = true
  self.species = world.entitySpecies(entity.id())
  self.firetimer = 0
  self.rechargeDirectives = "?fade=CC22CCFF=0.1"
  self.rechargeDirectivesNil = nil
  self.rechargeEffectTime = 0.1 
  self.rechargeEffectTimer = 0
  self.flashCooldownTimer = 0
  self.halted = 0
  checkFood()
end

function uninit()

end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = world.lightLevel(position)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end

function checkFood()
	if status.isResource("food") then
		self.foodValue = status.resource("food")		
	else
		self.foodValue = 15
	end	
end

function damageConfig()
  totalVal = (self.foodValue /17)
end

function activeFlight()
    damageConfig()
    local damageConfig = { 
      power = totalVal,
    
	  actionOnReap = {
	      {
		action='explosion',
		foregroundRadius=totalVal,
		backgroundRadius=(totalVal/2),
		explosiveDamageAmount= (totalVal/2),
		harvestLevel = 99,
		delaySteps=2
	      }
	    }     
    }
    world.spawnProjectile("minerclaw", mcontroller.position(), entity.id(), aimVector(), false, damageConfig)
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, sb.nrand(0, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function chargeUp()
    if self.halted == 0 then
       self.halted = 1
    end	 
end


    
function update(args)
        local primaryItem = world.entityHandItem(entity.id(), "primary")
        local altItem = world.entityHandItem(entity.id(), "alt")       
        self.firetimer = math.max(0, self.firetimer - args.dt)
        checkFood()
        
	  if self.flashCooldownTimer > 0 then
	    self.flashCooldownTimer = math.max(0, self.flashCooldownTimer - args.dt)  
	    if self.flashCooldownTimer <= 2 then
	      chargeUp()
	    end
	    
	    if self.flashCooldownTimer == 0 then
	      self.rechargeEffectTimer = self.rechargeEffectTime
	      tech.setParentDirectives(self.rechargeDirectives)
	      animator.playSound("refire")
            end
	  end

	  if self.rechargeEffectTimer > 0 then
	    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
	    if self.rechargeEffectTimer == 0 then
	      tech.setParentDirectives()
	    end
	  end
	
	if args.moves["special1"] and self.firetimer == 0 and not (primaryItem and root.itemHasTag(primaryItem, "weapon")) and not (altItem and root.itemHasTag(altItem, "weapon")) then 
		if self.foodValue > 10 then
		    status.addEphemeralEffects{{effect = "foodcostclaw", duration = 0.01}}
		else
		    status.overConsumeResource("energy", 1)
		end	
		self.firetimer = 0.3
		activeFlight()
		self.dashCooldownTimer = 0.3
		self.flashCooldownTimer = 0.3
		self.halted = 0
	end
end
