require("/scripts/vec2.lua")
function init()

	self.usedIntro = 0
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

	--conditionals
	self.windLevel =  world.windLevel(mcontroller.position(),0)        -- is there wind? we note that too
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
	if (status.statPositive("extremepressureProtection") or
	(status.stat("physicalResistance",0) >= self.effectCutoffValue)) then
		return false
	end
	-- otherwise, return true
	return true
end

--[[ Check if weather effect is still applicable and handle visual effects ]]--
function checkEffectValid()
	-- remove effect if no longer affected
	if not isEntityAffected() then
		deactivateVisualEffects()
		effect.expire()
	-- add visual effect and display warning (if not yet shown)
	else
		activateVisualEffects()
		-- display a random warning
		if (self.timerRadioMessage <= 0) and (self.usedIntro == 0) then
			local rand = math.random(4)
			if rand == 1 then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressure", 1.0) -- send player a warning
			elseif rand == 2 then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressure2", 1.0) -- send player a warning
			elseif rand == 3 then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressure3", 1.0) -- send player a warning
			else -- rand == 4, obviously
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressure4", 1.0) -- send player a warning
			end
			self.usedIntro = 1
			self.timerRadioMessage = 20
		end
	end
end

-- *******************Damage effects
function setEffectDamage()
	return ( ( self.baseDmg ) *  (1 -status.stat("physicalResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
	return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("physicalResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
		return (  self.baseRate *  math.min(   1 + math.min( status.stat("physicalResistance",0) )))
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
	if not world.liquidAt(mouthPosition) then
		inWater = 0
	end
end

function toHex(num)
	local hex = string.format("%X", math.floor(num + 0.5))
	if num < 16 then hex = "0"..hex end
	return hex
end

function hungerLevel()
	if status.isResource("food") then
		return status.resource("food")
	else
		return 50
	end
end

--*********alert the player that they are affected

function activateVisualEffects()
	effect.setParentDirectives("fade=306630=0.8")
end

function deactivateVisualEffects()
	effect.setParentDirectives("fade=306630=1.0")
end


function makeAlert()
	world.spawnProjectile( "teslaboltsmall", mcontroller.position(), entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
	animator.playSound("bolt")
	local statusTextRegion = { 0, 1, 0, 1 }
	animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
	animator.burstParticleEmitter("statustext")
end


function update(dt)
	checkEffectValid()

	self.timerRadioMessage = self.timerRadioMessage - dt

	self.windLevel =  world.windLevel(mcontroller.position()) or 1
	--set the base stats
	self.baseRate = config.getParameter("baseRate",0)
	self.baseDmg = config.getParameter("baseDmgPerTick",0)
	self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
	self.biomeTemp = config.getParameter("biomeTemp",0)
	self.biomeThreshold = config.getParameter("biomeThreshold",0)
	self.biomeNight = config.getParameter("biomeNight",0)
	self.situationPenalty = config.getParameter("situationPenalty",0)
	self.liquidPenalty = config.getParameter("liquidPenalty",0)


	self.damageApply = setEffectDamage()
	self.debuffApply = setEffectDebuff()

	-- environment checks
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()

	if isEntityAffected() then
		self.biomeTimer = self.biomeTimer - dt
		if ( self.biomeTimer <= 0 ) then
			-- Pressure is three times worse during the day. Not sure why.
			if daytime then
				if (self.timerRadioMessage <= 0) then
					if not self.usedIntro2 then
						world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressureday", 1.0) -- send player a warning
						self.usedIntro2 = 1
						self.timerRadioMessage = 220
					end
				end
				status.modifyResource("health", -self.damageApply * self.situationPenalty * 3 * dt)
			else
				if (self.timerRadioMessage <= 0) then
					if not self.usedIntro3 then
						world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressurenight", 1.0) -- send player a warning
						self.usedIntro3 = 1
						self.timerRadioMessage = 220
					end
				end
				status.modifyResource("health", -self.damageApply * self.situationPenalty * dt)
			end
			makeAlert()
			-- add wind modifiers
			if self.windLevel >= 40 then
				self.biomeThreshold = self.biomeThreshold + (self.windLevel / 100)
				if (self.timerRadioMessage <= 0) then
					if not self.usedWind then
						world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressurewind", 1.0) -- send player a warning
						self.timerRadioMessage = 220
						self.usedWind = 1
					end
				end
			end
			self.biomeTimer = setEffectTime()
		end -- self.biomeTimer <= 0
	end -- isEntityAffected()
end

function uninit()

end
