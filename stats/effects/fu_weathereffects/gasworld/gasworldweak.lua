function init()
  script.setUpdateDelta(5)

  animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("coldbreath", true)
  
  --config --
  biomeDay = config.getParameter("biomeDay",0)
  biomeNight = config.getParameter("biomeNight",0)
  biomeRate = math.random(biomeDay, biomeNight)
  biomeDmg = math.random(biomeDay, biomeNight)
  world.setProperty ("biomeEffect", biomeTemp)
  world.setProperty ("biomemainRate", biomeRate)
  biomeTimer = 5
  biomeDate = world.day()
  local bounds = mcontroller.boundBox()
  effect.setParentDirectives("fade=ffea00=0.027")
  baseValue = config.getParameter("biomeDmgPerTick")
  activateVisualEffects()
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
		--if lightLevel > 95 then
		--	biomeDmg = biomeDmg +1
		--	biomeTimer = 5
 		makeAlert()
 		  activateVisualEffects()
		if world.time() <= 0.8 then
			biomeDmg = biomeDmg +1
			biomeTimer = 5
			makeAlert()
			activateVisualEffects()
		elseif world.time() <= 0.7 then
 			biomeDmg = biomeDmg +1
 			biomeTimer = 5
 			makeAlert()
 			activateVisualEffects()
		elseif world.time() <= 0.6 then
			biomeDmg = biomeDmg +2
			biomeTimer = 5
			makeAlert()
			activateVisualEffects()
		elseif world.time() <= 0.5 then
			biomeDmg = biomeDmg +2
			biomeTimer = 4
			makeAlert()
			activateVisualEffects()
		elseif world.time() <= 0.4 then
			biomeDmg = biomeDmg +3
			biomeTimer = 4
			makeAlert()
			activateVisualEffects()
		elseif world.time() <= 0.3 then
			biomeDmg = biomeDmg +3
			biomeTimer = 4
			makeAlert()
			activateVisualEffects()
		elseif world.time() <= 0.2 then
			biomeDmg = biomeDmg +4
			biomeTimer = 4
			makeAlert()
			activateVisualEffects()
		elseif world.time() <= 0.1 then
			biomeDmg = biomeDmg +4
			biomeTimer = 4
			makeAlert()
			activateVisualEffects()
		elseif world.time() <= 0.05 then
			biomeDmg = biomeDmg +5
			biomeTimer = 3
			makeAlert()
			activateVisualEffects()
		else
			biomeDmg = biomeDmg +5
			biomeTimer = 3	
			makeAlert()
			activateVisualEffects()
			
		end 		
        if world.time() <= 0.5 and biomeDmg <= biomeDay then
          status.applySelfDamageRequest ({
          damageType = "IgnoresDef",
          damage = biomeDmg+5,
          damageSourceKind = "fire",
          sourceEntityId = entity.id(),  
          biomeTimer = 3	
          })       
	makeAlert()     
	activateVisualEffects()
        end
        
        if world.time() > 0.5 and biomeDmg <= biomeNight then
          status.applySelfDamageRequest ({
          damageType = "IgnoresDef",
          damage = biomeDmg,
          damageSourceKind = "ice",
          sourceEntityId = entity.id(),  
          biomeTimer = 5	
          })   
	makeAlert()      
	activateVisualEffects()
        end
      
      
      
  

      end	
	
	
end

function uninit()

end