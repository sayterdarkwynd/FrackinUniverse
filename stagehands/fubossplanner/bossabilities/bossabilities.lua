require "/stagehands/bossplanner/minions.lua"
require "/scripts/vec2.lua"

function mapAbilityActions(ability, func)
  for k,action in pairs(ability.sequenceActions or {}) do
    if contains(ability.actions, action.name) then
      ability.sequenceActions[k] = func(action)
    end
  end
  return ability
end

function floorPositions(state, spaceConfig)
  local floors = util.filter(state, function(term) return term[1] == "Floor" end)
  floors = util.map(floors, function(term) return {term[2], term[3]} end)
  local positions = util.map(floors, function(space)
    return vec2.add(spaceConfig.origin, vec2.mul(vec2.add(space, {0.5, 0.5}), spaceConfig.size))
  end)
  return positions
end

function platformPositions(state, spaceConfig)
  local floors = util.filter(state, function(term) return term[1] == "Floor" end)
  floors = util.map(floors, function(term) return {term[2], term[3]} end)
  floors = util.filter(floors, function(pos) return pos[2] ~= 0 end)
  local positions = util.map(floors, function(space)
    return vec2.add(spaceConfig.origin, vec2.mul(vec2.add(space, {0.5, 0.5}), spaceConfig.size))
  end)
  return positions
end

-- returns a behavior config with parameters applied from the operation
function minionTriggerGroupHandler(ability, operation, plan, state, spaceConfig)
  local triggerId = minionTriggerId(operation, plan)
  local minionType = util.find(operation.postconditions, function(term) return term[1] == "Minion" end)[2][1]
  ability = mapAbilityActions(ability, function(action)
      if minionType == "kill" then
        action.parameters.spawns = {
          {
            monsterType = "fuguardianminion",
            position = vec2.add({-8, 8}, entity.position()),
            parameters = {
              managerUid = entity.uniqueId(),
              triggerId = triggerId,
              partOfGroup = true
            }
          },
          {
            monsterType = "fuguardianminion",
            position = vec2.add({8, 8}, entity.position()),
            parameters = {
              managerUid = entity.uniqueId(),
              triggerId = triggerId,
              partOfGroup = true
            }
          },
          {
            monsterType = "fuguardianminion",
            position = vec2.add({8, -8}, entity.position()),
            parameters = {
              managerUid = entity.uniqueId(),
              triggerId = triggerId,
              partOfGroup = true
            }
          },
          {
            monsterType = "fuguardianminion",
            position = vec2.add({-8, -8}, entity.position()),
            parameters = {
              managerUid = entity.uniqueId(),
              triggerId = triggerId,
              partOfGroup = true
            }
          }
        }
      elseif minionType == "collide" then
        local positions = floorPositions(state, spaceConfig)
        action.parameters.spawnMin = spaceConfig.origin
        action.parameters.spawnMax = vec2.add(spaceConfig.origin, vec2.mul(spaceConfig.dimensions, spaceConfig.size))
        action.parameters.spawns = {
          {
            monsterType = "collidingminion",
            positions = positions,
            parameters = {
              managerUid = entity.uniqueId(),
              triggerId = triggerId,
              partOfGroup = true
            }
          },
          {
            monsterType = "fuguardianminion",
            parameters = {
              managerUid = entity.uniqueId(),
              partOfGroup = true
            }
          }
        }
      end
      return action
    end)
  return ability
end

