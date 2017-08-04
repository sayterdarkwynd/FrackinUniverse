require "/vehicles/modularmech/armscripts/base.lua"

MeleeArm = MechArm:extend()

function MeleeArm:init()
  self.state = FSM:new()
  self.baseDamage = self.projectileParameters.power
end

function MeleeArm:update(dt)
  if self.state.state then
    self.state:update()
  end

  if not self.state.state then
    if self.fireTriggered then
      self.state:set(self.windupState, self)
    end
  end

  if self.state.state then
    self.bobLocked = true
  else
    animator.setAnimationState(self.armName, "idle")
    self.bobLocked = false
  end
end

function MeleeArm:windupState()
  animator.setAnimationState(self.armName, "windup")

  local stateTimer = self.windupTime
  while stateTimer > 0 do
--    animator.rotateTransformationGroup(self.armName, self.aimAngle + self.windupAngle, self.shoulderOffset)
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)
    stateTimer = stateTimer - script.updateDt()
    coroutine.yield()
  end

  self.state:set(self.fireState, self, self.windupAngle, self.fireAngle, true)
end

function MeleeArm:fireState(fromAngle, toAngle, allowCombo) -- allowCombo flase=downSlash true = upslash
  animator.playSound(self.armName .. "Fire")
  animator.setAnimationState(self.armName, "active")
--  allowCombo = false
  
  local stateTimer = self.fireTime
  local projectileSpawnTime = stateTimer - self.swingTime
  local fireWasTriggered = false
  while stateTimer > 0 do
    fireWasTriggered = fireWasTriggered or self.fireTriggered

    local swingRatio = math.min(1, (self.fireTime - stateTimer) / self.swingTime)
    local currentAngle = util.lerp(swingRatio, fromAngle, toAngle)
--    animator.rotateTransformationGroup(self.armName, self.aimAngle + currentAngle, self.shoulderOffset)
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

    local dt = script.updateDt()
    if stateTimer == self.fireTime then -- upswing
      local travelDist = self.projectileBaseDistance - self.shoulderOffset[1] * self.facingDirection
      self.projectileParameters.speed = travelDist / self.projectileTimeToLive
      self.projectileParameters.power = self.baseDamage * 0.4
      self.projectileType = self.projectileSwooshUp
      
      self:fire()
    end
    if stateTimer > projectileSpawnTime and (stateTimer - projectileSpawnTime) < dt then
      local travelDist = self.projectileBaseDistance - self.shoulderOffset[1] * self.facingDirection
      self.projectileParameters.speed = travelDist / self.projectileTimeToLive
      self.projectileParameters.power = self.baseDamage * 0.6
      self.projectileType = self.projectileSwooshDown

      self:fire()
    end

    stateTimer = stateTimer - dt
    coroutine.yield()
  end

  if allowCombo and fireWasTriggered then
    self.state:set()
    self.state:set(self.fireState, self, self.fireAngle, self.comboFireAngle, true)
  else
    self.state:set(self.cooldownState, self)
  end
end

function MeleeArm:cooldownState()
  animator.setAnimationState(self.armName, "winddown")

  local stateTimer = self.cooldownTime
  while stateTimer > 0 do
--    animator.rotateTransformationGroup(self.armName, self.cooldownAngle, self.shoulderOffset)
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)
    stateTimer = stateTimer - script.updateDt()
    coroutine.yield()
  end

  self.state:set()
end
