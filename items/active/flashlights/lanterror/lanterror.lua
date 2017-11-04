require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.timer = 3
  self.fireOffset = config.getParameter("fireOffset")
  script.setUpdateDelta(5)
end

function update(dt, fireMode, shiftHeld, moves)
  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)
  updateAim()
 
  if fireMode == "primary" and self.previousFireMode ~= "primary" then
    if self.timer == 3 then
      self.active = not self.active
      animator.setLightActive("flashlight", self.active)
      animator.setLightActive("flashlightSpread", self.active)
      animator.playSound("flashlight")
      animator.setParticleEmitterActive("activatedLight", self.active)
      status.addEphemeralEffect("erchiusimmunity", math.huge)
      self.lastFireMode = fireMode
      self.timer= 0
    else
      self.timer= 3
      self.lastFireMode = fireMode
    end
  end
    
end

function updateAim()
    self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
    -- self.aimAngle, self.aimDirection = aimAngle or 0, aimDirection or 0
    activeItem.setArmAngle(self.aimAngle)
    activeItem.setFacingDirection(self.aimDirection)
end


function uninit()
  self.timer = 3
  animator.setParticleEmitterActive("activatedLight", false)
  status.removeEphemeralEffect("erchiusimmunity")  
end
