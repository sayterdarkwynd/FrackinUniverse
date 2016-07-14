require "/scripts/vec2.lua"
require "/scripts/util.lua"

GuidedBolt = WeaponAbility:new()

function GuidedBolt:init()
  self.elementalType = self.elementalType or self.weapon.elementalType

  activeItem.setCursor("/cursors/reticle0.cursor")

  self.guides = {}
  self.guideTimer = 0

  self.guideRefreshTimer = 0

  self.stances = config.getParameter("stances")

  self.weapon:setStance(self.stances.idle)

  self.weapon.onLeaveAbility = function()
    self:reset()
  end
end

function GuidedBolt:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.guideTimer = math.max(0, self.guideTimer - self.dt)
  self.guideRefreshTimer = math.max(0, self.guideRefreshTimer - self.dt)

  if self.guideRefreshTimer == 0 then
    self:refreshGuides()
    self.guideRefreshTimer = self.guideRefreshRate
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and not status.resourceLocked("energy") then

    self:setState(self.charge)
  end
end

function GuidedBolt:charge()
  self.weapon:setStance(self.stances.charge)

  animator.playSound(self.elementalType.."charge")
  animator.setAnimationState("charge", "charge")
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)
  activeItem.setCursor("/cursors/charge2.cursor")

  local chargeTimer = self.stances.charge.duration
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    status.setResourcePercentage("energyRegenBlock", 1.0)

    coroutine.yield()
  end

  animator.stopAllSounds(self.elementalType.."charge")

  if chargeTimer <= 0 then
    self:setState(self.charged)
  else
    animator.playSound(self.elementalType.."discharge")
    self:setState(self.cooldown)
  end
end

function GuidedBolt:charged()
  self.weapon:setStance(self.stances.charged)

  animator.playSound(self.elementalType.."fullcharge")
  animator.playSound(self.elementalType.."chargedloop", -1)
  animator.setParticleEmitterActive(self.elementalType .. "charge", true)
  activeItem.setCursor("/cursors/chargeready.cursor")

  self.guides = {}
  self.guideTimer = 0

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    self:tracePath()

    mcontroller.controlModifiers({runningSuppressed=true})

    status.setResourcePercentage("energyRegenBlock", 1.0)

    coroutine.yield()
  end

  animator.stopAllSounds(self.elementalType.."chargedloop")

  self:setState(self.discharge)
end

function GuidedBolt:discharge()
  self.weapon:setStance(self.stances.discharge)

  animator.setAnimationState("charge", "discharge")
  animator.playSound("physicalactivate")
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)

  animator.playSound(self.elementalType.."activate")

  self:castBolt()
  self:clearGuides()

  -- sb.logInfo("bolt segments are %s", self.boltSegments)

  local timeLeft = self.stances.discharge.duration
  util.wait(self.stances.discharge.duration, function(dt)
    self.weapon:setOwnerDamageAreas(self.damageConfig, self.boltSegments)

    timeLeft = timeLeft - dt
    local colorFactor = 1 - (timeLeft / self.stances.discharge.duration)
    local lightningColor = {
      util.lerp(colorFactor, self.lightningStartColor[1], self.lightningEndColor[1]),
      util.lerp(colorFactor, self.lightningStartColor[2], self.lightningEndColor[2]),
      util.lerp(colorFactor, self.lightningStartColor[3], self.lightningEndColor[3]),
      util.lerp(colorFactor, self.lightningStartColor[4], self.lightningEndColor[4])
    }
    for i, bolt in ipairs(self.lightning) do
      self.lightning[i].color = lightningColor
    end
    activeItem.setScriptedAnimationParameter("lightning", self.lightning)
  end)

  activeItem.setScriptedAnimationParameter("lightning", {})

  self:setState(self.cooldown)
end

function GuidedBolt:cooldown()
  self.weapon:setStance(self.stances.cooldown)

  animator.setAnimationState("charge", "discharge")
  activeItem.setCursor("/cursors/reticle0.cursor")

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function GuidedBolt:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("stone", "focalPoint")))
end

