require "/vehicles/modularmech/armscripts/base.lua"

BeamArm = MechArm:extend()

function BeamArm:init()
  self.state = FSM:new()
end

function BeamArm:update(dt)
  if self.state.state then
    self.state:update()
  end

  if not self.state.state then
    if self.isFiring then
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

function BeamArm:windupState()
  local stateTimer = self.windupTime

  animator.setAnimationState(self.armName, "windup")
  animator.playSound(self.armName .. "Windup")

  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

    local dt = script.updateDt()
    stateTimer = stateTimer - dt
    coroutine.yield()
  end

  if self.isFiring then
    self.state:set(self.fireState, self)
  else
    self.state:set(self.winddownState, self)
  end
end

function BeamArm:fireState()
  local stateTimer = self.fireTime

  animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

  local endPoint, beamCollision, beamLength = self:updateBeam()

  animator.playSound(self.armName .. "Fire")
  animator.setParticleEmitterBurstCount(self.armName .. "Beam", math.ceil(self.beamParticleDensity * beamLength))
  animator.burstParticleEmitter(self.armName .. "Beam")
  animator.setAnimationState(self.armName .. "Beam", "fire", true)

  vehicle.setDamageSourceEnabled(self.armName .. "Beam", true)

  self.aimLocked = self.lockAim

  if beamCollision and self.beamTileDamage > 0 then
    local maximumEndPoint = vec2.add(self.firePosition, vec2.mul(self.aimVector, self.beamLength))
    local damagePositions = world.collisionBlocksAlongLine(self.firePosition, maximumEndPoint, nil, self.beamTileDamageDepth)
    world.damageTiles(damagePositions, "foreground", self.firePosition, "beamish", self.beamTileDamage, 99)
    world.damageTiles(damagePositions, "background", self.firePosition, "beamish", self.beamTileDamage, 99)
  end

  coroutine.yield()

  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

    self:updateBeam()

    local dt = script.updateDt()
    stateTimer = stateTimer - dt
    coroutine.yield()
  end

  self.aimLocked = false

  vehicle.setDamageSourceEnabled(self.armName .. "Beam", false)

  if self.isFiring and self.repeatFire then
    self.state:set(self.fireState, self)
  else
    self.state:set(self.winddownState, self)
  end
end

function BeamArm:winddownState()
  local stateTimer = self.winddownTime or 0

  animator.setAnimationState(self.armName, "winddown")

  while stateTimer > 0 do
    animator.rotateTransformationGroup(self.armName, self.aimAngle, self.shoulderOffset)

    local dt = script.updateDt()
    stateTimer = stateTimer - dt
    coroutine.yield()
  end

  self.state:set()
end

function BeamArm:updateBeam()
  local endPoint = vec2.add(self.firePosition, vec2.mul(self.aimVector, self.beamLength))
  local beamCollision = world.lineCollision(self.firePosition, endPoint)
  if beamCollision then
    endPoint = beamCollision
  end
  local beamLength = world.magnitude(self.firePosition, endPoint)

  animator.resetTransformationGroup(self.armName .. "Beam")
  animator.scaleTransformationGroup(self.armName .. "Beam", {beamLength, 1}, {self.beamSourceOffset[1], self.beamSourceOffset[2] - self.beamHeight / 2})

  local particleRegion = {self.beamSourceOffset[1], self.beamSourceOffset[2], self.beamSourceOffset[1] + beamLength, self.beamSourceOffset[2]}
  animator.setParticleEmitterOffsetRegion(self.armName .. "Beam", particleRegion)

  return endPoint, beamCollision, beamLength
end
