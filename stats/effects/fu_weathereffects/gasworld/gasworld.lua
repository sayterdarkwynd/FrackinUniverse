function init()
  script.setUpdateDelta(5)
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomepressure", 5.0)
  animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("coldbreath", true)
  
  --config --
  biomeDay = config.getParameter("biomeDay",0)
  biomeNight = config.getParameter("biomeNight",0)
  biomeRate = math.random(biomeDay, biomeNight)
  biomeDmg = math.random(biomeDay, biomeNight)
  world.setProperty ("biomeEffect", biomeTemp)
  world.setProperty ("biomemainRate", biomeRate)
  biomeTimer = 3
  biomeDate = world.day()
  local bounds = mcontroller.boundBox()
  effect.setParentDirectives("fade=ffea00=0.027")
  baseValue = config.getParameter("biomeDmgPerTick")
  activateVisualEffects()
  
  if status.stat("negativeMiasma") > 0 then
    effect.expire()
  end
end


function activateVisualEffects()
  effect.setParentDirectives("fade=306630=0.8")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end


function makeAlert()
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          entity.id(),
          directionTo,
          false,
          {
            power = 0,
            damageTeam = sourceDamageTeam
          }
        )
        animator.playSound("bolt")
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end
  
function update(dt)
      local lightLevel = getLight()
      biomeTimer = biomeTimer - dt
      
      if biomeTimer <= 0 then
        effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue* (-1) }})
 		makeAlert()
		biomeDmg = biomeDmg +2
		biomeTimer = 1.5
		makeAlert()
		activateVisualEffects()
		
			
				
        if world.time() <= 0.5 and biomeDmg <= biomeDay then
          status.applySelfDamageRequest ({
          damageType = "IgnoresDef",
          damage = biomeDmg+2,
          damageSourceKind = "poison",
          sourceEntityId = entity.id(),  
          biomeTimer = 2	
          })       
	makeAlert()     
	activateVisualEffects()
        end
        
        if world.time() > 0.5 and biomeDmg <= biomeNight then
          status.applySelfDamageRequest ({
          damageType = "IgnoresDef",
          damage = biomeDmg+2,
          damageSourceKind = "electric",
          sourceEntityId = entity.id(),  
          biomeTimer = 2	
          })   
	makeAlert()      
	activateVisualEffects()
        end
      
      
      
  

      end	
	
	
end

function uninit()

end