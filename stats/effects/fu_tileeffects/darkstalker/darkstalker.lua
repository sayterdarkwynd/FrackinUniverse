

function init()

  self.maxHealth = status.stat("maxHealth")
  self.maxEnergy = status.stat("maxEnergy")
  self.food = status.resource("food") 
  self.maxDps = config.getParameter("maxDps")
  self.dps = 0
  self.tickDamagePercentage = 0.005
  self.tickTime = 0.1
  self.tickTimer = self.tickTime
  activateVisualEffects()
  self.timers = {} 
  
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end


function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  
  local lightLevel = getLight()
  if lightLevel <= 25 then
    animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
    animator.setParticleEmitterActive("smoke", true)  
  end
end
  
function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end


function nighttimeCheck()
	return world.timeOfDay() > 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position()) 
end

function update(dt)
  nighttime = nighttimeCheck()
  underground = undergroundCheck()
  
  local lightLevel = getLight()
  self.tickTimer = self.tickTimer + dt
  if self.tickTimer >= 0 then
  self.tickTimer = self.tickTime
  
  
    local damageRatio = self.maxHealth / self.maxDps
    self.dps = (damageRatio * self.maxDps) /2
    
    
	  if nighttime then
		if lightLevel <= 25 then
		    status.modifyResource("health", (-self.dps /50) * dt)
		    status.modifyResource("energy", (-self.dps * 3) * dt)
		    status.modifyResource("food", (-self.dps /75) * dt)
		elseif lightLevel <= 10 then
		    status.modifyResource("health", (-self.dps /50) * dt)
		    status.modifyResource("energy", (-self.dps * 3) * dt)
		    status.modifyResource("food", (-self.dps /75) * dt)		
		elseif lightLevel <= 1 then
		    status.modifyResource("health", (-self.dps /50 ) * dt)
		    status.modifyResource("energy", (-self.dps * 3) * dt)
		    status.modifyResource("food", (-self.dps /75) * dt)		
		end  
	  end

	  if underground then
		if lightLevel <= 25 then
		    status.modifyResource("health", (-self.dps /40) * dt)
		    status.modifyResource("energy", (-self.dps * 4) * dt)
		    status.modifyResource("food", (-self.dps /65) * dt)
		elseif lightLevel <= 10 then
		    status.modifyResource("health", (self.dps /40) * dt)
		    status.modifyResource("energy", (self.dps * 4) * dt)
		    status.modifyResource("food", (self.dps /65) * dt)		
		elseif lightLevel <= 1 then
		    status.modifyResource("health", (self.dps /40 ) * dt)
		    status.modifyResource("energy", (self.dps * 4) * dt)
		    status.modifyResource("food", (self.dps /65) * dt)	
		end  
	  end  
  end

  

		
end

function uninit()

end