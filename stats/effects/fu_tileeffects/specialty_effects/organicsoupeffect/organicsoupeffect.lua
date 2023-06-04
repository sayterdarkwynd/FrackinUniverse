function init()
	if status.isResource("food") then
		effect.setParentDirectives("border=1;cc005500;00000000")
		script.setUpdateDelta(3)
	else
		script.setUpdateDelta(0)
	end
end

function update(dt)
	self.tickTimer = (self.tickTimer or 3.0) - dt
	effect.setParentDirectives("fade=aa00cc="..self.tickTimer * 0.4)
	if self.tickTimer <= 0 then
		randVal = math.random(1,2)
		self.tickTimer = nil
		if randVal == 1 then
			status.modifyResource("food", (status.resource("food") * 0.015))
		else
			status.modifyResource("health", (status.resource("health") * 0.015*math.max(0,1+status.stat("healingBonus"))))
		end
	end
end
