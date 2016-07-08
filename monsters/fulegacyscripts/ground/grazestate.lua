grazeState = {
  searchDistance = 3,
  rotationOffset = { -1, -0.5 },
  targetOffset = { 0.5, 0.9 },

  headRotationFrequency = 2,
  headRotationAmplitude = 5,

  grazeTime = 10,
  maxMoveTime = 4,

  cooldown = 10,
}

function grazeState.enter()
  if isCaptive() or hasTarget() then return nil end

  local grazePosition = grazeState.findGrassPosition()
  if grazePosition == nil then return nil end

  return {
    moveTimer = 0,
    grazeTimer = 0,
    grazePosition = grazePosition
  }
end

function grazeState.update(dt, stateData)
  if hasTarget() then return true, grazeState.cooldown end

  local bounds = config.getParameter("metaBoundBox")
  local toTarget = world.distance(stateData.grazePosition, self.position)
  if world.magnitude(toTarget) < math.max(math.abs(bounds[1]), bounds[3]) then
    local pivotPosition = vec2.add(self.position, grazeState.rotationOffset)
    local toGrass = vec2.sub(stateData.grazePosition, pivotPosition)
    local angle = -vec2.angle(toGrass)

    local amplitude = grazeState.headRotationAmplitude * math.pi / 180
    angle = angle + amplitude * math.sin(stateData.grazeTimer * grazeState.headRotationFrequency)

    animator.rotateGroup("projectileAim", angle)

    move({ 0, 0 }, false)

    stateData.grazeTimer = stateData.grazeTimer + dt
    if stateData.grazeTimer > grazeState.grazeTime then
      return true, grazeState.cooldown
    end
  else
    move(toTarget, false)

    stateData.moveTimer = stateData.moveTimer + dt
    if stateData.moveTimer > grazeState.maxMoveTime then
      return true, grazeState.cooldown
    end
  end

  return false
end

function grazeState.leavingState(stateData)
  animator.rotateGroup("projectileAim", 0)
end

function grazeState.findGrassPosition()
  local tilePosition = {
    math.floor(self.position[1] + 0.5),
    math.floor(self.position[2] + 0.5)
  }

  local bounds = config.getParameter("metaBoundBox")
  for offset = 0, grazeState.searchDistance do
    local targetPosition = vec2.add({ bounds[1] - offset, bounds[2] }, tilePosition)
    if grazeState.tileHasGrassMod(targetPosition) then
      return vec2.add(targetPosition, grazeState.targetOffset)
    end

    local targetPosition = vec2.add({ bounds[3] + offset, bounds[2] }, tilePosition)
    if grazeState.tileHasGrassMod(targetPosition) then
      return vec2.add(targetPosition, grazeState.targetOffset)
    end
  end

  return nil
end

function grazeState.tileHasGrassMod(tilePosition)
  local modName = world.mod(tilePosition, "foreground")
  return modName ~= nil and string.find(modName, "grass")
end
