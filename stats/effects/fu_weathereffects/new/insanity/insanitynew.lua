require("/scripts/vec2.lua")

function init()

	-- Environment Configuration --
	--base values
	self.effectCutoff = config.getParameter("effectCutoff",0)
	self.effectCutoffValue = config.getParameter("effectCutoffValue",0)
	self.baseRate = config.getParameter("baseRate",0)
	self.baseDmg = config.getParameter("baseDmgPerTick",0)
	self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
	self.biomeTemp = config.getParameter("biomeTemp",0)
	--timers
	self.biomeTimer = self.baseRate
	self.biomeTimer2 = (self.baseRate * (1 + status.stat("cosmicResistance",0)) *10)

	--conditionals

	self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
	self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
	self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
	self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
	self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?
	self.timerRadioMessage =  config.getParameter("baseRate",0)  -- initial delay for secondary radiomessages
	self.timerRadioMessage2 =  config.getParameter("baseRate",0)  -- initial delay for secondary radiomessages
	-- set desaturation effect
	self.multiply = config.getParameter("multiplyColor")
	self.saturation = 0

	self.madnessTotal = config.getParameter("madnessTotal",0)

	checkEffectValid()
	insanityDarkImmune=effect.addStatModifierGroup({})
	script.setUpdateDelta(5)
end

function getTotalResist()
	-- Insanity is mitigated by cosmic resistance, and somewhat by shadow.
	return status.stat("cosmicResistance",0) + (status.stat("shadowResistance",0) / 2)
end

--[[ Helper function to determine if weather effect applies to an entity ]]--
function isEntityAffected()
	-- if not a player, or world type is "unknown" (???) then return false --
	if ((world.entityType(entity.id()) ~= "player") or
	world.type()=="unknown") then
		return false
	end
	-- if player has immunity stat or sufficient resistance, return false --
	if (status.statPositive("insanityImmunity") or
	(getTotalResist() >= self.effectCutoffValue)) then
		return false
	end
	-- otherwise, return true
	return true
end

--[[ Check if weather effect is still applicable, and handle visual effects ]]--
function checkEffectValid()
	-- remove visual effect if no longer affected
	if not isEntityAffected() then
		deactivateVisualEffects()
		effect.expire()
	-- add visual effect and display warning (if not yet shown)
	else
		activateVisualEffects()
		if self.timerRadioMessage <= 0 then
			-- Send player initial warning
			if not self.usedIntro then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomeinsanity", 1.0) -- send player a warning
				self.usedIntro = 1
				self.timerRadioMessage = 20
			-- Otherwise, display other insanity chatter
			else
				sendInsanityMessage()
				self.timerRadioMessage = 40
			end
		end
	end
end

-- *******************Damage effects
function setEffectDamage()
	return ( ( self.baseDmg ) *  (1 -status.stat("cosmicResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
	return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("cosmicResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
	return (  self.baseRate *  math.min(   1 - math.min( status.stat("cosmicResistance",0) ),0.25))
end

-- ******** Applied bonuses and penalties
function setNightPenalty()
	if (self.biomeNight > 1) then
		self.baseDmg = self.baseDmg + self.biomeNight
		self.baseDebuff = self.baseDebuff + self.biomeNight
	end
end

function setSituationPenalty()
	if (self.situationPenalty > 1) then
		self.baseDmg = self.baseDmg + self.situationPenalty
		self.baseDebuff = self.baseDebuff + self.situationPenalty
	end
end

function setLiquidPenalty()
	if (self.liquidPenalty > 1) then
		self.baseDmg = self.baseDmg * 2
		self.baseDebuff = self.baseDebuff + self.liquidPenalty
	end
end

function setWindPenalty()
	self.windLevel =  world.windLevel(mcontroller.position())
	if (self.windLevel > 1) then
		self.biomeThreshold = self.biomeThreshold + (self.windLevel / 100)
	end
end

-- ********************************

--**** Other functions
function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = world.lightLevel(position)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end


function isDry()
	local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	return not world.liquidAt(mouthPosition)
end

function hungerLevel()
	if status.isResource("food") then
		return status.resource("food")
	else
		return 50
	end
end

function toHex(num)
	local hex = string.format("%X", math.floor(num + 0.5))
	if num < 16 then hex = "0"..hex end
	return hex
end

function activateVisualEffects()
	animator.setParticleEmitterOffsetRegion("poisonbreath", mcontroller.boundBox())
	animator.setParticleEmitterActive("poisonbreath", true)
	local resist = status.stat("cosmicResistance", 0)
	local multiply = {100 * math.max(resist, 0), 255 + self.multiply[2] * math.max(resist, 0), 255 + self.multiply[3] * math.max(resist, 0)}
	local multiplyHex = string.format("%s%s%s", toHex(multiply[1]), toHex(multiply[2]), toHex(multiply[3]))
	effect.setParentDirectives(string.format("?saturation=%d?multiply=%s", self.saturation, multiplyHex))
end

function deactivateVisualEffects()
	animator.setParticleEmitterActive("poisonbreath", false)
	effect.setParentDirectives("fade=ff7600=0.0")
end

function sendInsanityMessage()
	if self.timerRadioMessage <= 0 then
		-- Insanity message while in liquid
		if mcontroller.liquidPercentage() >= 0.5 and not self.usedLiq then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectliquid", 1.0)
			self.usedLiq = 1
		-- Insanity message while going fast
		elseif mcontroller.xVelocity() >= 10 and not self.usedVel then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectfast", 1.0)
			self.usedVel = 1
		-- Insanity message while in zero-G
		elseif mcontroller.zeroG() and not self.usedZero then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectgrav", 1.0)
			self.usedZero = 1
		-- Insanity message while airborne
		elseif not mcontroller.onGround() and not self.usedLeap then
			local rand = math.random(3)
			if rand == 1 then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectair", 1.0)
			elseif rand == 2 then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectair2", 1.0)
			else -- rand == 3
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectair3", 1.0)
			end
			self.usedLeap = 1
		-- Insanity chatter while injured
		elseif status.resource("health") < (status.stat("maxHealth") * 0.75) then
			local rand = math.random(15)
			if rand == 1 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectdying", 1.0)
			elseif rand == 2 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectdying2", 1.0)
			elseif rand == 3 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectdying3", 1.0)
			elseif rand == 4 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectdying4", 1.0)
			elseif rand == 5 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectdying5", 1.0)
			elseif rand == 6 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectskin", 1.0)
			elseif rand == 7 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectwindy", 1.0)
			elseif rand == 8 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectducts", 1.0)
			elseif rand == 9 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo1", 1.0)
			elseif rand == 10 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo2", 1.0)
			elseif rand == 11 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo3", 1.0)
			elseif rand == 12 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo4", 1.0)
			elseif rand == 13 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "fu_kevin_insanity3", 1.0)
			elseif rand == 14 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "fu_kevin_insanity5", 1.0)
			else --rand == 15
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "fu_kevin_insanity1", 1.0)
			end
		-- Otherwise, random insanity chatter (previously while windy)
		else
			local rand = math.random(15)
			if rand == 1 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectkyle", 1.0)
			elseif rand == 2 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectmike", 1.0)
			elseif rand == 3 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectmusic", 1.0)
			elseif rand == 4 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectwee", 1.0)
			elseif rand == 5 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectneat", 1.0)
			elseif rand == 6 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectskin", 1.0)
			elseif rand == 7 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectwindy", 1.0)
			elseif rand == 8 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectducts", 1.0)
			elseif rand == 9 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo1", 1.0)
			elseif rand == 10 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo2", 1.0)
			elseif rand == 11 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo3", 1.0)
			elseif rand == 12 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectweirdo4", 1.0)
			elseif rand == 13 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "fu_kevin_insanity6", 1.0)
			elseif rand == 14 then world.sendEntityMessage(entity.id(), "queueRadioMessage", "fu_kevin_insanity2", 1.0)
			else --rand == 15
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "fu_kevin_insanity4", 1.0)
			end
		end
	end
