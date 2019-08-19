require "/scripts/vec2.lua"
require "/scripts/golemancer/gol_patternManager.lua"
require "/scripts/golemancer/gol_resourceManager.lua"
require "/scripts/golemancer/gol_spawnManager.lua"

function init()
  object.setInteractive(true)
  self.patterns = config.getParameter("patterns")
  self.matchedPattern = false
  self.position = object.position()

  self.tickTime = config.getParameter("scriptDelta") or 1.0
  self.tickTimer = self.tickTime

  self.consumedTable = {}
end

function update(dt)
  if self.matchedPattern then
    self.tickTimer = self.tickTimer - dt
    if self.tickTimer <= 0 then
      self.tickTimer = self.tickTime
      if consumeResources(self.matchedPattern) == "allConsumed" then
        clearPatternArea(self.matchedPattern)
        spawn(self.matchedPattern)
        self.matchedPattern = false
      end
    end
  else
    self.consumedErchius = 0
  end
end

function onInteraction(args)
  self.matchedPattern = checkPatterns(self.patterns)
end

function uninit()

end
