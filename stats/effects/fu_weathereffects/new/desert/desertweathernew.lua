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
	self.biomeTimer2 = (self.baseRate * (1 + status.stat("fireResistance",0)) *10)

	--conditionals

	self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
	self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
	self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
	self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
	self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?

	checkEffectValid()
	self.gracePeriod = 10
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
	if (status.statPositive("biomeheatImmunity") or
	status.statPositive("ffextremeheayImmunity") or
	(status.stat("fireResistance",0)  >= self.effectCutoffValue)) then
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
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesert", 1.0)
			self.usedIntro = 1
			self.timerRadioMessage = 220
		end
	end
end

-- *******************Damage effects

function setEffectDamage()
	return ( ( self.baseDmg ) *  (1 -status.stat("fireResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
	return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("fireResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
	return (  self.baseRate *  math.min(   1 - math.min( status.stat("fireResistance",0) ),0.5))
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

--**** Alert the player
function activateVisualEffects()
	effect.setParentDirectives("fade=ff7600=0.05")
	--animator.setParticleEmitterOffsetRegion("firebreath", mcontroller.boundBox())
	--animator.setParticleEmitterActive("firebreath", true)
end

function deactivateVisualEffects()
	effect.setParentDirectives("fade=ff7600=0.0")
	--animator.setParticleEmitterActive("firebreath", false)
end


function makeAlert()
	world.spawnProjectile("fireinvis",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
	animator.playSound("bolt")
end



function update(dt)
	checkEffectValid()
	-- self.biomeTimer2 = self.biomeTimer2 - dt
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
		-- Desert heat only applies during the day.
		if daytime then
			-- Check underground or wet conditions which pause heat effects.
			-- Going underground reduces biome temperature and provides 60 sec immunity after leaving.
			if underground then
				self.biomeTemp = self.biomeTemp / 4
				self.gracePeriod = 60
				if not self.usedCavernous then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertunderground", 1.0) -- send player a warning
					self.timerRadioMessage = 10
					self.usedCavernous = 1
				end
			-- Getting wet provides 60 sec immunity after leaving.
			elseif not dry then
				setLiquidPenalty() -- Less than 1.
				if (self.timerRadioMessage <= 0) then
					if not self.usedWater then
						world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertwater", 1.0) -- send player a warning
						self.timerRadioMessage = 10
						self.gracePeriod = 60
						self.usedWater = 1
					end
				end
			end
			-- Only apply effects if underground/wet/night immunity has worn off.
			if (self.gracePeriod <= 0) then
				self.biomeTimer = self.biomeTimer - dt
				if (self.biomeTimer <= 0) then
					-- Desert heat is worse during the day.
					if lightLevel >= 75 then
						self.situationPenalty = self.situationPenalty + 0.5
						if not self.usedNoon then
							world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertnoon", 1.0) -- send player a warning
							self.timerRadioMessage = 10
							self.usedNoon = 1
						end
					elseif lightLevel >= 15 then
						if not self.usedSunrise then
							world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertsunrise", 1.0) -- send player a warning
							self.timerRadioMessage = 10
							self.usedSunrise = 1
						end
					else
						self.situationPenalty = config.getParameter("situationPenalty",0)
					end
					self.biomeTimer = self.baseRate
				end -- self.biomeTimer <= 0
				-- Set damage totals.
				self.damageApply = setEffectDamage()
				self.debuffApply = setEffectDebuff()
				-- Apply health drain.
				status.modifyResource("health", -self.damageApply * dt)
				-- If player has low health, penalise movement.
				if (status.resource("health")) <= (status.stat("maxHealth",0)/4) then
					mcontroller.controlModifiers({
						airJumpModifier = 0.85,
						speedModifier = 0.85
					})
				end
			else -- if self.gracePeriod > 0 then
				self.gracePeriod = self.gracePeriod - dt
			end
		-- Display night message (if not yet shown).
		else -- if not daytime then
			self.gracePeriod = 60
			if (self.timerRadioMessage <= 0) then
				if not self.usedNight then
					world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertnight", 1.0) -- send player a warning
					self.timerRadioMessage = 10
					self.usedNight = 1
				end
			end
		end
	end -- isEntityAffected()
end

function uninit()

end
