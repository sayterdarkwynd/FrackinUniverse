require "/stats/effects/fu_statusUtil.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

fuWeatherBase = {}

--============================= CLASS DEFINITION ============================--

function fuWeatherBase.new(self, child)
	child = child or {}
	setmetatable(child, self)
	child.parent = self
	self.__index = self
	return child
end

--============================== INIT AND UNINIT =============================--

function fuWeatherBase.init(self, config_file)
	-- Environment Configuration --
	local effectConfig = root.assetJson(config_file)["effectConfig"]
	self.configPath=effectConfig.configPath
	--resistances
	self.resistanceTypes = effectConfig.resistanceTypes
	self.resistanceThreshold = effectConfig.resistanceThreshold
	--immunities
	self.immunityStats = effectConfig.immunityStats
	--damage over time
	self.baseHealthDrain = effectConfig.healthDrain
	self.baseHungerDrain = effectConfig.hungerDrain
	self.baseEnergyDrain = effectConfig.energyDrain
	--movement penalties
	self.baseSpeedPenalty = effectConfig.speedPenalty
	self.baseJumpPenalty = effectConfig.jumpPenalty
	--debuffs
	self.baseDebuffRate = effectConfig.debuffRate
	self.baseDebuffStartDelay = effectConfig.debuffStartDelay
	self.debuffs = effectConfig.debuffs
	self.currentDebuffs = {}
	self.debuffGroup = effect.addStatModifierGroup({})
	self.energyFixGroup = effect.addStatModifierGroup({})
	--situational modifiers
	self.modifiers = effectConfig.modifiers
	--messages
	self.messages = effectConfig.messages
	self.usedMessages = {}
	--timers
	self.messageTimer = nil -- timer until next radio message may play
	self.messageDelay = 5 -- default cooldown for radio messages
	self.debuffTimer = nil -- timer until next debuff tick
	self.debuffStartTimer = nil -- timer before debuffs start to apply

	-- Check and apply initial effect --
	self.effectActive = false
	--fuWeatherBase.checkEffect()

	-- Define script update interval --
	script.setUpdateDelta(5)
	-- Return the effect config (for child classes to extend).
	return effectConfig
end

function fuWeatherBase.uninit(self)
end

--=========================== CORE HELPER FUNCTIONS ==========================--

function fuWeatherBase.totalResist(self)
	local totalResist = 0
	for resist, multiplier in pairs(self.resistanceTypes) do
		totalResist = totalResist + (status.stat(resist) * multiplier)
	end
	return totalResist
end

function fuWeatherBase.resistModifier(self)
	local totalResist = fuWeatherBase.totalResist(self)
	if (totalResist > 0) then
		if (self.resistanceThreshold > 0) then
			-- Normal case: scale resistance modifier to resistanceThreshold
			return 1.0 - math.min(totalResist / self.resistanceThreshold, 1.0)
		else
			-- Fallback case: if resistanceThreshold is zero for some reason
			return 1.0 - math.min(totalResist, 1.0)
		end
	else
		-- Negative resist case: don't scale to resistanceThreshold
		return 1.0 - totalResist
	end
end

function fuWeatherBase.entityAffected(self)
	-- if player has the correct immunity stat, return false
	for _,stat in pairs(self.immunityStats) do
		if status.statPositive(stat) then
			return false
		end
	end
	-- if player has sufficient total resistances, return false
	if (self:totalResist() >= self.resistanceThreshold) then
		return false
	end
	return true
end

function fuWeatherBase.applyEffect(self)
	self:activateVisualEffects()
	self.effectActive = true
	-- Set debuff and other timers.
	self.messageTimer = 0
	self.debuffTimer = self.baseDebuffRate
	-- Debuff start delay timer scales with player resistances.
	if (self.baseDebuffStartDelay ~= nil) and (self.baseDebuffStartDelay > 0) then
		local debuffStartMult
		local totalResist = self:totalResist()
		if (totalResist >= 0) then
			debuffStartMult = 1.0 + (totalResist / self.resistanceThreshold)
		else
			debuffStartMult = math.max(1.0 + totalResist, 0.5)
		end
		self.debuffStartTimer = self.baseDebuffStartDelay * debuffStartMult
	else
		self.debuffStartTimer = 0
	end
