require "/stats/typer_particle.lua"
require("/scripts/vec2.lua")
require("/stats/effects/fu_weathereffects/new/fuWeatherBase.lua")
--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of fuWeatherBase. The child's metatable
		is set to the parent's, so that any missing indexes (methods) are looked
		up from fuWeatherBase. The methods can also be accessed manually (in cases
		that extend the parent method) through the child.parent attribute. ]]--

fuInsanityWeather = fuWeatherBase:new({})

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuWeatherBase should be
		defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
				self.parent.method(self)
		rather than the conventional "syntactic sugar version"
				self.parent:method()
		The latter will pass the parent class as the "self" parameter, preventing
		any attributes overwritten by the child from being used. ]]--

function fuInsanityWeather.removeEffect(self)
	self:deactivateVisualEffects()
	self:removeDebuffs()
	-- Reset used warning messages (in case player only has temporary immunity)
	self.usedMessages = {}
	self.effectActive = false
	typerParticle.reset()
end

function fuInsanityWeather.init(self, config_file)
	effectConfig = self.parent.init(self, config_file)
	-- Extra graphical settings.
	self.colorMod = effectConfig.colorMod
	self.saturation = effectConfig.saturation
	-- Chatter timer.
	self.chatterDelay = effectConfig.chatterDelay
	self.chatterTimer = nil
	-- Delay before granting darkness immunity.
	self.darknessImmunityDelay = effectConfig.darknessImmunityDelay
	self.darknessImmunityTimer = nil
	self.madTimer = 0
	self.afk = 0
	self.myspeed = 0
	self.unBlockable = config.getParameter("isUnblockable") or 0
	effect.addStatModifierGroup({{stat = "isUnblockable", amount = self.unBlockable}})
	self.onTerrestrialWorld=world.terrestrial()
	typerParticle.init()
end

function fuInsanityWeather.update(self, dt)

	self.parent.update(self, dt)

	if self.effectActive then
		-- Tick down extra timers.
		self.darknessImmunityTimer = math.max(self.darknessImmunityTimer - dt, 0)
		self.chatterTimer = math.max(self.chatterTimer - dt, 0)
		-- Insanity chatter.
		if (self.chatterTimer == 0) then
			self:insanityChatter()
			self.chatterTimer = self.chatterDelay.base + math.random() * self.chatterDelay.random
		end
		typerParticle.update(dt)
	end
end

