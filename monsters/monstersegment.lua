require "/scripts/behavior.lua"
require "/scripts/pathing.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/drops.lua"
require "/scripts/status.lua"
require "/scripts/companions/capturable.lua"
require "/scripts/tenant.lua"
require "/scripts/actions/movement.lua"
require "/scripts/actions/animator.lua"

-- Engine callback - called on initialization of entity
function init()
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
  BData:setPosition("spawn", storage.spawnPosition)

  if not config.getParameter("parent") or config.getParameter("dynamic") then
    self.behavior = root.behavior(config.getParameter("behavior"), config.getParameter("behaviorConfig", {}))
    self.behaviorState = self.behavior:init(_ENV)
  end
  
  self.collisionPoly = mcontroller.collisionPoly()

  if animator.hasSound("deathPuff") then
    monster.setDeathSound("deathPuff")
  end
  if config.getParameter("deathParticles") then
    monster.setDeathParticleBurst(config.getParameter("deathParticles"))
  end

  script.setUpdateDelta(1)
  mcontroller.setAutoClearControls(false)
  self.behaviorTickRate = config.getParameter("behaviorUpdateDelta", 5)
  self.behaviorTick = math.random(1, self.behaviorTickRate)

  animator.setGlobalTag("flipX", "")
  BData:setNumber("facingDirection", mcontroller.facingDirection())

  capturable.init()

  -- Listen to damage taken
  if not config.getParameter("parent") then
    self.damageTaken = damageListener("damageTaken", function(notifications)
      for _,notification in pairs(notifications) do
        if notification.healthLost > 0 then
          self.damaged = true
          BData:setEntity("damageSource", notification.sourceEntityId)
        end
      end
    end)
  else
    self.damageTaken = damageListener("damageTaken", function(notifications)
      for _,notification in pairs(notifications) do
        if notification.healthLost > 0 then
        self.damaged = true
	      status.setResourcePercentage("health",100)
	      world.sendEntityMessage(config.getParameter("head"),"headDamage",notification)
        end
      end
    end)
  end

  self.debug = true

  message.setHandler("notify", function(_,_,notification)
      return notify(notification)
    end)
  message.setHandler("despawn", function()
      monster.setDropPool(nil)
      monster.setDeathParticleBurst(nil)
      monster.setDeathSound(nil)
      self.deathBehavior = nil
      self.shouldDie = true
      status.addEphemeralEffect("monsterdespawn")
    end)

  local deathBehavior = config.getParameter("deathBehavior")
  if deathBehavior then
    self.deathBehavior = root.behavior(deathBehavior, config.getParameter("behaviorConfig", {}))
  end

  self.forceRegions = ControlMap:new(config.getParameter("forceRegions", {}))
  self.damageSources = ControlMap:new(config.getParameter("damageSources", {}))
  self.touchDamageEnabled = true

  if config.getParameter("damageBar") then
    monster.setDamageBar(config.getParameter("damageBar"));
  end

  monster.setInteractive(config.getParameter("interactive", false))

  self.segments = config.getParameter("segments")
  self.child = config.getParameter("segmentMonster")
  self.segmentArray = type(self.child) == 'table' and self.child or nil
  self.child = self.segmentArray and self.segmentArray[self.segments] or self.child
  if not config.getParameter("parent") then 
    self.head = entity.id()
    message.setHandler("headDamage", function(_,__,notification)
     self.damaged = true
     BData:setEntity("damageSource", notification.sourceEntityId)
     status.overConsumeResource("health",notification.healthLost)
    end)
  else
    self.totalSegments = self.segments
  end
  if self.segments > 0 then 
	self.child = world.spawnMonster(self.child, mcontroller.position(),
  	{
  	head = self.head and self.head or config.getParameter("head"), 
  	parent = entity.id(), 
  	segmentMonster = config.getParameter("segmentMonster"),
    totalSegments = self.totalSegments and self.totalSegments or config.getParameter("totalSegments"),
  	segments = self.segments - 1, 
  	parentRadius = config.getParameter("radius"),
    damageBar = false,
    dynamic = config.getParameter("dynamicSegments") or config.getParameter("dynamic"),
  	renderLayer = "foregroundEntity+"..tostring(self.segments)})
  end 
end

