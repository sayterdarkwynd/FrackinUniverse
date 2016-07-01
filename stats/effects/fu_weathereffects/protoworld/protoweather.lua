function init()
  script.setUpdateDelta(5)

  animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("coldbreath", true)
  
  --config --
  biomeDay = effect.configParameter("biomeDay",0)
  biomeNight = effect.configParameter("biomeNight",0)
  biomeRate = math.random(biomeDay, biomeNight)
  biomeDmg = math.random(biomeDay, biomeNight)
  world.setProperty ("biomeEffect", biomeTemp)
  world.setProperty ("biomemainRate", biomeRate)
  biomeTimer = 10
  biomeDate = world.day()
  local bounds = mcontroller.boundBox()
  effect.setParentDirectives("fade=ffea00=0.027")
  baseValue = effect.configParameter("biomeDmgPerTick")
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
		--	biomeTimer = 35
 
		if world.time() <= 0.8 then
			biomeDmg = biomeDmg +1
			biomeTimer = 35
		elseif world.time() <= 0.7 then
 			biomeDmg = biomeDmg +1
 			biomeTimer = 33
		elseif world.time() <= 0.6 then
			biomeDmg = biomeDmg +2
			biomeTimer = 31
		elseif world.time() <= 0.5 then
			biomeDmg = biomeDmg +2
			biomeTimer = 29
		elseif world.time() <= 0.4 then
			biomeDmg = biomeDmg +3
			biomeTimer = 27
		elseif world.time() <= 0.3 then
			biomeDmg = biomeDmg +3
			biomeTimer = 25
		elseif world.time() <= 0.2 then
			biomeDmg = biomeDmg +4
			biomeTimer = 22
		elseif world.time() <= 0.1 then
			biomeDmg = biomeDmg +4
			biomeTimer = 19
		elseif world.time() <= 0.05 then
			biomeDmg = biomeDmg +5
			biomeTimer = 17
		else
			biomeDmg = biomeDmg +5
			biomeTimer = 15		
		end 		
        if world.time() <= 0.5 and biomeDmg <= biomeDay then
          status.applySelfDamageRequest ({
          damageType = "IgnoresDef",
          damage = biomeDmg+5,
          damageSourceKind = "nitrogenweapon",
          sourceEntityId = entity.id(),  
          biomeTimer = 15	
          })       
        end
        
        if world.time() > 0.5 and biomeDmg <= biomeNight then
          status.applySelfDamageRequest ({
          damageType = "IgnoresDef",
          damage = biomeDmg,
          damageSourceKind = "nitrogenweapon",
          sourceEntityId = entity.id(),  
          biomeTimer = 15	
          })       
        end
      
      
      
  

      end	
	
	
end

function uninit()

end