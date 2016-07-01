function init()
  local bounds = mcontroller.boundBox()
  self.healingRate = 1.01 / effect.configParameter("healTime", 420)
  script.setUpdateDelta(10)
end


function activateVisualEffects()
  local lightLevel = getLight()
  if lightLevel <= 25 then
    animator.setParticleEmitterOffsetRegion("blood", mcontroller.boundBox())
    animator.setParticleEmitterActive("blood", true)  
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

 if lightLevel > 95 then
   self.healingRate = 1.01 / effect.configParameter("healTime", 140)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 90 then
   self.healingRate = 1.008 / effect.configParameter("healTime", 180)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 80 then
   self.healingRate = 1.007 / effect.configParameter("healTime", 220)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 70 then
   self.healingRate = 1.006 / effect.configParameter("healTime", 240)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 65 then
   self.healingRate = 1.005 / effect.configParameter("healTime", 270)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 55 then
   self.healingRate = 1.004 / effect.configParameter("healTime", 300)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 45 then
   self.healingRate = 1.003 / effect.configParameter("healTime", 340)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 35 then
   self.healingRate = 1.002 / effect.configParameter("healTime", 380)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
  elseif lightLevel > 25 then
   self.healingRate = 1.001 / effect.configParameter("healTime", 420)
   status.modifyResourcePercentage("energy", self.healingRate * dt)
end 

function uninit()

end