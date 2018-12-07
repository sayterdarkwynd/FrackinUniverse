require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/rect.lua"

function init()
  self.beamDirections = config.getParameter("beamDirections", {
    {0,1},
    {1,0},
    {0,-1},
    {-1,0}
  })
  self.maxLength = config.getParameter("maxBeamLength", 50)
  self.startOffset = config.getParameter("beamStartOffsets", {
    {0,0},
    {0,0},
    {0,0},
    {0,0}
  })
  self.startPosition = {}
  self.endPosition = {}
  for i=1, 4 do
    self.beamDirections[i] = vec2.norm(self.beamDirections[i])
    self.startPosition[i] = vec2.add(self.startOffset[i], entity.position())
    self.endPosition[i] = nil
  end
  if storage.active == nil then
    storage.active = false
  end

  self.rotationSpeed = config.getParameter("rotationSpeed", 0)
  self.rotationOffset = config.getParameter("rotationOffset", {0,0})
  if object.direction() == -1 then self.rotationSpeed = -self.rotationSpeed end

  sb.logInfo("direction %s",object.direction())
  sb.logInfo("rotationSpeed %s",self.rotationSpeed)

  findEnd()

  animator.setAnimationState("trapState", "off")
  object.setSoundEffectEnabled(false)
  object.setLightColor(config.getParameter("inactiveLightColor", {0, 0, 0, 0}))
  object.setAnimationParameter("beams", {})

  script.setUpdateDelta(5)

  self.startProjectile = {}
  self.endProjectile = {}

  self.state = FSM:new()
  self.state:set(offState)
end

function update()
  storage.active = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
  if storage.active then
    if object.direction() == -1 then --shrug
      animator.rotateTransformationGroup("body", -self.rotationSpeed, self.rotationOffset)
    else
      animator.rotateTransformationGroup("body", self.rotationSpeed, self.rotationOffset)
    end
    for i=1, 4 do
      self.beamDirections[i]=vec2.rotate(self.beamDirections[i],self.rotationSpeed)
      self.startOffset[i]=vec2.rotate(self.startOffset[i],self.rotationSpeed)
      self.startPosition[i]=vec2.add(self.startOffset[i],entity.position())
    end
  end

  findEnd()

  self.state:update()
end

function projectileStart(index)
  local bounds = {0, 0, 0, 0}
  for _,space in pairs(object.spaces()) do
    bounds = {
      math.min(bounds[1], space[1]),
      math.min(bounds[2], space[2]),
      math.max(bounds[3], space[1] + 1),
      math.max(bounds[4], space[2] +1)
    }
  end
  return rect.snap(bounds, self.startOffset[index], self.beamDirections[index])
end

function findEnd()
  for i=1, 4 do
    self.endPosition[i] = vec2.add(self.startPosition[i], vec2.mul(self.beamDirections[i], self.maxLength))
    local lineStart = vec2.add(self.startPosition[i], vec2.mul(self.beamDirections[i], 1.5))
    self.endPosition[i] = world.lineCollision(lineStart, self.endPosition[i]) or self.endPosition[i]
  end
end

