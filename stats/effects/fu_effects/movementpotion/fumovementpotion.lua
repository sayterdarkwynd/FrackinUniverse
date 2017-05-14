function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("dust", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
  self.featherfall = config.getParameter("featherfall") or 0
  
 if self.featherfall == 1 then
	effect.addStatModifierGroup({{stat = "fallDamageMultiplier", amount = -1.0}})
 end
 
end

function update(dt)
  animator.setParticleEmitterActive("dust", mcontroller.onGround() and mcontroller.running())
  mcontroller.controlModifiers({
          speedModifier = config.getParameter("runmodifiervalue", 30),
	  airJumpModifier = config.getParameter("jumpmodifiervalue", 30)
    })
end

function uninit()
  
end