-- This is called in update() using pcall
-- to catch errors
function update(dt)

  capturable.update(dt)
  self.damageTaken:update()

  if status.resourcePositive("stunned") then
    animator.setAnimationState("damage", "stunned")
    animator.setGlobalTag("hurt", "hurt")
    self.stunned = true
    mcontroller.clearControls()
    if self.damaged then
      self.suppressDamageTimer = config.getParameter("stunDamageSuppression", 0.5)
      monster.setDamageOnTouch(false)
    end
    return
  else
    animator.setGlobalTag("hurt", "")
    animator.setAnimationState("damage", "none")
  end

  -- Suppressing touch damage
  if self.suppressDamageTimer then
    monster.setDamageOnTouch(false)
    self.suppressDamageTimer = math.max(self.suppressDamageTimer - dt, 0)
    if self.suppressDamageTimer == 0 then
      self.suppressDamageTimer = nil
    end
  elseif status.statPositive("invulnerable") then
    monster.setDamageOnTouch(false)
  else
    monster.setDamageOnTouch(self.touchDamageEnabled)
  end


  if self.behaviorTick >= self.behaviorTickRate then
    self.behaviorTick = self.behaviorTick - self.behaviorTickRate
    mcontroller.clearControls()

    self.tradingEnabled = false
    self.setFacingDirection = false
    self.moving = false
    self.rotated = false
    self.forceRegions:clear()
    self.damageSources:clear()
    self.damageParts = {}
    BData:clearControls()
    clearAnimation()

    BData:setEntity("self", entity.id())
    BData:setPosition("self", mcontroller.position())
    BData:setNumber("dt", dt * self.behaviorTickRate)
    BData:setNumber("facingDirection", self.facingDirection or mcontroller.facingDirection())

    if self.behavior then
      self.behavior:run(self.behaviorState, dt * self.behaviorTickRate)
    end

    BData:update()
    updateAnimation()

    if not self.rotated and self.rotation then
      mcontroller.setRotation(0)
      animator.resetTransformationGroup(self.rotationGroup)
      self.rotation = nil
      self.rotationGroup = nil
    end

    self.interacted = false
    self.damaged = false
    self.stunned = false
    self.notifications = {}

    setDamageSources()
    setPhysicsForces()
    monster.setDamageParts(self.damageParts)
    overrideCollisionPoly()

  end
  self.behaviorTick = self.behaviorTick + 1

  movement()

  if config.getParameter("parent") and not world.entityExists(config.getParameter("parent")) then
    status.setResource("health", 0)
  end

end

function interact(args)
  self.interacted = true
  BData:setEntity("interactionSource", args.sourceId)
end

function shouldDie()
  return (self.shouldDie and status.resource("health") <= 0) or capturable.justCaptured
end

function die()
  if not capturable.justCaptured then
    if self.deathBehavior then
      local deathBehaviorState = self.deathBehavior:init(_ENV)
      self.deathBehavior:run(deathBehaviorState, script.updateDt())
    end
    capturable.die()
  end
  spawnDrops()
end

function uninit()
end

function setDamageSources()
  local partSources = {}
  for part,ds in pairs(config.getParameter("damageParts", {})) do
    local damageArea = animator.partPoly(part, "damageArea")
    if damageArea then
      ds.poly = damageArea
      table.insert(partSources, ds)
    end
  end

  local damageSources = util.mergeLists(partSources, self.damageSources:values())
  damageSources = util.map(damageSources, function(ds)
    ds.damage = ds.damage * root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * status.stat("powerMultiplier")
    if ds.knockback and type(ds.knockback) == "table" then
      ds.knockback[1] = ds.knockback[1] * mcontroller.facingDirection()
    end

    local team = entity.damageTeam()
    ds.team = { type = ds.damageTeamType or team.type, team = ds.damageTeam or team.team }

    return ds
  end)
  monster.setDamageSources(damageSources)
end

function setPhysicsForces()
  local regions = util.map(self.forceRegions:values(), function(region)
    if region.type == "RadialForceRegion" then
      region.center = vec2.add(mcontroller.position(), region.center)
    elseif region.type == "DirectionalForceRegion" then
      if region.rectRegion then
        region.rectRegion = rect.translate(region.rectRegion, mcontroller.position())
        util.debugRect(region.rectRegion, "blue")
      elseif region.polyRegion then
        region.polyRegion = poly.translate(region.polyRegion, mcontroller.position())
      end
    end

    return region
  end)

  monster.setPhysicsForces(regions)
end

function overrideCollisionPoly()
  local collisionParts = config.getParameter("collisionParts", {})

  for _,part in pairs(collisionParts) do
    local collisionPoly = animator.partPoly(part, "collisionPoly")
    if collisionPoly then
      -- Animator flips the polygon by default
      -- to have it unflipped we need to flip it again
      if not config.getParameter("flipPartPoly", true) and mcontroller.facingDirection() < 0 then
        collisionPoly = poly.flip(collisionPoly)
      end
      mcontroller.controlParameters({collisionPoly = collisionPoly, standingPoly = collisionPoly, crouchingPoly = collisionPoly})
      break
    end
  end
end

function setupTenant(...)
  require("/scripts/tenant.lua")
  tenant.setHome(...)
end
