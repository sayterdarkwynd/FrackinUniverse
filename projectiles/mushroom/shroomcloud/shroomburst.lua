require "/stats/effects/fu_statusUtil.lua"

function init()
	script.setUpdateDelta(5)
	self.tickTimer = 1
	self.pulseTimer = 0
	self.halfPi = math.pi / 2
end

function update(dt)
	applyFilteredModifiers({
		speedModifier = 0.55,
		airJumpModifier = 0.65
	})

	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = 1
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = 0.054 * status.resourceMax("health"),
			sourceEntityId = entity.id()
		})
	end

	self.pulseTimer = self.pulseTimer + dt * 2
	if self.pulseTimer >= math.pi then
		self.pulseTimer = self.pulseTimer - math.pi
	end

	local pulseMagnitude = math.floor(math.cos(self.pulseTimer - self.halfPi) * 16) / 16
	effect.setParentDirectives(string.format("fade=00AA00=%.3f?border=2;00FF00%2x;00000000", (pulseMagnitude * 0.3 + 0.1), math.floor(pulseMagnitude * 70) + 10))
end

function uninit()
	filterModifiers({},true)
end
