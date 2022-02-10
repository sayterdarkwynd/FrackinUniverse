-- Iterates over a list of patterns to see if someone match, returns the matched pattern or false
function checkPatterns(patterns)
  for _, v in ipairs(patterns) do
    local pattern = root.assetJson(v)
    if checkPattern(pattern) then
      return pattern
    end
  end
  return false
end

-- Check if the pattern is mathched, using as starting point "self.position - pattern.offset"
function checkPattern(pattern)
  local initialPos = vec2.add(self.position, {-pattern.offset[1] - 1, -pattern.offset[2] - 1})
  for y, layer in pairs(pattern.layoutTable) do
		for x, expectedId in pairs(layer) do
      local tileToTest = vec2.add(initialPos, {x, y})
      local foundMaterial = world.material(tileToTest,'foreground')
      local expectedMaterial = pattern.blocksTable[expectedId]
      if foundMaterial ~= expectedMaterial then
        sb.logInfo("Pattern '%s' not matched.", pattern.name)
        sb.logInfo("At x=%s y=%s", x, y)
        sb.logInfo("Expected: %s , Found : %s", expectedMaterial, foundMaterial)
        return false
      end
    end
  end
  sb.logInfo("Pattern '%s' matched.", pattern.name)
  return true
end

-- Destroys all the tiles in the area specified in "pattern.offset" starting at "self.position - pattern.offset"
function clearPatternArea(pattern)
  local initialPos = vec2.add(self.position, {-pattern.offset[1] - 1, -pattern.offset[2] - 1})
  for y, layer in pairs(pattern.layoutTable) do
    for x in pairs(layer) do
      local tileToDestroy = vec2.add(initialPos, {x, y})
      world.damageTiles({tileToDestroy}, "foreground", tileToDestroy, "blockish", 10000, 0)
    end
  end
end
