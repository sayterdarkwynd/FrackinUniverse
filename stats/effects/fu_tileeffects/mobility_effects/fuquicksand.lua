function init()
  animator.setParticleEmitterOffsetRegion("sanddrips", mcontroller.boundBox())
  animator.setParticleEmitterActive("sanddrips", true)
  animator.setParticleEmitterActive("statustext", true)  
  
  effect.setParentDirectives("fade=BDAE65=0.1")
  local slows = status.statusProperty("slows", {})
  slows["sandslowdown"] = 0.9
  status.setStatusProperty("slows", slows)
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = config.getParameter("moveMod",1),
      runModifier = config.getParameter("speedMod",1),
      jumpModifier = config.getParameter("jumpMod",1)
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