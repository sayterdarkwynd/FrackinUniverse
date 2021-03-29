require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/rect.lua"

--Tactical planner script for NPC Combat
function npcCombat(dt)
  if not world.entityExists(self.goal) then
    self.success = true
    return
  end
  local entityPosition = world.entityPosition(self.goal)
  self.groupResources:set("targetPosition", entityPosition)

  if not self.npcBounds or not self.npcPoly then
    if self.group.members[1] then
      self.npcBounds = world.callScriptedEntity(self.group.members[1], "mcontroller.boundBox")
      self.npcPoly = world.callScriptedEntity(self.group.members[1], "mcontroller.collisionPoly")
    end
  end

  setMeleeAttackerPositions()
  setRangedAttackerPositions()
end

function rangedWeaponRanges(npcId, ranged)
  local item = world.entityHandItem(npcId, "primary")
  local gunRanges = config.getParameter("npcCombat.rangedWeaponRanges")
  return gunRanges[item] or gunRanges.default
end

function meleeWeaponRanges(npcId, ranged)
  local item = world.entityHandItem(npcId, "primary")
  local weaponRanges = config.getParameter("npcCombat.meleeWeaponRanges")
  return weaponRanges[item] or weaponRanges.default
end

--Sets attack positions for all melee attackers
function setMeleeAttackerPositions()
  if self.tasks["melee"] and #self.tasks["melee"].members > 0 then
    local usedPositions = {}
    local targetPosition = world.entityPosition(self.goal)

    local memberRanges = util.map(self.tasks["melee"].members, function(memberId)
      local ranges = meleeWeaponRanges(memberId)      
      self.memberResources[memberId]:set("maxRange", ranges.maxRange + 1)
      return {memberId, ranges}
    end)

    table.sort(memberRanges, function(a,b) return a[2].maxRange > b[2].maxRange end)
    local maxRange = memberRanges[1][2].maxRange
    table.sort(memberRanges, function(a,b) return a[2].minRange < b[2].minRange end)
    local minRange = memberRanges[1][2].minRange

    local validPositions = attackPositionsAlongGround(minRange, maxRange, targetPosition)
    for _,pair in pairs(memberRanges) do
      local npcPosition = world.entityPosition(pair[1])
      table.sort(validPositions, function(a,b)
        local aToTarget = world.magnitude(targetPosition, a)
        local bToTarget = world.magnitude(targetPosition, b)

        -- For two positions at very similar distance to the target, pick the one closest to the npc
        if math.abs(aToTarget - bToTarget) < 0.5 then
          return world.magnitude(npcPosition, a) < world.magnitude(npcPosition, b)
        end

        -- In all other cases, closer to target is better
        return aToTarget < bToTarget
      end)

      local movePosition = util.find(validPositions, function(position)
        local distance = math.abs(world.distance(position, targetPosition)[1])
        if distance > pair[2].maxRange or distance < pair[2].minRange then return false end

        return util.find(usedPositions, function(usedPosition) return world.magnitude(position, usedPosition) < 1 end) == nil
      end)

      table.insert(usedPositions, movePosition)
      self.memberResources[pair[1]]:set("meleePosition", movePosition)
    end
  end
end

