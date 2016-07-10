function init()
  animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
  animator.setParticleEmitterActive("snow", true)
  effect.setParentDirectives("fade=DDDDFF=0.5")

  local stuns = status.statusProperty("stuns", {})
  stuns["freeze"] = true
  status.setStatusProperty("stuns", stuns)
end

function update(dt)
  mcontroller.controlModifiers({
      movementSuppressed = true
    })
end

function uninit()
  local stuns = status.statusProperty("stuns", {})
  stuns["freeze"] = nil
  status.setStatusProperty("stuns", stuns)
end