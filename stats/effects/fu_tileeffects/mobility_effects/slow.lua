function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  
  --check types
  if config.getParameter("isHoney",0)==1 then
    activateVisualEffectsHoney()
  end
  if config.getParameter("isTar",0)==1 then
    activateVisualEffectsTar()
  end 
  
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = config.getParameter("moveMod",1),
      speedModifier = config.getParameter("speedMod",1),
      airJumpModifier = config.getParameter("jumpMod",1)     
    })
end

function activateVisualEffectsHoney()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=edcd5c=0.2")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function activateVisualEffectsTar()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=300030=0.8")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function uninit()

end