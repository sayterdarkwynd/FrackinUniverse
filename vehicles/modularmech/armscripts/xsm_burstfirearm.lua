require "/vehicles/modularmech/armscripts/base.lua"

BurstFire = MechArm:extend()

function BurstFire:init()
  self.state = FSM:new()
  self.projectileIds = {}
end

function BurstFire:update(dt)
  self:updateProjectiles()

  if self.state.state then
    self.state:update()
  end

  if not self.state.state then
    if self.isFiring then
      self.state:set(self.fireState, self)
    end
  end

  if not self.state.state then
    self.bobLocked = false
  end
--  world.debugPoint(self.firePosition,"green")
end

function BurstFire:updateProjectiles()
  self.projectileIds = util.filter(self.projectileIds, function(pId)
      if world.entityExists(pId) then
        world.sendEntityMessage(pId, "setTargetPosition", self.aimPosition)
        return true
      end
      return false
    end)
end

function BurstFire:fireState()
  self.bobLocked = true

  animator.setAnimationState(self.armName, "rotate")

  local stateTimer = self.windupTime
  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

    stateTimer = stateTimer - script.updateDt()
    coroutine.yield()
  end

  if not self:rayCheck(self.firePosition) then
    animator.setAnimationState(self.armName, "idle")
    self.state:set()
    return
  end
  
  local intervalTimer = 0
  local burstCount = 0
  stateTimer = self.fireTime
  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)
    
    if intervalTimer <= 0 and burstCount < self.burstCount then
     
      animator.setAnimationState(self.armName, "active")
      animator.playSound(self.armName .. "Fire")

      local projectileIds = self:fire()
      util.appendLists(self.projectileIds, projectileIds)
      intervalTimer = self.burstInterval
      burstCount = burstCount + 1
    end

    intervalTimer = intervalTimer - script.updateDt()
    stateTimer = stateTimer - script.updateDt()
    coroutine.yield()
  end

  self.state:set(self.cooldownState, self)
end

function BurstFire:cooldownState()
  animator.setAnimationState(self.armName, "recover")

  local stateTimer = self.cooldownTime
  while stateTimer > 0 do
    stateTimer = stateTimer - script.updateDt()
    coroutine.yield()
  end

--  animator.setAnimationState(self.armName, "recover")
  animator.playSound(self.armName .. "Recover")

  self.state:set()
end
