require "/scripts/util.lua"
require "/scripts/vec2.lua"

MechArm = {}

function MechArm:extend(config)
  return setmetatable(config and copy(config) or {}, {__index = self})
end

function MechArm:new(armConfig, armName, shoulderOffset, ownerUuid)
  local newArm = self:extend(armConfig)
  newArm.armName = armName
  newArm.shoulderOffset = shoulderOffset
  newArm.ownerUuid = ownerUuid
  newArm.rotationLimits = {-math.pi, math.pi}
  newArm.bobLocked = false
  newArm.aimLocked = false
  newArm:init()
  return newArm
end

function MechArm:init()
  -- not implemented
end

function MechArm:update(dt)
  -- not implemented
end

function MechArm:updateBase(dt, driverId, isFiring, wasFiring, aimPosition, facingDirection, crouchValue)
  self.crouchValue = crouchValue -- lpk: save crouch for use in shoulderPosition()
  self.driverId = driverId
  self.isFiring = isFiring
  self.wasFiring = wasFiring
  self.fireTriggered = isFiring and not wasFiring
  if self.frontPartImages or self.backPartImages then
    self:updateAnimationSide(facingDirection)
  end
  self:updateAimInfo(aimPosition, facingDirection)
  world.debugPoint(self:shoulderPosition(),"green")
end

function MechArm:updateAnimationSide(facingDirection)
  local isFront = (facingDirection > 0) == (self.armName == "rightArm")
  for partName, partImage in pairs(isFront and self.frontPartImages or self.backPartImages) do
    animator.setPartTag(partName, "partImage", partImage)
  end
end

function MechArm:shoulderPosition()
  return vec2.add(mcontroller.position(), vec2.add(self.shoulderOffset, {0, self.crouchValue or 0}))--lpk: apply crouch here for arm script use
end

function MechArm:updateAimInfo(aimPosition, facingDirection)
  if aimPosition and facingDirection and not self.aimLocked then
    self.aimPosition = aimPosition
    self.facingDirection = facingDirection

    local shoulderPos = self:shoulderPosition()
    local baseAimVector = world.distance(aimPosition, shoulderPos)
    local aimAngle = vec2.angle(baseAimVector)

    if facingDirection == -1 then
      aimAngle = math.pi - aimAngle
    end

    aimAngle = util.angleDiff(0, aimAngle)
    aimAngle = math.max(self.rotationLimits[1], math.min(aimAngle, self.rotationLimits[2]))

    local aimVector = vec2.withAngle(aimAngle)
    aimVector[1] = aimVector[1] * facingDirection

    local firePosition
    if self.fireOffset then
      firePosition = vec2.rotate(self.fireOffset, aimAngle)
      firePosition[1] = firePosition[1] * facingDirection
      firePosition = vec2.add(shoulderPos, firePosition)
    end

    self.aimAngle, self.aimVector, self.firePosition = aimAngle, aimVector, firePosition
  end
end

function MechArm:transformOffset(offset)
  offset = vec2.rotate(offset, self.aimAngle)
  offset[1] = offset[1] * self.facingDirection
  offset = vec2.add(self:shoulderPosition(), offset)
  return offset
end

function MechArm:rayCheck(firePosition)
  return not world.lineTileCollision(mcontroller.position(), firePosition)
end


function MechArm:gimmestats()
    return self.stats
end

function MechArm:fire()
  local projectileIds = {}

  if self.aimAngle and self.aimVector and self.firePosition and self:rayCheck(self.firePosition) then
    local pParams = copy(self.projectileParameters)
    if not self.projectileTrackSource and mcontroller.zeroG() then
      pParams.referenceVelocity = mcontroller.velocity()
    else
      pParams.referenceVelocity = nil
    end
    pParams.processing = self.directives

    local pCount = self.projectileCount or 1
    local pSpread = self.projectileSpread or 0
    local inacc = self.projectileInaccuracy or 0
    local aimVec = vec2.rotate(self.aimVector, -0.5 * (pCount - 1) * pSpread)

    local firePos = self.firePosition
    local pSpacing
    if self.projectileSpacing and pCount > 1 then
      pSpacing = vec2.mul(vec2.rotate(self.projectileSpacing, self.aimAngle), {self.facingDirection, 1})
      firePos = vec2.add(firePos, vec2.mul(pSpacing, (pCount - 1) * -0.5))
    end

    for i = 1, pCount do
      local thisFirePos = firePos
      if self.projectileRandomOffset then
        thisFirePos = vec2.add(thisFirePos, {(math.random() - 0.5) * self.projectileRandomOffset[1], (math.random() - 0.5) * self.projectileRandomOffset[2]})
      end

      local thisAimVec = aimVec
      if self.projectileInaccuracy then
        thisAimVec = vec2.rotate(thisAimVec, sb.nrand(self.projectileInaccuracy, 0))
      end

      if self.projectileRandomSpeed then
        pParams.speed = util.randomInRange(self.projectileRandomSpeed)
      end

      -- apply FU damage bonus , to tier Mech damage

        self.mechTier = (self.stats.power + self.stats.energy) /2
        self.multicount = self.stats.multicount
        if self.multicount then
          pParams.power = (pParams.power / self.multicount) * self.mechTier
        else
          pParams.power = pParams.power * self.mechTier
        end
      --end
      
      local projectileId = world.spawnProjectile(
          self.projectileType,
          thisFirePos,
          self.driverId,
          thisAimVec,
          self.projectileTrackSource,
          pParams)

      if projectileId then
        table.insert(projectileIds, projectileId)
      end

      aimVec = vec2.rotate(aimVec, pSpread)
      if pSpacing then
        firePos = vec2.add(firePos, pSpacing)
      end
    end
  end

  return projectileIds
end
