local oldInitControlModifier=init
local oldUpdateControlModifier=update

require("/scripts/util.lua")

function init()
	controlModifierValues=config.getParameter("controlModifiers",{})
	if oldInitControlModifier then oldInitControlModifier() end
end

function update(dt)
	mcontroller.controlModifiers(filterModifiers(copy(controlModifierValues)))
	if oldUpdateControlModifier then oldUpdateControlModifier(dt) end
end

function filterModifiers(stuff)
	if (status.statPositive("spikeSphereActive") and 1.0) and stuff["speedModifier"] then stuff["speedModifier"]=1.0 end
	return stuff
end
