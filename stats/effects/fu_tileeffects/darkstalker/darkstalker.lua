function init()
  self.maxHealth = status.stat("maxHealth")
  if status.isResource("energy") then
    self.maxEnergy = status.stat("maxEnergy")
  else
    self.maxEnergy = false
  end
  if status.isResource("food") then
      self.food = status.resource("food")
  else
      self.food = false
  end
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
if world.entityType(entity.id()) ~= "player" then
  effect.expire()
end
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  animator.playSound("burn")
  local lightLevel = getLight()
	  if lightLevel < 40 and world.entityType(entity.id()) == "player" then
	    animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	    animator.setParticleEmitterActive("smoke", true)
	  else
	    animator.setParticleEmitterActive("smoke", false)
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
if world.entityType(entity.id()) ~= "player" then
  effect.expire()
end
    self.tickTimer = self.tickTimer - dt
    local lightLevel = getLight()

    local damageRatio = self.maxHealth / self.maxDps
    self.dps = (damageRatio * self.maxDps) /2

    self.dpsMod = 1 / lightLevel

    if lightLevel < 1 then
      self.dpsMod = 1.1
    end
  if lightLevel > 70 then
    animator.setParticleEmitterActive("smoke", false)
  end
  
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    if lightLevel <=70 or (world.timeOfDay() > 0.5 or world.underground(mcontroller.position())) then
      if world.entityType(entity.id()) == "player" then
 	    animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	    animator.setParticleEmitterActive("smoke", true)  
      end
      status.modifyResource("health", (-self.dps * (self.dpsMod * 0.095) ) * dt)
      if self.maxEnergy then
        status.modifyResource("energy", (-self.dps * (self.dpsMod * 1.8) ) * dt)
      end
      if self.food then
        status.modifyResource("food", (-self.dps * (self.dpsMod * 0.009 ) ) * dt)
      end
    end
  end
end


function uninit()

end
