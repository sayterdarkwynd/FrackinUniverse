require "/scripts/vec2.lua"
require "/stats/effects/fu_statusUtil.lua"
local foodThreshold=20--used by checkFood

function init()
	self.enabled = 0
	self.timer = 0
	self.baseInsanityImmunity = status.stat("insanityImmunity")
end

function uninit()
	deactivate()
end

function update(args)
	-- Check if F pushed
	if args.moves["special1"] and self.timer == 0 then
		self.timer = 0.5
		if self.enabled == 0 then
			activate()
		else
			deactivate()
		end
	end
	-- Timer to limit activation
	if self.timer > 0 then
		self.timer = math.max(0, self.timer - args.dt)
	end
	-- Stop if hungry
	if checkFood() < foodThreshold then
		deactivate()
	end
	-- Consume food
	if self.enabled == 1 then
		status.modifyResource("food",-0.006)
	end
end

function activate()
	self.enabled = 1
	if self.baseInsanityImmunity > 0 then
		status.setPersistentEffects("insanityVulnerability", {{stat = "insanityImmunity", amount = -1*self.baseInsanityImmunity}})
	end
	status.addPersistentEffect("madnesseffect2", "insanitynew", math.huge)
end

function deactivate()
	self.enabled = 0
	if self.baseInsanityImmunity > 0 then
		status.clearPersistentEffects("insanityVulnerability")
	end
	status.setPersistentEffects("madnesseffect2",{})
end
