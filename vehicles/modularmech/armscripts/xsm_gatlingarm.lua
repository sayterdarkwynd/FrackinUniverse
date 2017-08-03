require "/vehicles/modularmech/armscripts/base.lua"

GatlingArm = MechArm:extend()

function GatlingArm:init()
  self.windupTimer = 0
  self.fireTimer = 0
  self.defaultProjectile = string.format("%s",self.projectileType) --save copy
  self.tracerCount = math.floor(math.random(4))
  self.newFirePosition = vec2.add(self:shoulderPosition(),self.fireOffset or {4,0})
end

function GatlingArm:update(dt)
  if self.isFiring then
    self.windupTimer = math.min(self.windupTimer + dt, self.windupTime)
  else
    self.windupTimer = math.max(0, self.windupTimer - dt)
  end

  if self.fireTriggered then
    animator.setAnimationState(self.armName, "windup")
  elseif self.wasFiring and not self.isFiring then
    animator.setAnimationState(self.armName, "winddown")
  end

  self.fireTimer = math.max(0, self.fireTimer - dt)

  if self.driverId and self.windupTimer > 0 then
    self.bobLocked = true
    self.newFirePosition = self:firePos()
    local aimFix = vec2.mag(vec2.sub(self:shoulderPosition(),self.newFirePosition))*2 < vec2.mag(vec2.sub(self:shoulderPosition(),self.aimPosition))
    self.aimAngle = aimFix and self:fireAngle() or self.aimAngle
    self.aimVector = aimFix and self:fireVector() or self.aimVector
    self.firePosition = aimFix and self.newFirePosition or self.firePosition

    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)
 
    if self.isFiring and self.windupTimer == self.windupTime and self.fireTimer == 0 then
      
      if self.tracerProjectile and self.tracerFrequency then
        if self.tracerCount >= self.tracerFrequency then
          self.projectileType = self.tracerProjectile
          self:fire()
          self.projectileType = self.defaultProjectile
          self.tracerCount = 0
        else
          self:fire()
          self.tracerCount = math.min(self.tracerCount + 1,self.tracerFrequency)
        end
      else
        self:fire()
      end

      animator.burstParticleEmitter(self.armName .. "Fire")
      animator.playSound(self.armName .. "Fire")

      self.fireTimer = self.fireTime
    end
  else
    animator.setAnimationState(self.armName, "idle")

    self.bobLocked = false
  end
end

function GatlingArm:fireAngle()
  local baseAimVector = world.distance(self.aimPosition, self.newFirePosition)
  local aimAngle = vec2.angle(baseAimVector)

  if self.facingDirection == -1 then
    aimAngle = math.pi - aimAngle
  end

  aimAngle = util.angleDiff(0, aimAngle)
  aimAngle = math.max(self.rotationLimits[1], math.min(aimAngle, self.rotationLimits[2]))

  return aimAngle
end

function GatlingArm:fireVector()
  local aimAngle = self:fireAngle()
  local aimVector = vec2.withAngle(aimAngle)
  aimVector[1] = aimVector[1] * self.facingDirection
  return aimVector
end

function GatlingArm:firePos()
  local firePosition = vec2.rotate(self.fireOffset, self:fireAngle())
  firePosition[1] = firePosition[1] * self.facingDirection
  firePosition = vec2.add(self:shoulderPosition(), firePosition)
  return firePosition
end
