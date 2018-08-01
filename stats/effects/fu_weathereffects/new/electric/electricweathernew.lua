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
	
	--timer stuff
	warningResource1="biomeelectricsurfacewarning"
	warningResource2="biomeelectricwaterwarning"
	self.biomeTimer = self.baseRate
	self.biomeTimer2 = (self.baseRate * (1 + status.stat("electricResistance",0)) *10)
	
	--conditionals
	zapped=effect.addStatModifierGroup({})
	self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
	self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
	self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
	self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
	self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?
	checkEffectValid()

	script.setUpdateDelta(5)
end

--******* check effect and cancel ************
function checkEffectValid()
	if not status.isResource("energy") or not entity.entityType("player") or entity.entityType("npc") or (status.stat("electricResistance",0)  >= self.effectCutoffValue) or status.statPositive("biomeelectricImmunity") or world.type()=="unknown" then
		effect.expire()
	end
end

-- *******************penalties
function setEffectTime()
	return self.baseRate * math.min(1 - math.min( status.stat("electricResistance",0) ),0.45)
end

function calcDebuff()
	return (self.baseDebuff * self.biomeTemp) * (1 - status.stat("electricResistance",0) * self.biomeThreshold) + (not world.underground(mcontroller.position()) and self.situationPenalty or 0) + (isWet() and self.liquidPenalty or 0)
end

function isWet()
	local liquid=mcontroller.liquidId()
	local entityPos=mcontroller.position()
	local mouthPos=world.entityMouthPosition(entity.id()) or {0,0}
	--sb.logInfo("%s %s",entityPos,mouthPos)
	return entityPos and (world.liquidAt(vec2.add(entityPos, mouthPos)) and ((liquid==1) or (liquid==6) or (liquid==58) or (liquid==12)))
end



function update(dt)
	checkEffectValid()
	
	self.biomeTimer = self.biomeTimer - dt
	self.biomeTimer2 = self.biomeTimer2 - dt
	
	if not world.underground(mcontroller.position()) then
		if status.isResource(warningResource1) then
			if not status.resourcePositive(warningResource1) then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeelectricsurface", 1.0)
			end
			status.setResourcePercentage(warningResource1,1.0)
		else
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeelectricsurface", 30.0)
		end
	end
	
	if isWet() then
		if status.isResource(warningResource2) then
			if not status.resourcePositive(warningResource2) then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeelectricwater", 1.0)
			end
			status.setResourcePercentage(warningResource2,1.0)
		else
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeelectricwater", 1.0)
		end
	end
	
	self.debuffApply = calcDebuff() / 120
	effect.setStatModifierGroup(zapped,{
		{stat = "maxEnergy", baseMultiplier = 0.5},
		{stat = "energyRegenPercentageRate", amount = status.stat("energyRegenPercentageRate") -self.debuffApply },
		{stat = "energyRegenBlockTime", amount = status.stat("energyRegenBlockTime") + self.debuffApply }
	})
end

function uninit()

end