function setBeamDamage(startProjectile, endProjectile)
  local damageSources = {}
  local beams = {}

  for i=1, 4 do
    local beamStart = self.startPosition[i]
    if startProjectile and startProjectile[i] then
      beamStart = world.entityPosition(startProjectile[i]) or beamStart
    end
    local beamEnd = self.endPosition[i]
    if endProjectile and endProjectile[i] then
      beamEnd = world.entityPosition(endProjectile[i]) or beamEnd
    end

    local length = world.magnitude(beamEnd, beamStart)
    local angle = vec2.angle(world.distance(beamEnd, beamStart))
    local damagePoly = {{0, -0.5}, {0, 0.5}, {length, 0.5}, {length, -0.5}}
    damagePoly = poly.translate(poly.rotate(damagePoly, angle), beamStart)

    local damageSource = config.getParameter("beamDamage")
    damageSource.poly = poly.translate(damagePoly, vec2.mul(entity.position(), -1))
    if damageSource.knockback and type(damageSource.knockback) == "table" then
      damageSource.knockback = vec2.mul(damageSource.knockback, {object.direction(), 1})
    end

    table.insert(damageSources,damageSource)
    if startproject and endproject then
      table.insert(beams,{
        startPosition = self.startPosition[i],
        endPosition = self.endPosition[i],
        startProjectile = startProjectile[i],
        endProjectile = endProjectile[i]
      })
    elseif startprojectile then
      table.insert(beams,{
        startPosition = self.startPosition[i],
        endPosition = self.endPosition[i],
        startProjectile = startProjectile[i],
        endProjectile = nil
      })
    elseif endProjectile then
      table.insert(beams,{
        startPosition = self.startPosition[i],
        endPosition = self.endPosition[i],
        startProjectile = nil,
        endProjectile = endProjectile[i]
      })
    else
      table.insert(beams,{
        startPosition = self.startPosition[i],
        endPosition = self.endPosition[i],
        startProjectile = nil,
        endProjectile = nil
      })
    end
  end

  object.setDamageSources(damageSources)
  object.setAnimationParameter("beams", beams)
end

function setActive(active)
  if active then
    animator.setAnimationState("trapState", "on")
    object.setSoundEffectEnabled(true)
    animator.playSound("on")
    object.setLightColor(config.getParameter("activeLightColor", {0, 0, 0, 0}))
  else
    animator.setAnimationState("trapState", "off")
    object.setSoundEffectEnabled(false)
    animator.playSound("off")
    object.setLightColor(config.getParameter("inactiveLightColor", {0, 0, 0, 0}))
  end
end

function offState()
  object.setDamageSources({})
  object.setAnimationParameter("beams", {})

  while not storage.active do
    coroutine.yield()
  end

  self.state:set(startState)
end

function startState()
  setActive(true)
  object.setAnimationParameter("requireProjectile", false)

  local speed = config.getParameter("beamSpeed", 40)
  local length = {}
  local params = {}
  for i=1, 4 do
    local projectileOffset = projectileStart(i)
    length[i] = world.magnitude(self.endPosition[i], vec2.add(entity.position(), projectileOffset))
    params[i] = {
      physics = "laser",
      speed = speed,
      timeToLive = length[i] / speed,
      onlyHitTerrain = true
    }
    self.endProjectile[i] = world.spawnProjectile("invisibleprojectile", vec2.add(entity.position(), projectileOffset), entity.id(), self.beamDirections[i], false, params[i])
  end
  while world.entityExists(self.endProjectile[1]) and storage.active do
    setBeamDamage(nil, self.endProjectile)
    coroutine.yield()
  end

  for i=1, 4 do
    if not world.entityExists(self.endProjectile[i]) then
      self.endProjectile[i] = nil
    end
  end

  self.state:set(onState)
end

function onState()
  while storage.active do
    setBeamDamage(nil, nil)
    coroutine.yield()
  end

  self.state:set(stopState)
end

function stopState()
  setActive(false)
  object.setAnimationParameter("requireProjectile", false)

  local speed = config.getParameter("beamSpeed", 40)
  local length = {}
  local params = {}
  for i=1, 4 do
    local projectileOffset = projectileStart(i)
    length[i] = world.magnitude(self.endPosition[i], vec2.add(entity.position(), projectileOffset))
    params[i] = {
      physics = "laser",
      speed = speed,
      timeToLive = length[i] / speed,
      onlyHitTerrain = true
    }
    self.startProjectile[i] = world.spawnProjectile("invisibleprojectile", vec2.add(entity.position(), projectileOffset), entity.id(), self.beamDirections[i], false, params[i])
  end
  while world.entityExists(self.startProjectile[1]) and storage.active do
    setBeamDamage(self.startProjectile, self.endProjectile)
    coroutine.yield()
  end

  for i=1, 4 do
    if not world.entityExists(self.startProjectile[i]) then
      self.endProjectile[i] = nil
    end
  end

  self.state:set(offState)
end
