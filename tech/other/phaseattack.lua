require "/scripts/vec2.lua"

function init()
	self.deactiveDelayMax = 0.6
	self.deactiveDelay = 1
	self.deactiveReady = false
end

function uninit()
	deactivate()
end

function update(args)
	if not self.specialLast and args.moves["special1"] then
		attemptActivation()
	end
	self.specialLast = args.moves["special1"]

	if args.moves["primaryFire"] or args.moves["altFire"] or status.resource("energy") <=0 then
		self.deactiveReady = true
	end

	if self.deactiveReady then
		self.deactiveDelay = self.deactiveDelay - args.dt;
		if self.deactiveDelay <= 0 then
			deactivate()
			self.deactiveReady = false
		end
	end

	if self.active then
		status.setResourcePercentage("energyRegenBlock", 1.0)
		if status.resourceLocked("energy") then
			deactivate()
			self.deactiveReady = false
		else
			status.addEphemeralEffect("phaseattackinvuln",1)
			status.addEphemeralEffect("phaseattackstat",1)
		end
	end
end

function attemptActivation()
	if not self.active then
		activate()
	elseif self.active then
		deactivate()
	end
end

function activate()
	if status.resourceLocked("energy") then return end
	if not self.active then
		status.removeEphemeralEffect("phaseattackstat")
		status.removeEphemeralEffect("phaseattackindicatorcharged")
		status.addEphemeralEffect("phaseattackstat",1)
		status.addEphemeralEffect("phaseattackinvuln",1)
		animator.playSound("activate")
	end

	self.active = true
	self.deactiveDelay = self.deactiveDelayMax
end

function deactivate()
	if self.active then
		status.removeEphemeralEffect("phaseattackinvuln")
		--this does nothing
		--world.setProperty("hide[" .. tostring(entity.id()) .. "]", nil)
		animator.playSound("deactivate")
	end

	self.active = false
end
