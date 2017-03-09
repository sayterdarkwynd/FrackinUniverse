require("/scripts/vec2.lua")
function init()
  -- Environment Configuration --

  --first, the modifier for temperature
  self.biomeTemp = config.getParameter("biomeTemp",0)
  self.windLevel =  world.windLevel(mcontroller.position())
  self.radioMessageTimer = 1
  self.baseDmg = config.getParameter("baseDmgPerTick",0)
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
  self.baseRate = config.getParameter("baseRate",0)
  self.biomeThreshold = config.getParameter("biomeThreshold",0)
  self.biomeNight = config.getParameter("biomeNight",0)
  self.situationPenalty = config.getParameter("situationPenalty",0)
  self.liquidPenalty = config.getParameter("liquidPenalty",0)
  
  self.biomeTimer = config.getParameter("baseRate",0)
  self.biomeTimer2= (self.biomeTimer * (1 - status.stat("radioactiveResistance"))) * 100

  
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeradiation", 1.0) -- send player a warning
  
  self.timerRadioMessage = 0
  script.setUpdateDelta(5)
end

-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=33dd15=0.7")
  animator.setParticleEmitterOffsetRegion("radioactivebreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("radioactivebreath", true) 
end

function setEffectDamage()
  return ( ( self.baseDmg + self.situationPenalty + self.liquidPenalty + self.biomeNight ) *  ( self.baseRate * (1 -status.stat("radioactiveResistance",0) ) * self.biomeTemp  ) )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff + self.liquidPenalty + self.biomeNight ) * self.biomeTemp ) * (1 -status.stat("radioactiveResistance") * self.baseRate) )
end

function setEffectTime()
  return (( self.baseDebuff * self.baseRate ) * (1 -status.stat("radioactiveResistance")))
end


function update(dt)
  self.damageApply = setEffectDamage()
  self.debuffApply = setEffectDebuff()

      if self.biomeTimer <= 0 and status.stat("radioactiveResistance") < 1.0 then
	self.timerRadioMessage = self.timerRadioMessage - dt 
	
          -- fallout
          self.windLevel =  world.windLevel(mcontroller.position())
          sb.logInfo("wind : "..self.windLevel)
          if self.windLevel >= 20 then
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeradiationwind", 1.0) -- send player a warning
                  self.timerRadioMessage = 60
		end
          end

          -- activate visuals and check stats
	  activateVisualEffects()
          makeAlert()  
            effect.addStatModifierGroup({
              {stat = "maxHealth", amount = -self.baseDebuff  },
              {stat = "powerMultiplier", amount = -(self.baseDebuff/100 )  }
            })
          self.biomeTimer = self.baseRate
      end 
        
      if status.stat("radioactiveResistance") <=0.99 then      
	     self.damageApply = (self.damageApply * (1+ (self.windLevel/100))  /100)  
	     status.modifyResource("health", -self.damageApply * dt)
	   
	   if status.isResource("food") then
	     self.debuffApply = (self.debuffApply * (1+ (self.windLevel/100)) /10) 
	     if status.resource("food") >= 2 then
	       status.modifyResource("food", -self.debuffApply * dt )
	     end
           end     
      end  
      self.biomeTimer = self.biomeTimer - dt
end       

function makeAlert()
        world.spawnProjectile("poisonsmoke",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
 	animator.playSound("bolt")
end

function uninit()

end