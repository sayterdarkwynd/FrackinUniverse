require "/stats/effects/fu_statusUtil.lua"

local oldInitControlModifier=init
local oldUninitControlModifier=uninit
local oldUpdateControlModifier=update

require("/scripts/util.lua")

function init()
	controlModifierValues=config.getParameter("controlModifiers",{})
	if oldInitControlModifier then oldInitControlModifier() end
end

function update(dt)
	mcontroller.controlModifiers(filterModifiers(controlModifierValues))
	if oldUpdateControlModifier then oldUpdateControlModifier(dt) end
end

function uninit()
	filterModifiers({},true)
	if oldUninitControlModifier then oldUninitControlModifier() end
end
