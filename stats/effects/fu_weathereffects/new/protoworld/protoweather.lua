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

  checkEffectValid()

  script.setUpdateDelta(5)
end


--******* check effect and cancel ************
function checkEffectValid()
  if world.entityType(entity.id()) ~= "player" then
    deactivateVisualEffects()
    effect.expire()
  end
	if status.statPositive("protoImmunity") or world.type()=="unknown" then
	  deactivateVisualEffects()
	  effect.expire()
	end

	-- checks strength of effect vs resistance
	if ( status.stat("poisonResistance",0)  >= self.effectCutoffValue ) then
	  deactivateVisualEffects2()
	  deactivateVisualEffects()
	  effect.expire()
	else
	  -- activate visuals and check stats
	  if not self.usedIntro and (self.timerRadioMessage == 0) then
	    world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomeproto", 1.0) -- send player a warning
	    self.usedIntro = 1
	    self.timerRadioMessage = 20
	  end	
	end
end


-- *******************Damage effects
function setEffectDamage()
  return ( ( self.baseDmg ) *  (1 -status.stat("poisonResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("poisonResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
  return (  self.baseRate *  math.min(   1 - math.min( status.stat("poisonResistance",0) ),0.45))
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

--**** Alert the player
function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("coldbreath", true) 
end

function activateVisualEffects2()
  effect.setParentDirectives("fade=306630=0.35")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function deactivateVisualEffects()
    animator.setParticleEmitterActive("coldbreath", false) 
end
function deactivateVisualEffects2()
  effect.setParentDirectives("fade=306630=0")
end

-- visual indicator for effect
function makeAlert()  
        world.spawnProjectile("poisonsmoke",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
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
  local lightLevel = getLight() 
  daytime = daytimeCheck()
  underground = undergroundCheck() 

      if self.biomeTimer <= 0 and status.stat("poisonResistance",0) < self.effectCutoffValue then
          
	  if not daytime then
	    setSituationPenalty()
	  end
	  self.damageApply = setEffectDamage()   
	  self.debuffApply = setEffectDebuff()       
         -- damage application per tick
          status.applySelfDamageRequest ({
            damageType = "IgnoresDef",
            damage = self.damageApply,
            damageSourceKind = "poison",
            sourceEntityId = entity.id()	
          })   

	  activateVisualEffects()

          self.biomeTimer = self.baseRate
      end 
      if self.biomeTimer2 <= 0 and status.stat("poisonResistance",0) < self.effectCutoffValue then  
          if status.stat("critChance",0) >=1 then
          effect.addStatModifierGroup({
            {stat = "maxHealth", amount = -self.debuffApply },
            {stat = "critChance", amount = -self.debuffApply }
          })
          else
          effect.addStatModifierGroup({
            {stat = "maxHealth", amount = -self.debuffApply }
          })          
          end
          activateVisualEffects2()
          self.biomeTimer2 = (self.biomeTimer * (1 + status.stat("poisonResistance",0))) * 2 
      end    
          
end         

function uninit()

end