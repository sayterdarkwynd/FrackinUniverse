require "/stats/effects/fu_statusUtil.lua"
require "/scripts/vec2.lua"

function init()
	attemptActivation(true)
end

function checkStance(moves)
	local swapped=false
	if moves["down"] then
		self.stance = "defense"
		swapped=true
	elseif moves["up"] then
		self.stance = "shield"
		swapped=true
	elseif moves["primaryFire"] or moves["altFire"] then
		self.stance = "attack"
		swapped=true
	elseif moves["jump"] then
		self.stance = "jump"
		swapped=true
	end

	if swapped then
		if self.stanceSoundCooldown <= 0.0 then
			local sound=""
			if self.stance ==  "defense" then
				sound="activate"
			elseif self.stance ==  "shield" then
				sound="activate2"
			elseif self.stance ==  "attack" then
				sound="activate3"
			elseif self.stance ==  "jump" then
				sound="activate3"
			end
			if animator.hasSound(sound) then
				animator.playSound(sound)
			end
		end
		self.stanceSoundCooldown = 3
	end
end

function setStance()
	--these use dummy statuses to display stats. these are located in  /stats/effects/fu_effects/fu_dummyeffects/thelusiantechdummies. they are purely for display.
	if self.stance == "defense" then
		status.setPersistentEffects("bugarmor", {
			"foodcostarmor",
			"thelusiantechdummyarmor",
			{stat = "protection", effectiveMultiplier = 1.3},
			{stat = "powerMultiplier", effectiveMultiplier = 0.85},
			{stat = "maxEnergy", effectiveMultiplier = 0.85}
		})
	elseif self.stance == "shield" then
		status.setPersistentEffects("bugarmor", {
			"foodcostarmor",
			"thelusiantechdummyshield",
			{stat = "shieldBash", amount = 25},
			{stat = "perfectBlockLimit", effectiveMultiplier = 2},
			{stat = "shieldBashPush", amount = 5},
			{stat = "maxEnergy", effectiveMultiplier = 0.50}
		})
	elseif self.stance == "attack" then
		status.setPersistentEffects("bugarmor", {
			"foodcostarmor",
			"thelusiantechdummyweapon",
			{stat = "protection", effectiveMultiplier = 0.85},
			{stat = "powerMultiplier", effectiveMultiplier = 1.25},
			{stat = "maxEnergy", effectiveMultiplier = 0.85}
		})
	elseif self.stance == "jump" then
		status.setPersistentEffects("bugarmor", {
			"foodcostarmor",
			"thelusiantechdummyjump",
			{stat = "protection", effectiveMultiplier = 0.85},
			{stat = "maxEnergy", effectiveMultiplier = 0.85}
		})
	end
end

function update(args)
	if args.moves["special1"] and self.stanceResetTimer then
		checkStance(args.moves)
		setStance()
		if self.stanceResetTimer < 3 then
			self.stanceResetTimer = math.min(3, self.stanceResetTimer + args.dt)
		else
			attemptActivation(true)
		end
	else
		self.stanceResetTimer = 0.0
	end

	if self.stanceSoundCooldown and self.stanceSoundCooldown > 0 then
		self.stanceSoundCooldown = math.max(0, self.stanceSoundCooldown - args.dt)
	else
		self.stanceSoundCooldown = 0
	end

	if self.stance == "defense" then -- in defense stance, we are slow
		applyFilteredModifiers({speedModifier = 0.75})
	elseif self.stance == "shield" then -- in shield stance we are slightly slower
		applyFilteredModifiers({speedModifier = 0.90})
	elseif self.stance == "attack" then -- in attack stance we are faster
		applyFilteredModifiers({speedModifier = 1.1})
	elseif self.stance == "jump" then -- in jump stance we are faster and jump higher
		applyFilteredModifiers({speedModifier = 1.1, airJumpModifier = 1.1})
	end
end

function attemptActivation(active)
	if active then
		if not self.stanceSoundCooldown then self.stanceSoundCooldown = 0.0 end
		if self.stanceSoundCooldown <= 0.0 then
			world.spawnProjectile("activeStance", mcontroller.position(), entity.id(), {0, 0}, false, { power = 0 })
		end
		self.stanceSoundCooldown = 3
		status.setPersistentEffects("bugarmor",{"foodcostarmor"})
		self.stance="neutral"
	else
		status.setPersistentEffects("bugarmor",{})
	end
end

function uninit()
	attemptActivation(false)
	filterModifiers({},true)
end
