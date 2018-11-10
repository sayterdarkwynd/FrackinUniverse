require("/scripts/vec2.lua")

function init()
	self.timerRadioMessage = 0  -- initial delay for secondary radiomessages

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
	self.biomeTimer2 = 3

	--conditionals
	self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
	self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
	self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
	self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
	self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?


	checkEffectValid()

	script.setUpdateDelta(5)
end

--[[ Helper function to determine if weather effect applies to an entity ]]--
function isEntityAffected()
	-- if not a player, or world type is "unknown" (???) then return false --
	if ((world.entityType(entity.id()) ~= "player") or
	world.type()=="unknown") then
		return false
	end
	-- if player has immunity stat or sufficient resistance, return false --
	if (status.statPositive("biomecoldImmunity") or
	status.statPositive("ffextremecoldImmunity") or
	(status.stat("iceResistance",0) >= self.effectCutoffValue)) then
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
		if not self.usedIntro then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomecold", 1.0)
			self.usedIntro = 1
			self.timerRadioMessage = 220
		end
	end
end

-- *******************Damage effects
function setEffectDamage()
	return ( ( self.baseDmg ) *  (1 -status.stat("iceResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
	return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("iceResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
	return (  self.baseRate *  math.min(   1 - math.min( status.stat("iceResistance",0) ),0.25))
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


-- alert the player that they are affected
function activateVisualEffects()
	effect.setParentDirectives("fade=3066cc=0.6")
end

function deactivateVisualEffects()
	effect.setParentDirectives("fade=3066cc=0.0")
end

-- ice breath
function makeAlert()
	local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	world.spawnProjectile("iceinvis",mouthPosition,entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
end


function update(dt)
	checkEffectValid()
	self.timerRadioMessage = self.timerRadioMessage - dt
	-- set the base stats
	self.baseRate = config.getParameter("baseRate",0)
	self.baseDmg = config.getParameter("baseDmgPerTick",0)
	self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
	self.biomeTemp = config.getParameter("biomeTemp",0)
	self.biomeThreshold = config.getParameter("biomeThreshold",0)
	self.biomeNight = config.getParameter("biomeNight",0)
	self.situationPenalty = config.getParameter("situationPenalty",0)
	self.liquidPenalty = config.getParameter("liquidPenalty",0)

	self.baseRate = setEffectTime()

	-- environment checks
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()
	local dry = isDry()

	if isEntityAffected() then
		self.biomeTimer = self.biomeTimer - dt
		if (self.biomeTimer <= 0) then
			-- Cold weather is worse when windy.
			if not (self.windLevel < 40 or underground) then
				setWindPenalty()
				if (self.timerRadioMessage <=0) then
					if not self.usedWind then
						world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomecoldwind", 1.0) -- send player a warning
						self.timerRadioMessage = 10
						self.usedWind = 1
					end
				end
			end
			-- Cold weather is worse when in liquid.
			if not dry then
				setLiquidPenalty()
				if (self.timerRadioMessage <= 0) then
						if not self.usedWater then
							world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldwater", 1.0) -- send player a warning
							self.timerRadioMessage = 10
							self.usedWater = 1
						end
				end
			end
			-- Cold weather is worse at night.
			if not (daytime or underground) then
				setNightPenalty()
				if (self.timerRadioMessage <= 0) then
					if not self.usedNight then
						world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldnight", 1.0) -- send player a warning
						self.timerRadioMessage = 10
						self.usedNight = 1
					end
				end
			end
			self.biomeTimer = self.baseRate
		end
		-- Set damage totals.
		self.damageApply = setEffectDamage()
		self.debuffApply = setEffectDebuff()
		-- Set movement penalties.
		self.modifier = math.max(status.stat("iceResistance", 0), 0) + 0.3
		-- Apply HP drain.
		status.modifyResource("health", -self.damageApply * dt)
		-- Apply hunger drain (if not casual).
		if status.isResource("food") then
			if (status.resource("food") >= 2) then
				status.modifyResource("food", -self.debuffApply * dt / 120)
			end
		end
		-- Apply movement penalties.
		mcontroller.controlModifiers({
			airJumpModifier = self.modifier,
			speedModifier = self.modifier - 0.1
		})
	end -- isEntityAffected()
	-- Add frosted breath effect (regardless of player status).
	self.biomeTimer2 = self.biomeTimer2 - dt
	if self.biomeTimer2 <= 0 then
		makeAlert() --misty breath
		self.biomeTimer2 = 2.4
	end
end

function uninit()

end
