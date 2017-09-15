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
  -- set desaturation effect
  self.multiply = config.getParameter("multiplyColor")
  self.saturation = 0

  checkEffectValid()

  script.setUpdateDelta(5)
end

--******* check effect and cancel ************
function checkEffectValid()
  if world.entityType(entity.id()) ~= "player" then
    deactivateVisualEffects()
    effect.expire()
  end
	if status.statPositive("insanityImmunity") or world.type()=="unknown" then
	  deactivateVisualEffects()
	  effect.expire()
	end

	if (status.stat("cosmicResistance",0)  >= self.effectCutoffValue) then
	  deactivateVisualEffects()
	  effect.expire()
	else
	  -- inform them they are ill
	  if not self.usedIntro then
	    world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomeinsanity", 1.0) 
	    self.usedIntro = 1
	  end

	  messageCheck()
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
    self.biomeThreshold = self.biomeThreshold + (self.windlevel / 100)
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

function messageCheck()
  if self.timerRadioMessage == 0 then
          self.liquidPercent = mcontroller.liquidPercentage()
	  if (self.liquidPercent) >= 0.5 then
			   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectliquid", 1.0) 
			   self.timerRadioMessage = 600  
	  end
	  self.velocityVal = mcontroller.xVelocity()
	  if (self.velocityVal) >= 10 then
			   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectfast", 1.0) 
			   self.timerRadioMessage = 600  
	  end

	  if mcontroller.zeroG() then
			   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectgrav", 1.0) 
			   self.timerRadioMessage = 600  
	  end  

	  if not mcontroller.onGround() then
			   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectair", 1.0) 
			   self.timerRadioMessage = 600  
	  end 
  end
  
  self.hungerLevel = hungerLevel()
        if (self.windLevel >= 20) then
                if self.timerRadioMessage == 0 then
                  if not self.usedWind then
                    world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectwindy", 1.0) 
                    self.timerRadioMessage = 5
                    self.usedWind = 1
                  end
		end
        end
        if status.isResource("food") then
	     if ( self.hungerLevel <= 5) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry4", 1.0) 
                   self.timerRadioMessage = 20
             elseif (self.hungerLevel <= 10) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry3", 1.0) 
                   self.timerRadioMessage = 20
             elseif (self.hungerLevel <= 20) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry2", 1.0) 
                   self.timerRadioMessage = 20
             elseif (self.hungerLevel <= 30) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry1", 1.0) 
                   self.timerRadioMessage = 20
             elseif (self.hungerLevel <= 40) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry5", 1.0) 
                   self.timerRadioMessage = 20
             elseif (self.hungerLevel <= 50) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry6", 1.0) 
                   self.timerRadioMessage = 20
             elseif (self.hungerLevel <= 60) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry7", 1.0) 
                   self.timerRadioMessage = 20
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
self.biomeTimer = self.biomeTimer - dt
self.biomeTimer2 = self.biomeTimer2 - dt
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
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight()

      if (status.stat("cosmicResistance") < self.effectCutoffValue) then
             mcontroller.controlModifiers({
	         speedModifier = (-status.stat("cosmicResistance",0))-0.2
             })
             activateVisualEffects()
      end

      if (self.biomeTimer <= 0) and (status.stat("cosmicResistance",0) < self.effectCutoffValue) then
	status.modifyResource("health", -self.damageApply * dt)
	status.modifyResource("food", -self.damageApply * dt)

	activateVisualEffects()
	if (self.timerRadioMessage <= 0) then
          messageCheck()
        else
	  self.timerRadioMessage = self.timerRadioMessage - dt
        end
        self.biomeTimer = self.baseRate
      end

      if (self.biomeTimer2 <= 0) and (status.stat("cosmicResistance",0) < 1.0) then
            effect.addStatModifierGroup({
              {stat = "protection", amount = -self.baseDebuff  },
              {stat = "maxEnergy", amount = -(self.baseDebuff*2)  }
            })
        makeAlert()
        self.biomeTimer2 = (self.biomeTimer * (1 + status.stat("cosmicResistance",0))) * 2
      end
end

function uninit()

end
