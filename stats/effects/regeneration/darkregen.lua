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

function update(dt)
  local lightLevel = getLight()
		if lightLevel <= 1 then
    self.healingRate = 1.01 / effect.configParameter("healTime", 180)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 2 then
    self.healingRate = 1.008 / effect.configParameter("healTime", 200)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 5 then
    self.healingRate = 1.007 / effect.configParameter("healTime", 220)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 7 then
    self.healingRate = 1.006 / effect.configParameter("healTime", 240)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 12 then
    self.healingRate = 1.005 / effect.configParameter("healTime", 280)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 15 then
    self.healingRate = 1.004 / effect.configParameter("healTime", 320)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 18 then
    self.healingRate = 1.003 / effect.configParameter("healTime", 350)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 22 then
    self.healingRate = 1.002 / effect.configParameter("healTime", 380)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		elseif lightLevel <= 25 then
    self.healingRate = 1.001 / effect.configParameter("healTime", 420)
    status.modifyResourcePercentage("health", self.healingRate * dt)
		end  

--		if world.time() <= 0.05 then
--    self.healingRate = 1.01 / effect.configParameter("healTime", 60)
--    status.modifyResourcePercentage("health", self.healingRate * dt)
--		elseif world.time() <= 0.1 then
--    self.healingRate = 1.008 / effect.configParameter("healTime", 60)
--    status.modifyResourcePercentage("health", self.healingRate * dt)
--		elseif world.time() <= 0.2 then
--    self.healingRate = 1.007 / effect.configParameter("healTime", 60)
--    status.modifyResourcePercentage("health", self.healingRate * dt)
--		elseif world.time() <= 0.3 then
--    self.healingRate = 1.006 / effect.configParameter("healTime", 60)
--    status.modifyResourcePercentage("health", self.healingRate * dt)
--		elseif world.time() <= 0.4 then
--    self.healingRate = 1.005 / effect.configParameter("healTime", 60)
--    status.modifyResourcePercentage("health", self.healingRate * dt)
--		elseif world.time() <= 0.5 then
--    self.healingRate = 1.004 / effect.configParameter("healTime", 60)
--    status.modifyResourcePercentage("health", self.healingRate * dt)
--		end  
		
end

function uninit()

end