function groundDashConfig(ability, operation, plan, state, spaceConfig)
  local bigNumber = 999999
  local leftPoint = {bigNumber, bigNumber}
  local rightPoint = {0, bigNumber}
  for _,term in pairs(operation.statemodifiers) do
    if term[1] == "Danger" then
      local x = term[2]
      local y = term[3]
      if x < leftPoint[1] then leftPoint[1] = x end
      if y < leftPoint[2] then leftPoint[2] = y end
      if x > rightPoint[1] then rightPoint[1] = x end
      if y < rightPoint[2] then rightPoint[2] = y end
    end
  end
  -- set positions to center of the spaces in world space
  leftPoint = vec2.add(spaceConfig.origin, vec2.mul(vec2.add(leftPoint, {0.5, 0.5}), spaceConfig.size))
  rightPoint = vec2.add(spaceConfig.origin, vec2.mul(vec2.add(rightPoint, {0.5, 0.5}), spaceConfig.size))

  ability = mapAbilityActions(ability, function(action)
      action.parameters.firstPosition = leftPoint
      action.parameters.secondPosition = rightPoint
      return action
    end)
  return ability
end

function pogoBeamHandler(ability, operation, plan, state, spaceConfig)
  local bigNumber = 999
  local leftPoint = {bigNumber, bigNumber}
  local rightPoint = {0, bigNumber}
  for _,term in pairs(operation.statemodifiers) do
    if term[1] == "Boss" then
      local x = term[2]
      local y = term[3]
      if x < leftPoint[1] then leftPoint[1] = x end
      if y < leftPoint[2] then leftPoint[2] = y end
      if x > rightPoint[1] then rightPoint[1] = x end
      if y < rightPoint[2] then rightPoint[2] = y end
    end
  end
  -- set positions to center of the spaces in world space
  leftPoint = vec2.add(spaceConfig.origin, vec2.mul(vec2.add(leftPoint, {0.5, 0.5}), spaceConfig.size))
  rightPoint = vec2.add(spaceConfig.origin, vec2.mul(vec2.add(rightPoint, {0.5, 0.5}), spaceConfig.size))

  ability = mapAbilityActions(ability, function(action)
      action.parameters.firstPosition = leftPoint
      action.parameters.secondPosition = rightPoint
      return action
    end)
  return ability
end

function groundHazardConfig(ability, operation, plan, state, spaceConfig)
  ability = mapAbilityActions(ability, function(action)
      action.parameters.segmentWidth = spaceConfig.size[1]
      action.parameters.areaWidth = spaceConfig.size[1] * spaceConfig.dimensions[1]
      action.parameters.projectileCount = spaceConfig.dimensions[1]
      action.parameters.center = vec2.add(spaceConfig.origin, vec2.mul({spaceConfig.dimensions[1] / 2, 1}, spaceConfig.size))
      action.parameters.projectileType = action.parameters.projectileType:gsub("<element>", storage.elementalType)
      return action
    end)
  return ability
end

function doubleGroundBeamConfig(ability, operation, plan, state, spaceConfig)
  local leftPosition = vec2.add(spaceConfig.origin, vec2.mul({0.5, 1}, spaceConfig.size))
  local rightPosition = vec2.add(spaceConfig.origin, vec2.mul({spaceConfig.dimensions[1] - 0.5, 1}, spaceConfig.size))
  ability = mapAbilityActions(ability, function(action)
      action.parameters.leftPosition = leftPosition
      action.parameters.rightPosition = rightPosition
      return action
    end)
  return ability
end

