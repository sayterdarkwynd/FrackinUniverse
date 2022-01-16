require "/scripts/behavior.lua"
require "/scripts/pathing.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

-- Engine callback - called on initialization of entity
function init()
  self.pathing = {}

  self.shouldDie = true
  self.notifications = {}
  if storage.spawnPosition == nil then
    local position = mcontroller.position()
    local groundSpawnPosition
    if mcontroller.baseParameters().gravityEnabled then
      groundSpawnPosition = findGroundPosition(position, -20, 3)
    end
    storage.spawnPosition = groundSpawnPosition or position
  end
  BData:setPosition("spawn", storage.spawnPosition)

  self.behavior = BTree:new(config.getParameter("behavior"))

  self.collisionPoly = mcontroller.collisionPoly()

  if animator.hasSound("deathPuff") then
    monster.setDeathSound("deathPuff")
  end
  animator.setLightActive("glow1", true)
  self.debug = true
end

-- Engine callback - called on each update
-- Update frequencey is dependent on update delta
function update(dt)
  if self.behavior:run(dt) ~= "running" then
    self.behavior:reset()
  end

  self.interacted = false
  self.damaged = false
  self.notifications = {}

  mcontroller.controlParameters({
    collisionPoly = self.collisionPoly
  })

  if config.getParameter("lockFacingDirection") then
    mcontroller.controlFace(1)
  end
end

function uninit()
  self.behavior:uninit()
end

-- Engine callback - called on taking damage
function damage(args)
  self.damaged = true
  BData:setEntity("damageSource", args.sourceId)
end

function setupTenant(...)
  require("/scripts/tenant.lua")
  tenant.setHome(...)
end

function suicide(args, output)
  status.setResource("health", 0)
end

function wasDamaged(args, output)
  return self.damaged == true
end

function shouldDie()
  return self.shouldDie and status.resource("health") <= 0
end

function attackNotification(args, output)
  return false
end

-- param type
-- param state
function setAnimationState(args, output)
  args = parseArgs(args, {
    type = "movement",
    state = "idle"
  })

  animator.setAnimationState(args.type, args.state)
  return true
end

function rotatePoly(angle)
  local basePoly = mcontroller.baseParameters().standingPoly
  local newPoly = {}
  for _,point in pairs(basePoly) do
    table.insert(newPoly, vec2.rotate(point, angle))
  end
  self.collisionPoly = newPoly
end

-- param angle
-- param vector
-- param immediate
function rotate(args, output)
  args = parseArgs(args, {
    angle = 0,
    vector = nil,
    immediate = true
  })

  local angle
  while true do
    if args.vector then
      local vector = vec2.norm(BData:getVec2(args.vector))
      if vector == nil then return false end
      angle = math.atan(vector[2], vector[1])
    else
      angle = BData:getNumber(args.angle)
    end
    angle = angle + config.getParameter("rotationOffset", 0)

    animator.rotateGroup("all", angle, args.immediate)
    rotatePoly(animator.currentRotationAngle("all") or 0)

    diff = ((animator.currentRotationAngle("all") - angle) + 3.14) % 6.28 - 3.14
    if math.abs(diff) < 0.02 or args.immediate then break end
    coroutine.yield("running")
  end

  rotatePoly(angle)
  return true
end

-- param emitter
function burstParticleEmitter(args, output)
  args = parseArgs(args, {
    emitter = nil
  })

  if args.emitter == nil then return false end

  animator.burstParticleEmitter(args.emitter)
  return true
end

-- param emitter
-- param active
function setParticleEmitterActive(args, output)
  args = parseArgs(args, {
    active = true
  })
  if args.emitter == nil then return false end

  animator.setParticleEmitterActive(args.emitter, args.active)
  return true
end

-- param sound
function playSound(args, output)
  args = parseArgs(args, {
    sound = nil
  })

  if args.sound == nil then return false end

  animator.playSound(args.sound)
  return true
end

function setLightActive(args, output)
  args = parseArgs(args, {
    light = nil,
    active = true
  })
  if light == nil or active == nil then return false end

  animator.setLightActive(args.light, args.active)
  return true
end

function setDying(args, output)
  args = parseArgs(args, {
    shouldDie = true
  })
  self.shouldDie = args.shouldDie
  return true
end
