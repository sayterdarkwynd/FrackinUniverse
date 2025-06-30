require "/scripts/unifiedGravMod.lua"
function init()
	self.baseparams = mcontroller.baseParameters()
	if not (self.baseparams.gravityEnabled and self.baseparams.collisionEnabled) then
		effect.expire()
		return
	end
	-- params
	unifiedGravMod.init()
	handle=effect.addStatModifierGroup({})
	self.applyToTypes = config.getParameter("applyToTypes") or {"player", "npc"}	 --what gets the effect?
	self.mouthPosition = status.statusProperty("mouthPosition") or {0,0}	--mouth position
	self.mouthBounds = {self.mouthPosition[1], self.mouthPosition[2], self.mouthPosition[1], self.mouthPosition[2]}
	--self.setWet = false -- doesnt start wet--unused. commenting out
	animator.setParticleEmitterOffsetRegion("bubbles", self.mouthBounds)

	--basic water locomotion stats
	self.shoulderHeight = 0.65							-- roughly shoulder depth
	self.fishHeight = 0.85 						-- almost all of the creature is submerged
	self.baseSpeed = 5.735						-- base liquid speed outside of a controlModifier call
	self.defaultSpeed = { speedModifier = 1 } 				-- the default movement speed
	self.defaultWaterSpeed = { speedModifier = 5.735 } 			-- the basic water speed
	self.basicMonsterSpeed = { speedModifier = 2.65 } 			-- most monsters speed
	self.jellyfishMonsterSpeed = { speedModifier = 0.1 } 			-- jellyfish are slow as molasses
	self.bossMonsterSpeed = { speedModifier = 4.735 } 			-- Veilendrex and Deep Seer speed

	self.boostAmount = status.stat("boostAmount")
	self.riseAmount = status.stat("riseAmount")

	applyBonusSpeed()

	self.gravityMultipliers={
		basic=-1.5,
		monsterWater=-0.9,
		--bossWater=0,
		--spawnedWater=0,
		--jellyfishWater=0.0,
		submerged=0.0
	}
	--[[self.gravityMultipliers={
		basic=-1,
		monsterWater=-1,
		--bossWater=0,
		--spawnedWater=0,
		jellyfishWater=-3,
		submerged=0.5
	}]]

	self.basicWaterParameters = {						-- generic values
		--gravityMultiplier = 0,
		liquidImpedance = 0,
		liquidForce = 100 * self.finalValue					-- get more swim force the better your boost is?
	}

	self.monsterWaterParameters = {						-- most monsters use these values , simulating slow movement and such
		--gravityMultiplier = 0.6,
		liquidImpedance = 0.5,
		liquidForce = 80.0
	}

	self.bossWaterParameters = {						-- Veilendrex and Deep Seer
		--gravityMultiplier = 1,
		liquidImpedance = 0.5,
		liquidForce = 80.0
	}

	self.spawnedWaterParameters = {						-- Atropal Eyes
		--gravityMultiplier = 1,
		liquidImpedance = 0.5,
		liquidForce = 30.0
	}

	self.jellyfishWaterParameters = {						-- Jellyfish
		--gravityMultiplier = -2,
		liquidImpedance = 0.5,
		liquidForce = 2.0
	}

	self.submergedParameters = {						-- generic values in water for non-specials
		--gravityMultiplier = 1.5,
		liquidImpedance = 0.5,
		liquidForce = 80.0,
		airFriction = 0,
		airForce = 0
	}
end

function applyBonusSpeed() --apply Speed Booost
	self.boostAmount = status.stat("boostAmount")
	if self.boostAmount > 2.5 then
		self.boostAmount = 2.5
	end

	self.finalValue = self.baseSpeed * (status.stat("boostAmount"))

end

function allowedType() -- check entity type from provided list
	local entityType = entity.entityType()
	for _,applyType in ipairs(self.applyToTypes) do
		if entityType == applyType then
			return true
		end
	end
end

function update(dt)
	if not (self.baseparams.gravityEnabled and self.baseparams.collisionEnabled) then
		effect.expire()
		return
	end
	-- params
	applyBonusSpeed() -- check if bonus speed is active

	local position = mcontroller.position()
	local worldMouthPosition = {self.mouthPosition[1] + position[1],self.mouthPosition[2] + position[2]}
	local liquidAtMouth = world.liquidAt(worldMouthPosition)

	handleWetness()

	if (status.stat("breathProtection") < 1) then
		if liquidAtMouth and (liquidAtMouth[1] == 1 or liquidAtMouth[1] == 2 or liquidAtMouth[1] == 6 or liquidAtMouth[1] == 40) then	--activate bubble particles if at mouth level with water
			animator.setParticleEmitterActive("bubbles", true)
			--self.setWet = true
		else
			animator.setParticleEmitterActive("bubbles", false)
			--self.setWet = false
		end

	end

	if not (allowedType()) then	-- if not the allowed type of entity (a monster that isn't a fish)
		setMonsterAbilities()
	else
		local liquidPercent=mcontroller.liquidPercentage()
		local boostAmount=status.stat("boostAmount")
		--sb.logInfo("liquidpercent %s, boostamount %s",liquidPercent,boostAmount)
		--funny enough, if you crouch in 2 block high water the collision poly gets stuck as a 2x2 box. this has silly results.

		if (liquidPercent < 0.25) and (boostAmount <= 1) then --are we barely in the water?
			mcontroller.controlParameters(self.submergedParameters)
			effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.submerged},{stat="fuswimming",amount=1}})
		elseif (liquidPercent < self.shoulderHeight) and (boostAmount <=1) then --are half submerged and not boosted
			effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.monsterWater},{stat="fuswimming",amount=1}})
			mcontroller.controlParameters(self.monsterWaterParameters)
		elseif (liquidPercent >= self.shoulderHeight) then --the following is redundant or ((liquidPercent >= self.shoulderHeight) and (boostAmount > 1)) then	--if the player is shoulder depth, or shallow depth+boosted
			effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.basic},{stat="fuswimming",amount=1}})
			mcontroller.controlModifiers({speedModifier = self.finalValue})
			mcontroller.controlParameters(self.basicWaterParameters)
		else
			effect.setStatModifierGroup(handle,{})
			effect.expire()
		end
	end
	unifiedGravMod.refreshGrav(dt)