--Sets attack positions for all ranged attackers
function setRangedAttackerPositions()
  local targetPosition = world.entityPosition(self.goal)

  if self.tasks["ranged"] then
    local usedPositions = {}

    -- Store gun ranges with ranged attacker IDs
    local memberRanges = util.map(self.tasks["ranged"].members, function(memberId)
      local ranges = rangedWeaponRanges(memberId, true)
      util.debugCircle(world.entityPosition(memberId), ranges.minRange, "red", 50)
      util.debugCircle(world.entityPosition(memberId), ranges.maxRange, "green", 50)
      util.debugCircle(world.entityPosition(memberId), ranges.forceMoveRange, "blue", 50)
      
      self.memberResources[memberId]:set("maxRange", ranges.forceMoveRange)
      self.memberResources[memberId]:set("minRange", ranges.minRange - 1) -- Give some wiggle room on the minimum fire range
      return {memberId, ranges}
    end)

    -- Filter out npcs that are already in a good ranged position
    local needPosition = util.filter(memberRanges, function(pair)
      local positions = {
        self.memberResources[pair[1]]:get("movePosition"),
        world.entityPosition(pair[1])
      }
      for _,position in pairs(positions) do
        local targetDistance = world.magnitude(targetPosition, position)
        if targetDistance < pair[2].forceMoveRange and targetDistance > pair[2].minRange and not world.lineTileCollision(position, targetPosition) then
          table.insert(usedPositions, position)
          self.memberResources[pair[1]]:set("movePosition", position)
          return false
        end
      end
      return true
    end)

    if #needPosition > 0 then
      -- Get biggest and smallest ranges for attackers
      table.sort(needPosition, function(a,b) return a[2].maxRange > b[2].maxRange end)
      local maxRange = needPosition[1][2].maxRange
      table.sort(needPosition, function(a,b) return a[2].minRange < b[2].minRange end)
      local minRange = needPosition[1][2].minRange

      local rangedPositions = attackPositionsInRange(maxRange, minRange, targetPosition)

      -- Find a good position for npcs that need one
      for _,pair in pairs(needPosition) do
        local npcPosition = world.entityPosition(pair[1])
        table.sort(rangedPositions, function(a,b)
          return world.magnitude(a, npcPosition) < world.magnitude(b, npcPosition)
        end)

        -- Get closest open position
        local movePosition = util.find(rangedPositions, function(position)
          local magnitude = world.magnitude(targetPosition, position)
          -- make sure the position is in range
          if magnitude < pair[2].minRange or magnitude > pair[2].maxRange then return false end

          -- If we can't find a close position in the already used positions, it's available
          return util.find(usedPositions, function(used) return world.magnitude(position, used) < 2 end) == nil
        end)
        table.insert(usedPositions, movePosition)
        self.memberResources[pair[1]]:set("movePosition", movePosition)
      end
    end
  end
end

function attackPositionsAlongGround(minRange, maxRange, targetPosition)
  local positions = {}

  for range = math.floor(minRange), math.ceil(maxRange) do
    range = math.max(minRange, math.min(maxRange, range))

    for _,dir in pairs({1,-1}) do
      local groundPosition = findGroundAttackPosition(vec2.add(targetPosition, {dir * range, 0}), -range, range, targetPosition, self.npcBounds)
      if groundPosition then
        world.debugPoint(groundPosition, "green")
        table.insert(positions, groundPosition)
      end
    end
  end

  return positions
end

function attackPositionAlongLine(startLine, endLine)
  local toEnd = world.distance(endLine, startLine)
  local dir = util.toDirection(toEnd[1])

  while toEnd[1] * dir > 0 do
    local groundPosition = findGroundAttackPosition(startLine, -4, 4, endLine, self.npcBounds, self.npcPoly)
    if groundPosition then
      return groundPosition
    end
    startLine[1] = startLine[1] + dir
    toEnd = world.distance(endLine, startLine)
  end

  return endLine
end


function validAttackPosition(position, bounds, avoidLiquid)
  local groundRegion = {
    position[1] + bounds[1], position[2] + bounds[2] - 1,
    position[1] + bounds[3], position[2] + bounds[2]
  }
  if avoidLiquid then
    local liquidLevel = world.liquidAt(rect.translate(bounds, position))
    if liquidLevel and liquidLevel[2] >= 0.1 then
      return false
    end
  end
  
  if not world.rectTileCollision(rect.translate(bounds, position), {"Null", "Block"}) and world.rectTileCollision(groundRegion, {"Null", "Block", "Dynamic", "Platform"}) then
    return true
  else
    return false
  end
end

--Find a valid ground position
function findGroundAttackPosition(position, minHeight, maxHeight, losPosition, bounds)
  position[2] = math.ceil(position[2]) - (bounds[2] % 1)
  for y = maxHeight, minHeight, -1 do
    local testPosition = {position[1], position[2] + y}
    if validAttackPosition(testPosition, bounds) and not world.lineTileCollision(testPosition, losPosition) then
      return testPosition
    end
  end
end

function attackPositionsInRange(maxRange, minRange, center)
  local positions = {}
  local range = maxRange
  while range >= minRange do
    local step = (math.pi / 2) / range
    local maxSteps = math.min(range, 25)
    for i = 0, maxSteps do
      local yStep = (range / maxSteps)
      local y = i * yStep
      local x = range * math.cos(math.asin(i/maxSteps))

      for _,xDir in ipairs({1, -1}) do
        for _,yDir in ipairs({1, -1}) do
          local position = {center[1] + xDir * x, center[2] + yDir * y}
          position[2] = math.ceil(position[2]) - (self.npcBounds[2] % 1)
          if validAttackPosition(position, self.npcBounds, true) and not world.lineTileCollision(position, vec2.add(center, {0, -1})) then
            world.debugPoint(position, "green")
            table.insert(positions, position)
          end
        end
      end
    end

    range = range - 1
  end
  return positions
end
