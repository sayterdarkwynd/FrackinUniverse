function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("dust", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
  self.featherfall = effect.configParameter("featherfall") or 0
  
 if self.featherfall == 1 then
	effect.addStatModifierGroup({{stat = "fallDamageMultiplier", amount = -1.0}})
 end
 
end

function update(dt)
  animator.setParticleEmitterActive("dust", mcontroller.onGround() and mcontroller.running())
  mcontroller.controlModifiers({
      runModifier = effect.configParameter("runmodifiervalue", 30),
	  jumpModifier = effect.configParameter("jumpmodifiervalue", 30)
    })
end

function uninit()
  
end