end

function handleWetness()
	checkLiquidType()
	applyWet()
end

function checkLiquidType()
	local position = mcontroller.position()
	local worldMouthPosition = {self.mouthPosition[1] + position[1],self.mouthPosition[2] + position[2]}
	local liquidAtMouth = world.liquidAt(worldMouthPosition)
	clearWetEffects()

	if liquidAtMouth then -- is liquid at least up to our mouth? if so set the tags below
		if liquidAtMouth[1] == 1 or liquidAtMouth[1] == 12 or liquidAtMouth[1] == 58 or liquidAtMouth[1] == 73 or liquidAtMouth[1] == 69 then -- check if its a 'normal' water
			self.isWater = 1
		elseif liquidAtMouth[1] == 40 then -- check if the Blood effect for Wet needs to play
			self.isBlood = 1
		elseif liquidAtMouth[1] == 53 then -- check if the Pus effect for Wet needs to play
			self.isPus = 1
			self.isBlood = 0
		elseif liquidAtMouth[1] == 6 then -- check if the healing water effect for Wet needs to play
			self.isHealingWater = 1
		elseif liquidAtMouth[1] == 45 then -- check if the Elder effect for Wet needs to play
			self.isElder = 1
	else
		self.isGeneric = 1
		end
	end
end

--this function is never actually called usually. let's do something else with it!
--function onExpire()	 --now we call on the set tags above to produce corresponding wet effect
function applyWet()
	if self.isBlood == 1 then
		status.addEphemeralEffect("wetblood")
	elseif self.isPus == 1 then
		status.addEphemeralEffect("wetpus")
	elseif self.isHealingWater == 1 then
		status.addEphemeralEffect("wethealingwater")
	elseif self.isElder == 1 then
		status.addEphemeralEffect("wetelder")
	elseif self.isWater == 1 then
		status.addEphemeralEffect("wet")
	elseif self.isSaltWater == 1 then
		status.addEphemeralEffect("wet")
	elseif self.isGeneric == 1 then
		--kinda a space filler.
		status.addEphemeralEffect("wet")
	end
	clearWetEffects()
end

function clearWetEffects()
	self.isBlood = 0
	self.isPus = 0
	self.isHealingWater = 0
	self.isElder = 0
	self.isWater = 0
	self.isSaltWater = 0
	self.isGeneric = 0
end

function setMonsterAbilities()
	if (status.stat("isWaterCreature")) then
		if (mcontroller.liquidPercentage() >= self.fishHeight) then
			if (status.stat("isBossCreature"))==1 then
				mcontroller.controlModifiers(self.bossMonsterSpeed)
				mcontroller.controlParameters(self.bossWaterParameters)
				--effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.bossWater}})
			elseif (status.stat("isSpawnedCreature"))==1 then
				mcontroller.controlModifiers(self.basicMonsterSpeed)
				mcontroller.controlParameters(self.spawnedWaterParameters)
				--effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.spawnedWater}})
			elseif (status.stat("isJellyfishCreature"))==1 then
				mcontroller.controlModifiers(self.jellyfishMonsterSpeed)
				mcontroller.controlParameters(jellyfishWaterParameters)
				--effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.jellyfishWater}})
			end
		else
			if not mcontroller.baseParameters().gravityEnabled then
				mcontroller.setYVelocity(-5)
			end
			mcontroller.controlModifiers(self.defaultSpeed)
			mcontroller.controlParameters(self.submergedParameters)
			effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.submerged},{stat="fuswimming",amount=1}})
		end

	else
		mcontroller.controlModifiers(self.basicMonsterSpeed)
		mcontroller.controlParameters(self.monsterWaterParameters)
		effect.setStatModifierGroup(handle,{{stat="gravityMod",amount=self.gravityMultipliers.monsterWater},{stat="fuswimming",amount=1}})
	end
end

function uninit()
	if handle then
		effect.removeStatModifierGroup(handle)
	end
end