end

function makeAlert()
	local statusTextRegion = { 0, 1, 0, 1 }
	animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
	animator.burstParticleEmitter("statustext")
end


function update(dt)

	checkEffectValid()
	self.timerRadioMessage = self.timerRadioMessage - dt
--set the base stats
	self.baseRate = config.getParameter("baseRate",0)
	self.baseDmg = config.getParameter("baseDmgPerTick",0)
	self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
	self.biomeTemp = config.getParameter("biomeTemp",0)
	self.biomeThreshold = config.getParameter("biomeThreshold",0)
	self.biomeNight = config.getParameter("biomeNight",0)
	self.situationPenalty = config.getParameter("situationPenalty",0)
	self.liquidPenalty = config.getParameter("liquidPenalty",0)

	self.baseRate = setEffectTime()
	self.damageApply = setEffectDamage()
	self.debuffApply = setEffectDebuff()

	-- environment checks
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()

	if isEntityAffected() then
		self.biomeTimer = self.biomeTimer - dt
		-- Apply periodic health and food drain.
		if (self.biomeTimer <= 0) then
			status.modifyResource("health", -self.damageApply * dt)
			status.modifyResource("food", -self.damageApply * dt)
			self.biomeTimer = self.baseRate
		end
		-- Insanity messages for hunger run on a separate timer.
		--if status.isResource("food") then
			self.timerRadioMessage2 = self.timerRadioMessage2 - dt
			if self.timerRadioMessage2 <= 0 then
				local hungerLevel = hungerLevel()
				if (hungerLevel < 5) then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry4", 1.0)
				elseif (hungerLevel < 10) then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry3", 1.0)
				elseif (hungerLevel < 20) then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry2", 1.0)
				elseif (hungerLevel < 30) then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry1", 1.0)
				elseif (hungerLevel < 40) then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry5", 1.0)
				elseif (hungerLevel < 50) then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry6", 1.0)
				elseif (hungerLevel < 60) then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry7", 1.0)
				end
				self.timerRadioMessage2 = 60
			end
		--end
		self.biomeTimer2 = self.biomeTimer2 - dt
		-- Apply semi-periodic protection and energy debuffs.
		if self.biomeTimer2 <= 0 then
			effect.setStatModifierGroup(insanityDarkImmune,{
				{stat = "darknessImmunity", amount = 1}
			})
			effect.addStatModifierGroup({
				{stat = "protection", amount = -self.baseDebuff},
				{stat = "maxEnergy", amount = -self.baseDebuff * 2}
			})
			makeAlert()
			self.biomeTimer2 = (self.baseRate * (1 + getTotalResist())) * 2
		end
	end --isEntityAffected()
end

function uninit()
	effect.removeStatModifierGroup(insanityDarkImmune)
end
