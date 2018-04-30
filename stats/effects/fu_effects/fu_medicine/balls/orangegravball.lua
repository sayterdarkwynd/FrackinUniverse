require "/scripts/util.lua"
require "/stats/effects/effectUtil.lua"

function init()
	range=config.getParameter("range",200)
end

function update(dt)
	if not deltaTime or deltaTime > 1.0 then
		deltaTime=0.0
		pulse()
	else
		deltaTime=deltaTime+dt
	end
end

function pulse()
	effectUtil.effectAllInRange(range,"orangegravrainHiddenNoBlock",effect.duration())
	effectUtil.effectAllInRange(range,"staffslow2",effect.duration())
end