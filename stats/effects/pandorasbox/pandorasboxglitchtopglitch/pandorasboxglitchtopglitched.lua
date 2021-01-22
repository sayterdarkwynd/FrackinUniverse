require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "pandorasboxglitched1", 1.0)
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "pandorasboxglitched2", 1.0)

	statusEffects = config.getParameter("statusEffects") or {}
	randomStatusEffect = statusEffects[math.random(#statusEffects)]
	effectDuration = effect.duration()
	status.addEphemeralEffects({{effect = randomStatusEffect, duration = effectDuration}, {effect = config.getParameter("blockingStatusEffect"), duration = effectDuration}})
	effect.expire()
	script.setUpdateDelta(0)
end

function update(dt)

end
