require "/scripts/vec2.lua"

function drawLightning(startLine, endLine, displacement, minDisplacement, forks, forkAngleRange, width, color)
  if displacement < minDisplacement then
    local position = startLine
    endLine = vec2.sub(endLine, startLine)
    startLine = {0,0}
    localAnimator.addDrawable({line = {startLine, endLine}, width = width, color = color, position = position, fullbright = true})
  else
    local mid = {(startLine[1] + endLine[1]) / 2, (startLine[2] + endLine[2]) / 2}
    mid = vec2.add(mid, randomOffset(displacement))
    drawLightning(startLine, mid, displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color)
    drawLightning(mid, endLine, displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color)

    if forks > 0 then
      local direction = vec2.sub(mid, startLine)
      local length = vec2.mag(direction) / 2
      local angle = math.atan(direction[2], direction[1]) + randomInRange(forkAngleRange)
      forkEnd = vec2.mul({math.cos(angle), math.sin(angle)}, length)
      drawLightning(mid, vec2.add(mid, forkEnd), displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color)
    end
  end
end

function randomInRange(range)
  return -range + math.random() * 2 * range
end

function randomOffset(range)
  return {randomInRange(range), randomInRange(range)}
end

function update()
  localAnimator.clearDrawables()

  local tickRate = animationConfig.animationParameter("lightningTickRate") or 25

  local lightningSeed = animationConfig.animationParameter("lightningSeed")
  if not lightningSeed then
    local millis = math.floor((os.time() + (os.clock() % 1)) * 1000)
    lightningSeed = math.floor(millis / tickRate)
  end
  math.randomseed(lightningSeed)

  local getLinePosition = function(bolt, positionType)
    return bolt["world"..positionType.."Position"]
      or (bolt["item"..positionType.."Position"] and vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(bolt["item"..positionType.."Position"])))
      or (bolt["part"..positionType.."Position"] and vec2.add(activeItemAnimation.ownerPosition(),
        activeItemAnimation.handPosition(animationConfig.partPoint(bolt["part"..positionType.."Position"][1], bolt["part"..positionType.."Position"][2]))))
  end

  --First bolt
  local lightningBolts = animationConfig.animationParameter("lightning")
  if lightningBolts then
    for _, bolt in pairs(lightningBolts) do
      local startPosition = getLinePosition(bolt, "Start")
      local endPosition = getLinePosition(bolt, "End")
      endPosition = vec2.add(startPosition, world.distance(endPosition, startPosition))
      if bolt.endPointDisplacement then
        endPosition = vec2.add(endPosition, randomOffset(bolt.endPointDisplacement))
      end
      drawLightning(startPosition, endPosition, bolt.displacement, bolt.minDisplacement, bolt.forks, bolt.forkAngleRange, bolt.width, bolt.color)
    end
  end

  --Second bolt
  local lightningBolts2 = animationConfig.animationParameter("lightning2")
  if lightningBolts2 then
    for _, bolt in pairs(lightningBolts2) do
      local startPosition = getLinePosition(bolt, "Start")
      local endPosition = getLinePosition(bolt, "End")
      endPosition = vec2.add(startPosition, world.distance(endPosition, startPosition))
      if bolt.endPointDisplacement then
        endPosition = vec2.add(endPosition, randomOffset(bolt.endPointDisplacement))
      end
      drawLightning(startPosition, endPosition, bolt.displacement, bolt.minDisplacement, bolt.forks, bolt.forkAngleRange, bolt.width, bolt.color)
    end
  end
end
