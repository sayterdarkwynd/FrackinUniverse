require "/scripts/vec2.lua"
require "/scripts/util.lua"

fuWeatherLib={}
fuWeatherLib.timerFuncs={}
fuWeatherLib.timerIntervals={}
fuWeatherLib.timerCounters={}


function fuWeatherLib.init()
	-- Environment Configuration --
	--base values
	
	-- level at which resistance stops the effect
	self.effectCutoff = config.getParameter("effectCutoff",0)
        self.effectCutoffValue = config.getParameter("effectCutoffValue",0)
        
        -- base infliction rate of the effect
	self.baseRate = config.getParameter("baseRate",0)
	
	-- base damage per tick
	self.baseDmg = config.getParameter("baseDmgPerTick",0)
	self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
	
	-- biome temperature modifier
	self.biomeTemp = config.getParameter("biomeTemp",0)			
	
	-- biome Level
	self.threatLevel = world.threatLevel()
	
	--set final biomeTemp
	self.biomeTemp = (self.biomeTemp) + ((self.threatLevel/25))
	
	self.biomeThreshold = config.getParameter("biomeThreshold",0)		-- base Modifier
	
	-- situational modifiers
	self.biomeNightModifier = config.getParameter("biomeNightModifier",1)	-- if set to anything other than one, multiplies base by that during night
	self.biomeDayModifier = config.getParameter("biomeDayModifier",1)	-- if set to anything other than one, multiplies base by that during day
	self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
	self.liquidPenalty = config.getParameter("liquidPenalty",0)			-- does liquid make things worse? how much?

	-- activate visuals and check stats
	activateVisualEffects()
	for i,f in pairs(fuWeatherLib.biomeFuncs) do
		fuWeatherLib.biomeTimers[i]=0
	end
	
	script.setUpdateDelta(5)

end

function fuWeatherLib.update(dt)
	for i,t in pairs(fuWeatherLib.timerCounters) do
		fuWeatherLib.timerCounters[i]=t+dt
	end
	for i,t in pairs(fuWeatherLib.timerCounters) do
		if t > fuWeatherLib.timerIntervals[i] then
			fuWeatherLib.timerFuncs[i](dt)
			fuWeatherLib.timerCounters[i]=0
		end
	end
end

function fuWeatherLib.applyDamage(resistType,resource,damage)
	if status.stat(resistType,0) < 1 then
		status.modifyResource(resource, -damage * dt)

	end
end

function fuWeatherLib.applyDebuff(resistType,resource)
	if status.stat(resistType,0) < 1 then
		if status.resourcePercentage(resource) <= 0.25 then
		mcontroller.controlModifiers({
			airJumpModifier = status.stat(resistType,0),
			speedModifier = status.stat(resistType,0)
		})
		end
	end
end


function fuWeatherLib.message(message)
	world.sendEntityMessage(entity.id(), "queueRadioMessage", message, 1.0)
end

function fuWeatherLib.getEffectDamage(resistType,rMax,rMin)
	local temp=fuWeatherLib.getEffectscale(resistType,rMax,rMin)
	temp=temp*self.baseDmg
	return temp
end

function fuWeatherLib.getEffectDebuff(resistType,rMax,rMin)
	local temp=fuWeatherLib.getEffectscale(resistType,rMax,rMin)
	--return self.biomeTemp
	temp=temp*self.baseDebuff
	return temp
end

function fuWeatherLib.getEffectscale(resistType,rMax,rMin)
	local temp=status.stat(resistType,0)
	
	if rMin and rMax then
		if rMax<rMin then
			local temp2=rMax
			rMax=rMin
			rMin=temp2
		end
	end
	if rMin then
		temp=math.max(temp,rmin)
	end
	if rMax then
		temp=math.min(temp,rMax)
	end
	
	temp=(1-temp) * self.biomeThreshold
	if world.timeOfDay() >= 0.5 and self.biomeNightModifier then
		temp=temp*self.biomeNightModifier
	elseif world.timeOfDay() < 0.5 and self.biomeDayPenalty then
		temp=temp*self.biomeDayPenalty
	end
	return temp
end


function fuWeatherLib.getEffectTime(resistType)
	return self.baseRate * math.max((1 + math.min(status.stat(resistType,0)),0.01)
end

-- ********************************
function checkEffectValid()
	  if world.entityType(entity.id()) ~= "player" then
	    deactivateVisualEffects()
	    effect.expire()
	  end
	if status.statPositive("aetherImmunity") or world.type()=="unknown" then
	  effect.expire()
	end

	-- checks strength of effect vs resistance
	if (config.getParameter("biomeTemp",0) == 2) and ( self.effectCutoff  >= self.effectCutoffValue ) then
	  deactivateVisualEffects()
	  effect.expire()
	elseif (config.getParameter("biomeTemp",0) == 3) and ( self.effectCutoff  >= self.effectCutoffValue ) then
	  deactivateVisualEffects()
	  effect.expire()   
	elseif (config.getParameter("biomeTemp",0) == 4) and ( self.effectCutoff  >= self.effectCutoffValue ) then
	  deactivateVisualEffects()
	  effect.expire() 
	else
	  -- activate visuals and check stats
	    if not self.usedIntro then
	      -- activate visuals and check stats
	     world.sendEntityMessage(entity.id(), "queueRadioMessage", message, 1.0) -- send player a warning
	      self.usedIntro = 1
	    end
	  activateVisualEffects()	
	end
end

function liquidInMouth()
	local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	return(world.liquidAt(mouthposition))
end

--**** Other functions
function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = world.lightLevel(position)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
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


function threatLevel()
	return world.threatLevel()
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end

function windLevel()
	return world.windLevel(mcontroller.position())
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 
end