function targetedProjectileHandler(ability, operation, plan, state, spaceConfig)
  self.rand = self.rand or sb.makeRandomSource(storage.seed)
  ability = mapAbilityActions(ability, function(action)
    local names = util.keys(ability.projectileConfig)
    table.sort(names) -- need deterministic order, json objects are unordererd
    local projectileName = names[self.rand:randUInt(1, #names)]
    local projectileConfig = ability.projectileConfig[projectileName]
    local params = copy(action.parameters.projectileParameters)
    local count = projectileConfig.count
    local windup = ability.windup
    params.speed = projectileConfig.speed

    local fuzzAim = function(amount)
      if action.parameters.fixedDistance then
        action.parameters.fuzzAimPosition = action.parameters.fuzzAimPosition + amount
      else
        action.parameters.fuzzAngle = action.parameters.fuzzAngle + (amount * ability.angleFuzzMultiplier)
      end
    end

    if self.rand:randf() < ability.explosiveChance then
      construct(params, "actionOnReap")
      local explosion = string.gsub(projectileConfig.explosion, "<element>", storage.elementalType)
      table.insert(params.actionOnReap, {action = "config", file = explosion})
      count = projectileConfig.explosiveCount
      params.speed = params.speed * ability.explosiveSpeedMultiplier

      fuzzAim(2)
      if self.rand:randf() < ability.fixedDistanceChance then
        action.parameters.fixedDistance = true
        action.parameters.fuzzSpeed = 0
      else
        fuzzAim(2)
      end
    end

    fuzzAim(ability.baseAimFuzz)
    action.parameters.outerRepeat = 1
    if self.rand:randf() < ability.outerRepeatChance then
      fuzzAim(-ability.baseAimFuzz * 0.7)
      action.parameters.outerRepeat = self.rand:randUInt(ability.outerRepeat[1], ability.outerRepeat[2])
      count = math.ceil(count / action.parameters.outerRepeat)
      action.parameters.outerInterval = ability.outerRepeatTime / action.parameters.outerRepeat
      action.parameters.trackOuter = true

      if action.parameters.fixedDistance then
        windup = windup + ability.fixedDistanceWindupModifier
      end
    end

    if self.rand:randf() < ability.innerRepeatChance then
      fuzzAim(-ability.baseAimFuzz * 0.3)
      action.parameters.innerRepeat = count
      count = 1
      action.parameters.innerInterval = ability.innerRepeatTime / action.parameters.innerRepeat

      action.parameters.trackInner = self.rand:randf() < ability.trackInnerChance
      if action.parameters.trackInner then
        if action.parameters.outerRepeat == 1 then
          action.parameters.innerInterval = ability.outerRepeatTime / action.parameters.innerRepeat
          action.parameters.trackOuter = true
          fuzzAim(ability.baseAimFuzz / -2)
        end
      else
        fuzzAim(ability.baseAimFuzz / 2)
      end
    end

    if count > 1 then
      action.parameters.fireSound = "burstFire"
    else
      action.parameters.fireSound = "rapidFire"
    end

    action.parameters.windup = windup
    action.parameters.projectileCount = count
    action.parameters.projectileParameters = params
    action.parameters.projectileType = string.gsub(projectileName, "<element>", storage.elementalType)
    return action
  end)
  return ability
end

function spawnMinionGroupHandler(ability, operation, plan, state, spaceConfig)
  self.rand = self.rand or sb.makeRandomSource(storage.seed)
  local platforms = platformPositions(state, spaceConfig)
  while #platforms < 4 do
    local spaces = {{self.rand:randUInt(0, spaceConfig.dimensions[1] - 1), self.rand:randUInt(1, spaceConfig.dimensions[2] - 1)}}
    spaces[2] = {spaceConfig.dimensions[1] - 1 - spaces[1][1], spaces[1][2]} -- symmetry
    for _,space in pairs(spaces) do
      table.insert(platforms, vec2.add(spaceConfig.origin, vec2.mul(vec2.add(space, {0.5, 0.5}), spaceConfig.size)))
    end
  end

  local rangedAttack = ability.rangedAttack
  local attackConfig = {
    fixedDistance = false,
    trackTarget = false,
    fireCount = 1
  }

  local names = util.keys(rangedAttack.projectileTypes)
  table.sort(names) -- need deterministic order, json objects are unordererd
  attackConfig.projectileType = names[self.rand:randUInt(1, #names)]
  local projectileConfig = rangedAttack.projectileTypes[attackConfig.projectileType]
  local count = projectileConfig.count

  attackConfig.projectileParameters = {}
  if self.rand:randf() < rangedAttack.explosiveChance then
    attackConfig.projectileParameters.actionOnReap = {
      {action = "config", file = projectileConfig.explosion:gsub("<element>", storage.elementalType)}
    }
    attackConfig.fixedDistance = true
    count = projectileConfig.explosiveCount
  end
  attackConfig.burstCount = count
  attackConfig.projectileParameters.power = rangedAttack.power

  if self.rand:randf() < rangedAttack.repeatChance then
    attackConfig.fireCount = count
    attackConfig.fireInterval = rangedAttack.fireInterval
    attackConfig.burstCount = 1
    if self.rand:randf() < rangedAttack.trackChance then
      attackConfig.fireInterval = rangedAttack.trackFireInterval
      attackConfig.trackTarget = true
    end
  end

  if attackConfig.fireCount == 1 and attackConfig.fixedDistance then
    attackConfig.fuzzAimPosition = projectileConfig.explosiveSpread
  end

  if attackConfig.burstCount > 1 and not attackConfig.fixedDistance then
    attackConfig.fuzzAngle = rangedAttack.burstFuzzAngle
    attackConfig.fuzzSpeed = rangedAttack.burstFuzzSpeed
  end

  attackConfig.projectileType = attackConfig.projectileType:gsub("<element>", storage.elementalType)
  attackConfig.cooldown = rangedAttack.cooldown

  ability = mapAbilityActions(ability, function(action)
      action.parameters.spawnMin = spaceConfig.origin
      action.parameters.spawnMax = vec2.add(spaceConfig.origin, vec2.mul(spaceConfig.dimensions, spaceConfig.size))
      action.parameters.spawns = {
        {
          monsterType = string.format("%srangedminion", storage.elementalType),
          positions = platforms,
          parameters = {
            managerUid = entity.uniqueId(),
            attack = attackConfig,
            partOfGroup = true
          }
        },
        {
          monsterType = string.format("%srangedminion", storage.elementalType),
          positions = platforms,
          parameters = {
            managerUid = entity.uniqueId(),
            attack = attackConfig,
            partOfGroup = true
          }
        }
      }
      return action
    end)
  return ability
end

function bumpersHandler(ability, operation, plan, state, spaceConfig)
  local platforms = platformPositions(state, spaceConfig)
  local center = spaceConfig.origin[1] + (spaceConfig.dimensions[1] * 0.5 * spaceConfig.size[1])
  local positions = {}
  for _,pos in pairs(platforms) do
    positions[pos[2]] = true
  end
  positions = util.keys(positions)
  local positions = util.map(positions, function(y) return {center, y} end)
  ability = mapAbilityActions(ability, function(action)
      action.parameters.positions = positions
      action.parameters.projectileType = ability.projectileType:gsub("<element>", storage.elementalType)
      return action
    end)
  return ability
end

function projectileCircleHandler(ability, operation, plan, state, spaceConfig)
  self.rand = self.rand or sb.makeRandomSource(storage.seed)
  ability = mapAbilityActions(ability, function(action)
    local names = util.keys(ability.projectileConfig)
    table.sort(names) -- need deterministic order, json objects are unordererd
    local projectileName = names[self.rand:randUInt(1, #names)]
    local projectileConfig = ability.projectileConfig[projectileName]

    local params = copy(action.parameters.projectileParameters)
    params.speed = projectileConfig.speed
    params.actionOnReap = {}
    local explosion = string.gsub(projectileConfig.explosion, "<element>", storage.elementalType)
    table.insert(params.actionOnReap, {action = "config", file = explosion})

    local repeatCount = ability.repeatCount
    local burst = projectileConfig.count / repeatCount

    action.parameters.fuzzAimPosition = (action.parameters.outerRange - action.parameters.innerRange) / 2 - (projectileConfig.radius)
    action.parameters.interval = action.parameters.duration / repeatCount
    action.parameters.projectileCount = burst
    action.parameters.projectileParameters = params
    action.parameters.projectileType = string.gsub(projectileName, "<element>", storage.elementalType)
    return action
  end)
  return ability
end
