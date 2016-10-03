function init()
  animator.setParticleEmitterOffsetRegion("sanddrips", mcontroller.boundBox())
  animator.setParticleEmitterActive("sanddrips", true)
  effect.setParentDirectives("fade=BDAE65=0.1")

  local slows = status.statusProperty("slows", {})
  slows["sandslowdown"] = 0.9
  status.setStatusProperty("slows", slows)
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.1,
      runModifier = 0.1,
      jumpModifier = 0.14
    })
  mcontroller.controlParameters({
	   liquidFriction = 75.0
    })
  local waterFactor = mcontroller.liquidPercentage();		
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["sandslowdown"] = nil
  status.setStatusProperty("slows", slows)
end