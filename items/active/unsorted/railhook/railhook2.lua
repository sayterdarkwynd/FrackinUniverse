require "/scripts/rails.lua"

function init()
  self.active = false

  self.connectionOffset = config.getParameter("connectionOffset", {0, 0})
  self.activeArmAngle = config.getParameter("activeArmAngle", 0)
  self.inactiveArmAngle = config.getParameter("inactiveArmAngle", 0)

  self.maxSpeed = config.getParameter("maxSpeed", 60)
  self.minSpeed = config.getParameter("minSpeed", 20)
  self.currentSpeed=self.maxSpeed

  self.speedCooldown = config.getParameter("speedCooldown", 1)
  self.speedTimer=0

  createRider()

  self.onRail = false
  self.volumeAdjustTimer = 0.0
  self.volumeAdjustTime = 0.1

  self.effectGroupName = "railhook" .. activeItem.hand()
end

function createRider()
  local railConfig = config.getParameter("railConfig", {})
  railConfig.speed = self.currentSpeed
  railConfig.onEngage = function() animator.playSound("engage") end

  self.railRider = Rails.createRider(railConfig)
  self.railRider:init()
end

function uninit()
  status.clearPersistentEffects(self.effectGroupName)
end

function update(dt, fireMode, shiftHeld, moves)
  self.speedTimer = math.max(0, self.speedTimer - dt)
  local edgeTrigger = fireMode ~= self.lastFireMode
  if shiftHeld and fireMode == "primary" then
    if self.speedTimer == 0 then
      switchSpeed()
      self.speedTimer=self.speedCooldown
    end
  elseif fireMode == "primary" then
    if edgeTrigger and self.railRider:onRail() then
      disengageHook()
    elseif edgeTrigger and not status.statPositive("activeMovementAbilities") and not mcontroller.onGround() then
      engageHook()
    end
  else
    if edgeTrigger and not self.railRider:onRail() then
      disengageHook()
    end
  end
  self.lastFireMode = fireMode

  if self.active then
    if mcontroller.isColliding() then
      disengageHook()
    else
      activeItem.setArmAngle(self.activeArmAngle)
      self.railRider:updateConnectionOffset(activeItem.handPosition(self.connectionOffset))

      self.railRider:update(dt)

      if self.railRider:onRail() then
        -- TODO: allow jumping off of rails
        mcontroller.controlModifiers({jumpingSuppressed = true, movementSuppressed = true})
        mcontroller.controlParameters({airForce = 0})
      end
    end
  else
    activeItem.setArmAngle(self.inactiveArmAngle)
  end

  if self.railRider:onRail() then
    status.setPersistentEffects(self.effectGroupName, {{stat = "activeMovementAbilities", amount = 1}})
    animator.setAnimationState("railState", "on")
  else
    status.clearPersistentEffects(self.effectGroupName)
    animator.setAnimationState("railState", "off")
  end

  local onRail = self.railRider:onRail() and self.railRider.moving and self.railRider.speed > 0.01
  if onRail then
    animator.setParticleEmitterActive("sparks", true)
    animator.setParticleEmitterEmissionRate("sparks", math.floor(self.railRider.speed) * 2)

    local volumeAdjustment = math.max(0.5, math.min(1.0, self.railRider.speed / 20))

    if not self.onRail then
      self.onRail = true
      animator.playSound("grind", -1)
      animator.setSoundVolume("grind", volumeAdjustment, 0)
    end

    self.volumeAdjustTimer = math.max(0, self.volumeAdjustTimer - dt)
    if self.volumeAdjustTimer == 0 then
      animator.setSoundVolume("grind", volumeAdjustment, self.volumeAdjustTime)
      self.volumeAdjustTimer = self.volumeAdjustTime
    end
  else
    animator.setParticleEmitterActive("sparks", false)

    self.onRail = false
    self.volumeAdjustTimer = self.volumeAdjustTime
    animator.stopAllSounds("grind")
  end

  local upHeld = moves["up"]
  local downHeld = moves["down"]
  local leftHeld = moves["left"]
  local rightHeld = moves["right"]

  if not self.railRider.moving then
    if upHeld then
      self.railRider:railResume(self.railRider:position(), nil, Rails.dirs.n)
    elseif downHeld then
      self.railRider:railResume(self.railRider:position(), nil, Rails.dirs.s)
    elseif leftHeld then
      self.railRider:railResume(self.railRider:position(), nil, Rails.dirs.w)
    elseif rightHeld then
      self.railRider:railResume(self.railRider:position(), nil, Rails.dirs.e)
    end
  end
end

function switchSpeed()
  if self.currentSpeed == self.maxSpeed then
    self.currentSpeed = self.minSpeed
    animator.playSound("minSpeed")
  else
    self.currentSpeed = self.maxSpeed
    animator.playSound("maxSpeed")
  end
  createRider()
end

function engageHook()
  activeItem.callOtherHandScript("disengageHook")
  self.active = true
  self.railRider:reset()
  activeItem.setArmAngle(self.activeArmAngle)
  self.railRider.connectionOffset = activeItem.handPosition(self.connectionOffset)
end

function disengageHook()
  self.active = false
  self.onRail = false
  self.railRider:reset()
end
