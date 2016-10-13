function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("bubbles", mcontroller.boundBox())
  animator.setParticleEmitterActive("bubbles", true)
  self.mouthPosition = status.statusProperty("mouthPosition") or {0,0}
  self.mouthBounds = {self.mouthPosition[1], self.mouthPosition[2], self.mouthPosition[1], self.mouthPosition[2]}
  self.boostAmount = config.getParameter("boostAmount", 0)
  self.riseAmount = config.getParameter("riseAmount", 0)
end

function update(dt)
  
  mcontroller.controlParameters(self.liquidMovementParameter)
  local position = mcontroller.position()
  local worldMouthPosition = {
    self.mouthPosition[1] + position[1],
    self.mouthPosition[2] + position[2]
  }

  local liquidAtMouth = world.liquidAt(worldMouthPosition)
  if liquidAtMouth and (liquidAtMouth[1] == 1 or liquidAtMouth[1] == 2) then 
     mcontroller.controlModifiers({
      speedModifier = self.boostAmount,
      liquidJumpModifier = self.riseAmount,
      liquidForce = 150,
      liquidImpedance = 0.1
    })
  animator.setParticleEmitterActive("bubbles", mcontroller.running())
  else
  
  animator.setParticleEmitterActive("bubbles", false)
  end
end

function uninit()
 -- status.removeEphemeralEffect("liquidimmunity")
end