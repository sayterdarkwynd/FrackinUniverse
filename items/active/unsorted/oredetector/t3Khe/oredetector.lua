require "/scripts/vec2.lua"

function init()
  self.pingRange = config.getParameter("pingRange")
  self.pingBandWidth = 10
  self.pingDuration = 1

  self.pingTimer = 0
  self.cooldownTimer = 0
  local detectConfig = config.getParameter("pingDetectConfig")
  detectConfig.maxRange = self.pingRange
  activeItem.setScriptedAnimationParameter("pingDetectConfig", detectConfig)
  activeItem.setScriptedAnimationParameter("pingLocation", nil)
end

function uninit()

end

function update(dt, fireMode, shiftHeld)
  updateAim()
	doStuff(fireMode,shiftHeld)

  if self.pingTimer > 0 then
    self.pingTimer = math.max(self.pingTimer - dt, 0)
    if self.pingTimer == 0 then
      activeItem.setScriptedAnimationParameter("pingLocation", nil)
    else
      local radius = (self.pingRange + self.pingBandWidth) * ((self.pingDuration - self.pingTimer) / self.pingDuration) - self.pingBandWidth
      activeItem.setScriptedAnimationParameter("pingOuterRadius", radius + self.pingBandWidth)
      activeItem.setScriptedAnimationParameter("pingInnerRadius", math.max(radius, 0))
    end
  end
end

function doStuff()
  if ready() then
    self.pingTimer = self.pingDuration
    local pingOffset = animator.partPoint("detector", "pingPosition")
    pingOffset[1] = pingOffset[1] * self.aimDirection
    local pingLocation = vec2.floor(vec2.add(mcontroller.position(), pingOffset))
    activeItem.setScriptedAnimationParameter("pingLocation", pingLocation)
    animator.playSound("ping")
  end
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.aimDirection)
end

function ready()
  return self.pingTimer == 0 and self.cooldownTimer == 0
end
