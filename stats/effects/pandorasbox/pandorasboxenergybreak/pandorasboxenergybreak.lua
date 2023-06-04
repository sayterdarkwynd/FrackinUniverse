require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
end

function update(dt)
if status.overConsumeResource("energy", 0) then
   status.setResourceLocked("energy", true);
   status.setResourcePercentage("energy", 0);
   effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", effectiveMultiplier = 0},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
    })
    end
end