function GuidedBolt:castBolt()
  self.boltSegments = {}
  local lastGuidePos = self:firePosition()
  for i, guideId in ipairs(self.guides) do
    local thisPos = world.entityPosition(guideId)
    if world.lineCollision(lastGuidePos, thisPos) or world.magnitude(lastGuidePos, thisPos) > self.guideDistance * 2 then
      break
    end
    table.insert(self.boltSegments, {lastGuidePos, thisPos})
    lastGuidePos = thisPos
  end

  self.lightning = {}
  for i, segment in ipairs(self.boltSegments) do
    local bolt = copy(self.lightningConfig)
    bolt.worldStartPosition = segment[1]
    bolt.worldEndPosition = segment[2]
    bolt.displacement = vec2.mag(vec2.sub(segment[1], segment[2])) / 5
    table.insert(self.lightning, bolt)
    table.insert(self.lightning, bolt)
    -- table.insert(self.lightning, bolt)
  end

  activeItem.setScriptedAnimationParameter("lightningSeed", math.floor((os.time() + (os.clock() % 1)) * 1000))
end

function GuidedBolt:tracePath()
  if #self.guides < self.maxGuides and self.guideTimer == 0 and status.resourcePositive("energy") then
    local lastGuidePos
    if #self.guides == 0 then
      lastGuidePos = self:firePosition()
    else
      -- if we've moved too far away from the first guide, try to add guides to the beginning instead
      local firstGuidePos = world.entityPosition(self.guides[1])
      local extendOffset = world.distance(self:firePosition(), firstGuidePos)
      if vec2.mag(extendOffset) >= self.guideDistance * 1.5 then
        local targetPosition = vec2.add(firstGuidePos, vec2.mul(vec2.norm(extendOffset), self.guideDistance))

        if not world.lineCollision(targetPosition, firstGuidePos) then
          self:addGuide(targetPosition, 1)
        end

        return
      else
        lastGuidePos = world.entityPosition(self.guides[#self.guides])
      end
    end

    local extendOffset = world.distance(activeItem.ownerAimPosition(), lastGuidePos)
    if vec2.mag(extendOffset) >= self.guideDistance then
      local targetPosition = vec2.add(lastGuidePos, vec2.mul(vec2.norm(extendOffset), self.guideDistance))

      if not world.lineCollision(targetPosition, lastGuidePos) then
        self:addGuide(targetPosition)
      end
    end
  end
end

function GuidedBolt:addGuide(position, addToStart)
  local projectileId = world.spawnProjectile(
      self.projectileType,
      position,
      activeItem.ownerEntityId(),
      {0, 0},
      false,
      {}
    )

  if projectileId then
    status.overConsumeResource("energy", self.energyCost)

    if addToStart then
      table.insert(self.guides, 1, projectileId)
    else
      table.insert(self.guides, projectileId)
    end
    self.guideTimer = self.guideTime
    animator.playSound("addGuide"..#self.guides)
  end
end

function GuidedBolt:refreshGuides()
  for i, guideId in ipairs(self.guides) do
    if world.entityExists(guideId) then
      world.callScriptedEntity(guideId, "keepAlive")
    end
  end
end

function GuidedBolt:clearGuides()
  for i, guideId in ipairs(self.guides) do
    if world.entityExists(guideId) then
      world.callScriptedEntity(guideId, "clearGuide")
    end
  end
  self.guides = {}
end

function GuidedBolt:reset()
  self:clearGuides()
  self.weapon:setStance(self.stances.idle)
  animator.stopAllSounds(self.elementalType.."chargedloop")
  animator.stopAllSounds(self.elementalType.."fullcharge")
  animator.setAnimationState("charge", "idle")
  animator.setParticleEmitterActive(self.elementalType .. "charge", false)
  activeItem.setScriptedAnimationParameter("lightning", {})
  activeItem.setCursor("/cursors/reticle0.cursor")
end

function GuidedBolt:uninit()
  self:reset()
end
