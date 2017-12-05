require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.timer = 3
  self.fireOffset = config.getParameter("fireOffset")
   self.energyCost = 10
  script.setUpdateDelta(5)
end

function update(dt, fireMode, shiftHeld, moves)
  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)
  updateAim()
 
  if fireMode == "primary" and self.previousFireMode ~= "primary" and status.overConsumeResource("energy", self.energyCost) then
      status.addEphemeralEffect("gyrostat", 0.1)
      animator.playSound("flashlight2", 1)
      animator.setParticleEmitterActive("activatedLight", true)      
      self.lastFireMode = fireMode
  else    
        status.removeEphemeralEffect("gyrostat") 
        animator.stopAllSounds("flashlight2")
        animator.setParticleEmitterActive("activatedLight", false) 
  end
    
end

function updateAim()
    self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
    -- self.aimAngle, self.aimDirection = aimAngle or 0, aimDirection or 0
    activeItem.setArmAngle(self.aimAngle)
    activeItem.setFacingDirection(self.aimDirection)
end


function uninit()
  status.removeEphemeralEffect("gyrostat")  
  animator.stopAllSounds("flashlight2")
  animator.setParticleEmitterActive("activatedLight", false)  
end
