function init()
  local detectConfig = config.getParameter("pingDetectConfig")
  activeItem.setScriptedAnimationParameter("pingDetectConfig", detectConfig)
end

function update(dt, fireMode, shiftHeld)
	updateAim()
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.aimDirection)
end