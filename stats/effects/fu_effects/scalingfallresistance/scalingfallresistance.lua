function init()
	self.minMod=config.getParameter("minMod",0.0)--value at speedmin
	self.maxMod=config.getParameter("maxMod",1.0)--value at speedmax
	self.speedMax=config.getParameter("speedMax")--upper bound of speed. note that this is to be mathematically greater than speedmin.
	self.speedMin=config.getParameter("speedMin")--lower bound of speed
	local yD=self.maxMod-self.minMod
	local xD=self.speedMax-self.speedMin
	self.slope=yD/xD--this is the power of algebra...designating a range of inputs and mapping it to a range of outputs.
	handler=effect.addStatModifierGroup({})
end

function update(dt)
	local liquidId=mcontroller.liquidId()--0 if none
	local falling=mcontroller.falling()
	local flying=mcontroller.flying()
	local mult=1.0--starts at 1.0, adds scaled value if in correct falling state.
	if falling and (not flying) and (liquidId==0) then
		mult=math.max(1.0+(self.slope*math.max(self.speedMin, math.min(mcontroller.yVelocity(), self.speedMax))),0.0)--clamps y velocity to speed range, multiplies by slope, adds 1.0, then clamps to positive range.
	end
	effect.setStatModifierGroup(handler,{{stat="fallDamageMultiplier",effectiveMultiplier=mult}})
end

function uninit()
	if handler then effect.removeStatModifierGroup(handler)
		handler=nil
	end
end