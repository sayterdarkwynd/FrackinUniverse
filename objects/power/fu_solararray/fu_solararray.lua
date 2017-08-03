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
	    local light = world.lightLevel(location)
	    local genmult = 2
	
	    if location[2] < 500 then
	      genmult = 1
	    elseif location[2] > 900 then
	      genmult = 5 
	    elseif location[2] > 700 then
	      genmult = 3
	    end
		if world.liquidAt(location) then
		  genmult = genmult * 0.5
		end
	
	    local generated = math.min(light * 2 * genmult,12)
	
	    local summationForDebug = string.format("P %.2f L %.2f", generated, light)
	    world.debugText(summationForDebug,{location[1]-(string.len(summationForDebug)*0.25),location[2]-3.5},"cyan")
	
	    if generated >= 6 then animator.setAnimationState("meter", "4")
	    elseif generated >= 4  then animator.setAnimationState("meter", "3")
	    elseif generated >= 3 then animator.setAnimationState("meter", "2")
	    elseif generated >= 2 then animator.setAnimationState("meter", "1")
	    else animator.setAnimationState("meter", "0")
	    end
	    power.setPower(generated)
	  end
	end
	power.update(dt)
end

function isn_powerGenerationBlocked()
	-- Power generation does not occur if...
	local location = isn_getTruePosition()
	if world.type == 'unknown' then return true -- it's on a ship
	elseif world.underground(location) then return true -- it's underground
	elseif world.lightLevel(location) < 0.2 then return true end -- not enough light
end

function isn_getTruePosition()
  storage.truepos = storage.truepos or {entity.position()[1] + math.random(2,3), entity.position()[2] + 1}
  return storage.truepos
end