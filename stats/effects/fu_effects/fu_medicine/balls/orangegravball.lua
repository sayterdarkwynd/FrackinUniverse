require "/scripts/util.lua"
require "/scripts/effectUtil.lua"

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
	effectUtil.effectAllInRange("orangegravrainHiddenNoBlock",range,effect.duration())
	effectUtil.effectAllInRange("staffslow2",range,effect.duration())
end