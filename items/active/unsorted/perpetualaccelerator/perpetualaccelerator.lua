require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  script.setUpdateDelta(5)
  self.increase = 1
end

function update(dt, fireMode, shiftHeld, moves)
  self.increase = self.increase + 0.005  --constantly increases speed when held
  mcontroller.controlModifiers({
      groundMovementModifier = self.increase,
      speedModifier = self.increase
    })
    animator.setParticleEmitterActive("activatedLight", true)
end

function uninit()
  animator.setParticleEmitterActive("activatedLight", false)
end


