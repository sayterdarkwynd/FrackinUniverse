require "/monsters/monster.lua"

-- Engine callback - called on initialization of entity
function init()
  if storage.despawn then
    despawn()
    return
  end

  self.pathing = {}

  self.shouldDie = true
  self.notifications = {}
  storage.spawnTime = world.time()
  if storage.spawnPosition == nil or config.getParameter("wasRelocated", false) then
    local position = mcontroller.position()
    local groundSpawnPosition
    if mcontroller.baseParameters().gravityEnabled then
      groundSpawnPosition = findGroundPosition(position, -20, 3)
    end
    storage.spawnPosition = groundSpawnPosition or position
  end

  self.behavior = behavior.behavior(config.getParameter("behavior"), config.getParameter("behaviorConfig", {}), _ENV)
  self.board = self.behavior:blackboard()
  self.board:setPosition("spawn", storage.spawnPosition)

  script.setUpdateDelta(1)
  mcontroller.setAutoClearControls(false)

  -- Listen to damage taken
  self.damageTaken = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        self.damaged = true
        self.board:setEntity("damageSource", notification.sourceEntityId)
      elseif self.shielded then
        animator.setAnimationState("shield", "hit", true)
      end
    end
  end)

  message.setHandler("notify", function(_,_,notification)
      return notify(notification)
    end)
  message.setHandler("despawn", despawn)

  self.forceRegions = ControlMap:new(config.getParameter("forceRegions", {}))
  self.damageSources = ControlMap:new(config.getParameter("damageSources", {}))
  self.touchDamageEnabled = false

  if config.getParameter("damageBar") then
    monster.setDamageBar(config.getParameter("damageBar"));
  end

  monster.setInteractive(config.getParameter("interactive", false))

  self.angle = 0

  self.damageBeam = config.getParameter("handBeam")
  self.shielded = config.getParameter("shielded")
  if self.shielded then
    animator.setAnimationState("shield", "active")
  end

  self.elementalType = config.getParameter("elementalType")
  self.damageBeam.startSegmentImage = string.gsub(self.damageBeam.startSegmentImage, "<element>", self.elementalType)
  self.damageBeam.segmentImage = string.gsub(self.damageBeam.segmentImage, "<element>", self.elementalType)
  self.damageBeam.endSegmentImage = string.gsub(self.damageBeam.endSegmentImage, "<element>", self.elementalType)

  self.spawnBeam = config.getParameter("spawnBeam")
  self.beamTypes = {
    damage = self.damageBeam,
    spawn = self.spawnBeam
  }
end

-- This is called in update() using pcall
-- to catch errors
function update(dt)
  if storage.despawn then return end

  self.damageTaken:update()

  mcontroller.clearControls()

  self.tradingEnabled = false
  self.setFacingDirection = false
  self.moving = false
  self.rotated = false
  self.chains = {}
  self.forceRegions:clear()
  self.damageSources:clear()
  self.damageParts = {}
  clearAnimation()

  local wasBeam = self.beam
  self.beam = false

  self.board:setEntity("self", entity.id())
  self.board:setPosition("self", mcontroller.position())
  self.board:setNumber("dt", dt)
  self.board:setNumber("facingDirection", self.facingDirection or mcontroller.facingDirection())

  movementAnimation(dt)

  self.behavior:run(dt)

  updateAnimation()

  self.damaged = false
  self.stunned = false
  self.notifications = {}

  monster.setAnimationParameter("chains", self.chains)
  if not self.beam and wasBeam then
    animator.stopAllSounds("beamLoop")
  end

  setDamageSources()
  setPhysicsForces()
  monster.setDamageParts(self.damageParts)
  overrideCollisionPoly()
end

function despawn()
  monster.setDropPool(nil)
  monster.setDeathParticleBurst(nil)
  monster.setDeathSound(nil)
  self.shouldDie = true
  storage.despawn = true
  status.addEphemeralEffect("monsterdespawn")
end

function movementAnimation(dt)
  local maxAngle = -0.3
  local maxSpeed = 25
  local xVel = util.clamp(mcontroller.velocity()[1] * mcontroller.facingDirection(), -maxSpeed, maxSpeed)
  local approachAngle = xVel / maxSpeed * maxAngle
  self.angle = self.angle + (util.angleDiff(self.angle, approachAngle) * dt * 4)
  animator.resetTransformationGroup("all")
  animator.rotateTransformationGroup("all", self.angle / 2)
  local lowerParts = {
    rightleg = "rlanchor",
    leftleg = "llanchor",
  }
  local upperParts = {
    righthand = "rhanchor",
    lefthand = "lhanchor",
  }
  for group,rotationCenter in pairs(lowerParts) do
    animator.resetTransformationGroup(group)
    animator.rotateTransformationGroup(group, self.angle, animator.partPoint("body", rotationCenter))
  end
  for group,rotationCenter in pairs(upperParts) do
    animator.resetTransformationGroup(group)
    animator.rotateTransformationGroup(group, -self.angle / 2, animator.partPoint("body", rotationCenter))
  end

  if contains({"active", "hit"}, animator.animationState("shield")) then
    animator.rotateTransformationGroup("shield", 2.0 * dt)
  elseif animator.animationState("shield") == "off" then
    animator.rotateTransformationGroup("shield", 0.4 * dt)
  end
end

function pointHand(part, angle)
  local flipTags = {
    righthand = "rhflip",
    lefthand = "lhflip"
  }
  if math.cos(angle) * mcontroller.facingDirection() > 0 then
    animator.setGlobalTag(flipTags[part], ".flip")
  else
    animator.setGlobalTag(flipTags[part], "")
  end

  angle = (angle + math.pi / 2) * mcontroller.facingDirection() -- hand points down in the sprite
  local startOffset = vec2.mul(vec2.add(animator.partProperty(part, "offset"), animator.partProperty(part, "rotationCenter")), -1)
  animator.resetTransformationGroup(part)
  animator.translateTransformationGroup(part, startOffset) -- rotate hand around entity center
  animator.rotateTransformationGroup(part, angle)
end


function handBeam(part, angle, frame, beamType, bounces, maxLength)
  self.beam = true
  beamType = beamType or "damage"
  bounces = bounces or 0
  self.displayBeam = true

  local beam = copy(self.beamTypes[beamType])
  beam.sourcePart = part
  beam.endPart = part
  beam.maxLength = maxLength

  local currentFrame = frame or 4
  beam.startSegmentImage = beam.startSegmentImage:gsub("<beamFrame>", currentFrame)
  beam.segmentImage = beam.segmentImage:gsub("<beamFrame>", currentFrame)
  beam.endSegmentImage = beam.endSegmentImage:gsub("<beamFrame>", currentFrame)
  beam.testCollision = true
  beam.bounces = bounces

  table.insert(self.chains, beam)
  pointHand(part, angle)
end

function shouldDie()
  return (self.shouldDie and status.resource("health") <= 0)
end

function die()
  spawnDrops()
end