end

function fuWeatherBase.removeEffect(self)
	self:deactivateVisualEffects()
	self:removeDebuffs()
	-- Reset used warning messages (in case player only has temporary immunity)
	self.usedMessages = {}
	self.effectActive = false
end

--[[ Checks whether or not the effect should be active, changes the effect's
		stat if necessary, and tries to play the "intro" warning message if it
		hasn't been played yet. ]]--
function fuWeatherBase.checkEffect(self)
	--[[ if not a player, or world type is "unknown" (on ship) then remove the
			effect and expire (should destroy this instance). ]]--
	if ((world.entityType(entity.id()) ~= "player")
	or world.type()=="unknown") then
		self:removeEffect()
		effect.expire()
		return
	end
	if self:entityAffected() then
		if (not self.effectActive) then
			self:applyEffect()
		end
		self:sendWarning("intro")
	elseif self.effectActive then
		self:removeEffect()
	end
end

--[[ Send a weather-related warning message to the player. This will only
		succeed if:
		1. The message self.messages[type] is defined
		2. The message timer is zero (cooldown has passed)
		3. The message has not already been sent for this effect instance
		If successful, the message timer will be reset and the message will be
		flagged as used. ]]--
function fuWeatherBase.sendWarning(self, label)
	if (self.messages[label] == nil) then
		return
	end
	if (self.messageTimer <= 0) then
		if (self.usedMessages[label] ~= true) then
			-- Determine what message to send.
			local message = nil
			local propString=(self.configPath or "genericBiomeWarningLastUsedProperty").."/"..label
			local biomeWarningLastUsedProperty=status.statusProperty(propString)
			--sb.logInfo("propstr %s propval %s p1 %s p2 %s",propString,biomeWarningLastUsedProperty,propCondition1,propCondition2)
			if (not biomeWarningLastUsedProperty) or ((os.time()-biomeWarningLastUsedProperty)>=60) then
				if (type(self.messages[label]) == "string") then
					-- If the target is a string, then that is the message.
					message = self.messages[label]
					status.setStatusProperty(propString,os.time())
				elseif (type(self.messages[label]) == "table") then
					-- If the target is a table, choose one of its elements at random.
					local index = math.random(#(self.messages[label]))
					message = self.messages[label][index]
					status.setStatusProperty(propString,os.time())
				else
					-- Unrecognised type, abort.
					return
				end
			end
			if message then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", message, 1.0)
			end
			self.messageTimer = self.messageDelay
			self.usedMessages[label] = true
		end
	end
end

--============================ CONDITIONAL CHECKS ===========================--

function fuWeatherBase.lightLevel(self)
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = math.min(world.lightLevel(position),1.0)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function fuWeatherBase.hungerLevel(self)
	if status.isResource("food") then
		return status.resource("food")
	else
		return 50
	end
end

function fuWeatherBase.isDaytime(self)
	return (world.timeOfDay() < 0.5)
end

function fuWeatherBase.isUnderground(self)
	return world.underground(mcontroller.position())
end

function fuWeatherBase.isWet(self)
	local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	return world.liquidAt(mouthPosition)
end

function fuWeatherBase.isWindy(self)
	return (world.windLevel(mcontroller.position()) > 40)
end

--============================ DEBUFFING FUNCTIONS ===========================--

--[[ Note that this function also triggers the appropriate warning messages
		for situational effects (wet, underground etc.). ]]--
function fuWeatherBase.totalModifier(self)
	local totalModifier = self:resistModifier()
	if (self.modifiers["night"] ~= nil) and not (self:isDaytime() or self:isUnderground()) then
		totalModifier = totalModifier * self.modifiers["night"]
		self:sendWarning("night")
	end
	if (self.modifiers["underground"] ~= nil) and (self:isUnderground()) then
		totalModifier = totalModifier * self.modifiers["underground"]
		self:sendWarning("underground")
	end
	if (self.modifiers["wet"] ~= nil) and (self:isWet()) then
		totalModifier = totalModifier * self.modifiers["wet"]
		self:sendWarning("wet")
	end
	if (self.modifiers["windy"] ~= nil) and (self:isWindy()) and (not self:isUnderground()) then
		totalModifier = totalModifier * self.modifiers["windy"]
		self:sendWarning("windy")
	end
	return totalModifier
end

function fuWeatherBase.applyHealthDrain(self, modifier, dt)
	if (self.baseHealthDrain > 0) then
		local healthDrain = self.baseHealthDrain * modifier
		status.modifyResource("health", -healthDrain * dt)
	end
end

function fuWeatherBase.applyHungerDrain(self, modifier, dt)
	if (self.baseHungerDrain > 0) then
		if status.isResource("food") then
			if (status.resource("food") >= 2) then
				local hungerDrain = self.baseHungerDrain * modifier
				status.modifyResource("food", -hungerDrain * dt)
			end
		end
	end
end

function fuWeatherBase.applyEnergyDrain(self, modifier, dt)
	if (self.baseEnergyDrain > 0) then
		if status.isResource("energy") then
			local energyDrain = self.baseEnergyDrain * modifier
			status.modifyResource("energy", -energyDrain * dt)
		end
	end
end

function fuWeatherBase.applyMovementPenalties(self, modifier)
	--[[ NOTE: Base penalties should be less than 1. The totalModifier is capped
			at 1.0 so that the player cannot be stopped completely. ]]--
	local speedPenalty = 0
	local jumpPenalty = 0
	if (self.baseSpeedPenalty > 0) then
		speedPenalty = self.baseSpeedPenalty * math.min(modifier, 1.0)
	end
	if (self.baseJumpPenalty > 0) then
		jumpPenalty = self.baseJumpPenalty * math.min(modifier, 1.0)
	end
	applyFilteredModifiers({
		speedModifier = 1.0 - speedPenalty,
		airJumpModifier = 1.0 - jumpPenalty
	})
end

function fuWeatherBase.applyDebuffs(self, modifier)
	-- Only apply debuffs if the start delay has ended.
	if (self.debuffStartTimer == 0) then
		local newGroup = {}
		local debuffChanged = false
		local i = 1
		for dStat, dParams in pairs(self.debuffs) do
			local statName = tostring(dStat)
			local dAmount = dParams.amount * modifier
			-- Initialise debuff entry if not yet set.
			if (self.currentDebuffs[statName] == nil) then
				self.currentDebuffs[statName] = dAmount
				debuffChanged = true
			-- Unless constant flag is set, stack debuffs on subsequent ticks.
			elseif (dParams.constant == nil) then
				-- If stat debuff is capped, do not exceed it.
				if (dParams.cap ~= nil) then
					local cappedAmount
					if (dAmount > 0) then -- upper cap
						cappedAmount = math.min(dParams.cap - status.stat(statName), dAmount)
					else -- lower cap
						cappedAmount = math.max(dParams.cap - status.stat(statName), dAmount)
					end
					-- Discard tiny changes due to precision limits.
					if (math.abs(cappedAmount) < 0.0001) then
						cappedAmount = 0
					end
					if (cappedAmount ~= 0) then
						debuffChanged = true
					end
					self.currentDebuffs[statName] = self.currentDebuffs[statName] + cappedAmount
				else
					self.currentDebuffs[statName] = self.currentDebuffs[statName] + dAmount
					debuffChanged = true
				end
			end
			-- Add debuff to modifier group.
			newGroup[i] = {stat = statName, amount = self.currentDebuffs[statName]}
			i = i + 1
		end
		if (i > 1) then
			-- Update this effect's debuff modifier group.
			effect.setStatModifierGroup(self.debuffGroup, newGroup)
			-- Display alerts (e.g. "-Max HP" popup).
			if (debuffChanged) then
				self:createAlert()
			end
		end
	end
end

function fuWeatherBase.removeDebuffs(self)
	self.currentDebuffs = {}
	effect.removeStatModifierGroup(self.debuffGroup)
	self.debuffGroup = effect.addStatModifierGroup({})
	effect.removeStatModifierGroup(self.energyFixGroup)
	self.energyFixGroup = effect.addStatModifierGroup({})
end

function fuWeatherBase.applySelfDamage(self, amount, type)
	-- Note that 'type' should be optional.
	status.applySelfDamageRequest({
		damageType = "IgnoresDef",
		damage = amount,
		damageSourceKind = type,
		sourceEntityId = entity.id()
	})
end

--============================= GRAPHICAL EFFECTS ============================--

function fuWeatherBase.toHex(self, num)
	local num2=math.floor(num + 0.5)
	local hex = string.format("%02X",num2)
	return hex
end

--[[ NOTE: These functions should be defined individually for each weather
		type. I have left these here as an "abstract class"-style definition. ]]--

function fuWeatherBase.activateVisualEffects(self)
end

function fuWeatherBase.deactivateVisualEffects(self)
end

function fuWeatherBase.createAlert(self)
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ NOTE: The actual update() function must be defined in each weather
		effect's .lua file. However, the idea is that the majority of what each
		weather effect does can be achieved simply by calling the method
		self:update(dt). ]]--

function fuWeatherBase.update(self, dt)
	if not fuWeatherBase.checkStatusPropertiesTimer or fuWeatherBase.checkStatusPropertiesTimer >= 0.1 then
		fuWeatherBase.playerLoungingIn=status.statusProperty("player.loungingIn")
		fuWeatherBase.playerIsInMech=status.statusProperty("playerIsInMech")
		fuWeatherBase.playerIsInVehicle=status.statusProperty("playerIsInVehicle")
		fuWeatherBase.checkStatusPropertiesTimer=0.0
	else
		fuWeatherBase.checkStatusPropertiesTimer=math.max(0,fuWeatherBase.checkStatusPropertiesTimer+dt)
	end
	--[[if not fuWeatherBase.checkingMechTimer or fuWeatherBase.checkingMechTimer >= 0.1 then
		if fuWeatherBase.playerIsInMech then
			fuWeatherBase.mechHazardImmunities=status.statusProperty("mechHazardData")
		else
			fuWeatherBase.mechHazardImmunities=nil
		end
		fuWeatherBase.checkingMechTimer=0.0
	else
		fuWeatherBase.checkingMechTimer=math.max(0,fuWeatherBase.checkingMechTimer+dt)
	end]]
	-- Check that weather effect is (still) active.
	self:checkEffect()
	if (not self.effectActive) then
		return 0
	end
	-- Tick down timers.
	self.messageTimer = math.max(self.messageTimer - dt, 0)
	self.debuffTimer = math.max(self.debuffTimer - dt, 0)
	self.debuffStartTimer = math.max(self.debuffStartTimer - dt, 0)

	-- Calculate the total effect modifier.
	local modifier = self:totalModifier()

	-- Apply health drain.
	self:applyHealthDrain(modifier, dt)
	-- Apply hunger drain (if not casual).
	self:applyHungerDrain(modifier, dt)
	-- Apply energy drain (unusual effect and probably conditional).
	self:applyEnergyDrain(modifier, dt)
	-- Apply speed and jump penalties.
	self:applyMovementPenalties(modifier)
	--[[ Special case: if the player's max energy is exactly zero due to debuffs,
			set it to -1 instead. This prevents the 'wipeout effect' from spamming
			if the player is in admin mode. ]]--
	if (type(self.currentDebuffs["maxEnergy"]) == "number") and (status.stat("maxEnergy") == 0) then
		local newGroup = {{stat = "maxEnergy", amount = -1}}
		effect.setStatModifierGroup(self.energyFixGroup, newGroup)
	end
	-- Then, periodically apply any stat debuffs.
	if (self.debuffTimer == 0) then
		self:applyDebuffs(modifier)
		self.debuffTimer = self.baseDebuffRate
	end
	-- Return the total modifier (for child classes to extend).
	return modifier
end
