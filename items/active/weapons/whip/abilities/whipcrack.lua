require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

-- whip primary attack plus swinging from torches like a boss
WhipCrack = WeaponAbility:new()

function WhipCrack:init()
  self.damageConfig.baseDamage = self.chainDps * self.fireTime

  self.weapon:setStance(self.stances.idle)
  animator.setAnimationState("attack", "idle")
  activeItem.setScriptedAnimationParameter("chains", nil)

  self.cooldownTimer = self:cooldownTime()

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end

  self.projectileConfig = self.projectileConfig or {}

  self.chain = config.getParameter("chain")

  self.anchorObjects = config.getParameter("anchorObjects", {"torch"})
  self.anchor = nil

  self.snapDistance = config.getParameter("snapDistance", 3.0)
  self.blockPiercing = config.getParameter("blockPiercing", false)
end

-- Ticks on every update regardless if this is the active ability
function WhipCrack:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == "primary" and self:canStartAttack() then
    self:setState(self.windup)
    self.fireHeld = true
  elseif self.fireMode ~= "primary" and self.fireHeld then
    self.fireHeld = false
    self:disconnect()
  end
end

function WhipCrack:canStartAttack()
  return not self.weapon.currentAbility and self.cooldownTimer == 0
end

-- State: windup
function WhipCrack:windup()
  self.weapon:setStance(self.stances.windup)

  animator.setAnimationState("attack", "windup")

  util.wait(self.stances.windup.duration)

  self:setState(self.extend)
end

-- State: extend
function WhipCrack:extend()
  self.weapon:setStance(self.stances.extend)

  animator.setAnimationState("attack", "extend")
  animator.playSound("swing")

  util.wait(self.stances.extend.duration)

  if self.fireHeld then
    self.anchor = self:findAnchor()
  end

  if self.anchor then
    animator.setAnimationState("attack", "fire")
    self:setState(self.swing)
  else
    animator.setAnimationState("attack", "fire")
    self:setState(self.fire)
  end
end

-- State: swing
function WhipCrack:swing()
  self.weapon:setStance(self.stances.swing)
  self.weapon:updateAim()

  self.cooldownTimer = self:cooldownTime()

  while self.anchor do
    if world.entityExists(self.anchor) then
      self.anchorPos = self.anchorPos or self:getAnchorPos()
      local chainEndPos = vec2.add(world.entityPosition(self.anchor), self.anchorPos)
      local chainStartPos = vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.startOffset))
      if not world.lineCollision(chainStartPos, chainEndPos) then --or self.blockPiercing then
        local aimVector = world.distance(chainEndPos, chainStartPos)
        local swingAngle = vec2.angle(aimVector)
        if not mcontroller.onGround() then
          mcontroller.controlApproachVelocityAlongAngle(swingAngle, 0, 1000, true)
        else
          mcontroller.controlModifiers({movementSuppressed = true})
        end

        if self.weapon.aimDirection < 0 then
          self.weapon.aimAngle = vec2.angle({-aimVector[1], aimVector[2]})
        else
          self.weapon.aimAngle = swingAngle
        end
        self.weapon:updateAim()

        self.chain.endPosition = chainEndPos
        activeItem.setScriptedAnimationParameter("chains", {self.chain})

        coroutine.yield()
      else
        self:disconnect()
      end
    else
      self:disconnect()
    end
  end
end

function WhipCrack:getAnchorPos()
local objectSpaceSort = function(a,b)
 if a[2] == b[2] then return a[1] < b[1] end
 return a[2] < b[2]
end
  local bounds = world.objectSpaces(self.anchor)
  table.sort(bounds,objectSpaceSort)
  local wid = (math.floor(bounds[#bounds][1] - bounds[1][1])+1)
  local ax = bounds[1][1] + (wid/2)
  local ay = (bounds[1][2])+0.25
return {ax,ay}
end

function WhipCrack:disconnect()
  self.anchor = nil
  self.anchorPos = nil
  animator.setAnimationState("attack", "idle")
  self.chain.endPosition = nil
  activeItem.setScriptedAnimationParameter("chains", nil)
end

-- State: fire
function WhipCrack:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  local chainStartPos = vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.startOffset))
  local chainLength = world.magnitude(chainStartPos, activeItem.ownerAimPosition())
  chainLength = math.min(self.chain.length[2], math.max(self.chain.length[1], chainLength))

  self.chain.endOffset = vec2.add(self.chain.startOffset, {chainLength, 0})
  local collidePoint = world.lineCollision(chainStartPos, vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.endOffset))) --and not self.blockPiercing
  if collidePoint then
    chainLength = world.magnitude(chainStartPos, collidePoint) - 0.25
    if chainLength < self.chain.length[1] then
      animator.setAnimationState("attack", "idle")
      return
    else
      self.chain.endOffset = vec2.add(self.chain.startOffset, {chainLength, 0})
    end
  end

  local chainEndPos = vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.endOffset))

  activeItem.setScriptedAnimationParameter("chains", {self.chain})

  animator.resetTransformationGroup("endpoint")
  animator.translateTransformationGroup("endpoint", self.chain.endOffset)
  animator.burstParticleEmitter("crack")
  animator.playSound("crack")

  self.projectileConfig.power = self:crackDamage()
  self.projectileConfig.powerMultiplier = activeItem.ownerPowerMultiplier()

  local projectileAngle = vec2.withAngle(self.weapon.aimAngle)
  if self.weapon.aimDirection < 0 then projectileAngle[1] = -projectileAngle[1] end

  world.spawnProjectile(
    self.projectileType,
    chainEndPos,
    activeItem.ownerEntityId(),
    projectileAngle,
    false,
    self.projectileConfig
  )

  util.wait(self.stances.fire.duration, function()
    if self.damageConfig.baseDamage > 0 then
      self.weapon:setDamage(self.damageConfig, {self.chain.startOffset, {self.chain.endOffset[1] + 0.75, self.chain.endOffset[2]}}, self.fireTime)
    end
  end)

  animator.setAnimationState("attack", "idle")
  activeItem.setScriptedAnimationParameter("chains", nil)

  self.cooldownTimer = self:cooldownTime()
end

function WhipCrack:cooldownTime()
  return self.fireTime - (self.stances.windup.duration + self.stances.extend.duration + self.stances.fire.duration)
end

function WhipCrack:uninit(unloaded)
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", nil)
end

function WhipCrack:chainDamage()
  return (self.chainDps * self.fireTime) * config.getParameter("damageLevelMultiplier")
end

function WhipCrack:crackDamage()
  return (self.crackDps * self.fireTime) * config.getParameter("damageLevelMultiplier")
end

function WhipCrack:findAnchor()
  local objectsNearCursor = world.objectQuery(activeItem.ownerAimPosition(), 7, {boundMode = "metaboundbox", order = "nearest"})
  if #objectsNearCursor > 0 then
    local anchorValid = nil
    for _, anchorObject in pairs(objectsNearCursor) do
      local objectName = world.entityName(anchorObject)
      local objectConfig = { pcall(root.itemConfig, objectName) } -- want [1]=true, [2]=config
      if objectConfig[1] == true and objectConfig[2].config.category == "light" then
        anchorValid = anchorObject
        break
      end
    end
    if anchorValid then
      local pos = vec2.add(world.entityPosition(anchorValid), {0.5, 0.5})
      local distToCursor = world.magnitude(pos, activeItem.ownerAimPosition())
      local distToHand = world.magnitude(pos, vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.startOffset)))
      if distToCursor <= self.snapDistance and distToHand <= self.chain.length[2] and distToHand >= self.chain.length[1] then
        return anchorValid
      end
    end
  end
end
