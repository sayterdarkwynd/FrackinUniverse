require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.timer = 3
  self.fireOffset = config.getParameter("fireOffset")
  script.setUpdateDelta(10)
end

function update(dt, fireMode, shiftHeld, moves)
      status.addEphemeralEffect("pocketanchorstat", 1)
     mcontroller.controlModifiers({
      speedModifier = self.boostAmount,
      liquidJumpModifier = 0,
      liquidForce = 300,
      liquidImpedance = 0.1
    })      
      --animator.playSound("flashlight2", 1)
      --animator.setParticleEmitterActive("activatedLight", true)      
end

function uninit()
  status.removeEphemeralEffect("pocketanchorstat")  
  --animator.stopAllSounds("flashlight2")
  --animator.setParticleEmitterActive("activatedLight", false)  
end