function fuInsanityWeather.totalModifier(self)
	--[[ There are no modifiers apart from resistance, and we don't want to play
			warning messages (they're replaced by insanity chatter). ]]--
	return self:resistModifier()
end

function fuInsanityWeather.applyEffect(self)
	self.parent.applyEffect(self)
	-- Set auxiliary timers.
	self.darknessImmunityTimer = self.darknessImmunityDelay
	self.chatterTimer = self.chatterDelay.base + math.random() * self.chatterDelay.random
end


--[[
{dAmount: -4, modifier: 1, statName: protection, dStat: protection, dParams: {cap: -20, amount: -4}}
{dAmount: -8, modifier: 1, statName: maxEnergy, dStat: maxEnergy, dParams: {cap: -1, amount: -8}}
]]

--[[ Modified function to add darkness immunity once the player has been
		insane for a while. ]]--
function fuInsanityWeather.applyDebuffs(self, modifier)
	local newGroup = {}
	local i = 1
	for dStat, dParams in pairs(self.debuffs) do
		local statName = tostring(dStat)
		local dAmount=dParams.amount * modifier
		local dType=tostring(dParams.type)

		-- Initialise debuff entry if not yet set.
		if (self.currentDebuffs[statName] == nil) then
			self.currentDebuffs[statName] = dAmount
			-- Unless constant flag is set, stack debuffs on subsequent ticks.
		elseif (dParams.constant == nil) then
			self.currentDebuffs[statName] = self.currentDebuffs[statName] + dAmount
		end

		if dParams.cap then
			self.currentDebuffs[statName]=math.max(self.currentDebuffs[statName],dParams.cap)
		end

		-- Add debuff to modifier group.
		local buffer={stat = statName}
		if dType=="effectiveMultiplier" then
			buffer[dType]=1.0+(self.currentDebuffs[statName]*0.01)
		else
			buffer["amount"]=self.currentDebuffs[statName]
		end
		
		newGroup[i] = buffer
		--sb.logInfo("%s",{dAmount=dAmount,dStat=dStat,dParams=dParams,statName=statName,modifier=modifier})
		i = i + 1
	end
	-- (Modified) Add darkness immunity if timer has expired.
	if (self.darknessImmunityTimer == 0) then
		newGroup[i] = {stat = "darknessImmunity", amount = 1}
		i = i + 1
	end

	if world.entityType(entity.id())=="player" then --only if its a player do we run this
		if (i > 1) then
			effect.setStatModifierGroup(self.debuffGroup, newGroup)
			if (status.stat("mentalProtection") < 1) and (self.madTimer < 200) then
				local afkLvl=afkLevel()
				if (afkLvl<=3) and (self.onTerrestrialWorld) then
					self.randMadness = math.random(2,8-(2*afkLvl)) * (math.random(1,2) - status.stat("mentalProtection"))-- spawn madness randomly when this effect is active, less if inactive
					world.spawnItem("fumadnessresource",entity.position(),self.randMadness )
				end
				self.madTimer = self.madTimer + 1
			end
			self:createAlert()
		end
	end
end

function afkLevel()
	return ((status.statusProperty("fu_afk_720s") and 4) or (status.statusProperty("fu_afk_360s") and 3) or (status.statusProperty("fu_afk_240s") and 2) or (status.statusProperty("fu_afk_120s") and 1) or 0)
end

function fuInsanityWeather.insanityChatter(self)

	-- Insanity messages for hunger take priority (most of the time).
	local hunger = self:hungerLevel()

	if (hunger < 60) and (math.random() >= 0.3) then
		if (hunger < 5) then
			self:sendWarning("hungry5")
			self.usedMessages["hungry5"] = nil
		elseif (hunger < 10) then
			self:sendWarning("hungry10")
			self.usedMessages["hungry10"] = nil
		elseif (hunger < 20) then
			self:sendWarning("hungry20")
			self.usedMessages["hungry20"] = nil
		elseif (hunger < 30) then
			self:sendWarning("hungry30")
			self.usedMessages["hungry30"] = nil
		elseif (hunger < 40) then
			self:sendWarning("hungry40")
			self.usedMessages["hungry40"] = nil
		elseif (hunger < 50) then
			self:sendWarning("hungry50")
			self.usedMessages["hungry50"] = nil
		else
			self:sendWarning("hungry60")
			self.usedMessages["hungry60"] = nil
		end
		-- Insanity message while in liquid
	elseif mcontroller.liquidPercentage() >= 0.5 then
		self:sendWarning("wet")
		-- Insanity message while going fast
	elseif mcontroller.xVelocity() >= 10 then
		self:sendWarning("fast")
		-- Insanity message while in zero-G
	elseif mcontroller.zeroG() then
		self:sendWarning("zeroG")
		-- Insanity message while airborne
	elseif (not mcontroller.onGround()) and (math.random() >= 0.5) then
		self:sendWarning("airborne")
		-- Unset "used" flag.
		self.usedMessages["airborne"] = nil
		-- Insanity chatter while injured
	elseif (status.resource("health") < (status.stat("maxHealth") * 0.75)) then
		self:sendWarning("injured")
		-- Unset "used" flag.
		self.usedMessages["injured"] = nil
		-- Otherwise, random insanity chatter (previously while windy)
	else
		self:sendWarning("random")
		-- Unset "used" flag.
		self.usedMessages["random"] = nil
	end
end

--============================= GRAPHICAL EFFECTS ============================--

function fuInsanityWeather.activateVisualEffects(self)
	animator.setParticleEmitterOffsetRegion("poisonbreath", mcontroller.boundBox())
	animator.setParticleEmitterActive("poisonbreath", true)
	local resist = math.max(self:totalResist(), 0)
	local colorMult = {
		100 * resist,
		255 + self.colorMod[2] * resist,
		255 + self.colorMod[3] * resist
	}
	local colorMultHex = string.format(
		"%s%s%s",
		self:toHex(colorMult[1]),
		self:toHex(colorMult[2]),
		self:toHex(colorMult[3])
	)
	effect.setParentDirectives(string.format("?saturation=%d?multiply=%s", self.saturation, colorMultHex))
end

function fuInsanityWeather.deactivateVisualEffects(self)
	animator.setParticleEmitterActive("poisonbreath", false)
	effect.setParentDirectives("fade=ff7600=0.0")
end

function fuInsanityWeather.createAlert(self)
	if entity.entityType()=="player" then
		local statusTextRegion = { 0, 1, 0, 1 }
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	 end
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
		They should not need to be modified (apart from the class name). ]]--

function init()
	local config_file = config.getParameter("configPath")
	fuInsanityWeather:init(tostring(config_file))
end

function uninit()
	fuInsanityWeather:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
		shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
	fuInsanityWeather:update(dt)
end
