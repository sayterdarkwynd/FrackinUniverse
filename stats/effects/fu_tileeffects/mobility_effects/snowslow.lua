function init()
  local slows = status.statusProperty("slows", {})
  slows["snowslow"] = 0.53
  status.setStatusProperty("slows", slows)
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)    
end

function update(dt)
  if status.stat("iceResistance") < 70.0 then
	  mcontroller.controlModifiers({
		groundMovementModifier = 0.75,
		speedModifier = 0.75,
		airJumpModifier = 0.8
	    })
  end
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["snowslow"] = nil
  status.setStatusProperty("slows", slows)
end





