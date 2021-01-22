require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.healingRate = config.getParameter("healAmount", -30) / effect.duration()
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
end
