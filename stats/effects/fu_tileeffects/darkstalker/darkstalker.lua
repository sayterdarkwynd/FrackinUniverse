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
  effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", baseMultiplier = 0.7 }})
end


function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  animator.playSound("burn")
  local lightLevel = getLight()
  if lightLevel <= 40 then
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

 
function update(dt)
    
    self.tickTimer = self.tickTimer - dt
    local lightLevel = getLight()
    
    local damageRatio = self.maxHealth / self.maxDps
    self.dps = (damageRatio * self.maxDps) /2
    
    self.dpsMod = 1 / lightLevel
    
    if lightLevel < 1 then 
      self.dpsMod = 1.1 
    end

  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    if lightLevel <=40 or (world.timeOfDay() > 0.5 or world.underground(mcontroller.position())) then
      status.modifyResource("health", (-self.dps * (self.dpsMod * 0.095) ) * dt)
      status.modifyResource("energy", (-self.dps * (self.dpsMod * 1.8) ) * dt)
      status.modifyResource("food", (-self.dps * (self.dpsMod * 0.009 ) ) * dt)
    end
  end
end


function uninit()

end