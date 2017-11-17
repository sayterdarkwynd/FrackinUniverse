require '/scripts/power.lua'

function update(dt)
	storage.checkticks = (storage.checkticks or 0) + dt
	if storage.checkticks >= 10 then
	  storage.checkticks = storage.checkticks - 10
	  if isn_powerGenerationBlocked() then
		animator.setAnimationState("meter", "0")
		power.setPower(0)
	  else
	    local location = isn_getTruePosition() 
	    local light = getLight(location)
	    local powerLevel = config.getParameter("powerLevel",1) 
                genmult = 1
                if (light) <= 0.38 then genmult = 1
		elseif (light) >= 0.85 then genmult = 4 * (1 + light)	                  
		elseif (light) >= 0.75 then genmult = 4	  
		elseif (light) >= 0.65 then genmult = 3 
		elseif (light) >= 0.55 then genmult = 2 		  
		elseif (light) <= 0 then genmult = 0 
		end	  
		
		if world.type() == 'playerstation' then  genmult = 3.75 end -- player space station always counts as high power, but never MAX power.
		if world.liquidAt(location) then genmult = genmult * 0.5 end -- water halves the output
		
		local generated = math.min(powerLevel * genmult,36) -- max at 36 just in case.	

		if genmult >=4 then animator.setAnimationState("meter", "4")
		elseif genmult > 3 then 
		  animator.setAnimationState("meter", "3")
		elseif genmult > 2 then 
		  animator.setAnimationState("meter", "2")
		elseif genmult > 0 then 
		  animator.setAnimationState("meter", "1")
		else 
		  animator.setAnimationState("meter", "0")
		end
	        power.setPower(generated)
	  end
	end
	power.update(dt)
end

function getLight(location)
  local objects = world.objectQuery(entity.position(), 20)
  local lights = {}
  for i=1,#objects do
	local light = world.callScriptedEntity(objects[i],'object.getLightColor')
	if light and (light[1] > 0 or light[2] > 0 or light[3] > 0) then
	  lights[objects[i]] = light
	  world.callScriptedEntity(objects[i],'object.setLightColor',{light[1]/3,light[2]/3,light[3]/3})
	end
  end
  local light = world.lightLevel(location)
  for key,value in pairs(lights) do
    world.callScriptedEntity(key,'object.setLightColor',value)
  end
  return light
end

function isn_powerGenerationBlocked()
    -- Power generation does not occur if...
    local location = isn_getTruePosition()
    return world.underground(location) or world.lightLevel(location) < 0.2 --or world.type == 'unknown'
end	
	
function isn_getTruePosition()
  storage.truepos = storage.truepos or {entity.position()[1] + math.random(2,3), entity.position()[2] + 1}
  return storage.truepos
end