require "/stats/effects/fu_statusUtil.lua"

local lightThreshold=30

function init()
	handler=effect.addStatModifierGroup({})
end

function update(dt)
	if not self.checkTimer or self.checkTimer>0.5 then
		doTheThing()
		self.checkTimer=0.0
	else
		self.checkTimer=self.checkTimer+dt
	end
end

function uninit()
	if handler then
		effect.removeStatModifierGroup(handler)
		handler=nil
	end
end

function doTheThing()
	if true or undergroundCheck() or (getLight() < lightThreshold) then
		effect.setStatModifierGroup(handler,{{stat="fuLeechPercent",amount=0.1}})
	else
		effect.setStatModifierGroup(handler,{})
	end
end