--edit notes from bk3000 aka bk3k
--
--efficiency improvement by not calculating truepos over and over when the location won't change!
--plus a small improvement in update()
--and make sure line 34 - 36 is as intended... seems like that might not me and could be done more efficiently by
--checking against larger values first combined with if, elseif, elseif, elseif to set the actual desired value

function init(virtual)
	if virtual == true then return end
	storage.checkticks = 0
	storage.truepos = storage.truepos or {entity.position()[1] + math.random(2,3), entity.position()[2] + 1}
  --if not nil, no reassignment.  If nil then gets assigned
  --although I honestly do no understand why the random 'x' offset but I left it intact
end

function update(dt)
	storage.checkticks = storage.checkticks + 1
	--if storage.checkticks >= 10 then
  if storage.checkticks > 9 then --slightly more efficient because >= is equivalent to n > v or n == v
		storage.checkticks = 0
		isn_getCurrentPowerOutput()
	end
end

function isn_getCurrentPowerOutput(divide)
	if isn_powerGenerationBlocked then
		animator.setAnimationState("meter", "0")
		return 0
	end
	
	local generated = 0
	local genmult = 2
	local light = world.lightLevel(location)
	if light > 0.1 then generated = generated + 0.25 end
	if light > 0.3 then generated = generated + 0.35 end
	if light > 0.5 then generated = generated + 0.45 end
	if light > 0.7 then generated = generated + 0.55 end
  --just to check your intention here, the 4 checks are no mutually exclusive so if light > 0.7 then 
  --generated is going to actually increase 1.6 in total, not 0.55 thanks to a compound increase
	
	if storage.truepos[2] < 500 then genmult = 1
	elseif storage.truepos[2] > 900 then genmult = 5 
	elseif storage.truepos[2] > 700 then genmult = 3 end
	
	generated = generated * genmult
	generated = math.min(generated,6)
	
	local summationForDebug = string.format("P %.2f L %.2f", generated, light)
	world.debugText(summationForDebug,{location[1]-(string.len(summationForDebug)*0.25),location[2]-3.5},"cyan")
	
	if generated >= 4 then animator.setAnimationState("meter", "4")
	elseif generated >= 3  then animator.setAnimationState("meter", "3")
	elseif generated >= 2 then animator.setAnimationState("meter", "2")
	elseif generated >= 1 then animator.setAnimationState("meter", "1")
	else animator.setAnimationState("meter", "0")
	end
	
	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)
	if divisor < 1 then return 0 end
	
	if divide == true then return generated / divisor
	else return generated end
end

function onNodeConnectionChange()
	if isn_checkValidOutput() == true then object.setOutputNodeLevel(0, true)
	else object.setOutputNodeLevel(0, false) end
end

function isn_powerGenerationBlocked()
	-- Power generation does not occur if...
	--if world.info == nil then return true end -- it's on a ship (doesn't work right now)
	local location = storage.truepos
	if world.underground(location) or world.liquidAt(location) or world.tileIsOccupied(location,false) or 
    world.lightLevel(location) < 0.2 then return true 
  else return false --no false return when the other option is true?!
  end 
  --LUA won't call what's to the right of 'or' if it got value beyond false or nil to the left of it
  --so making so many seperate statements isn't necessary so I combined them.
  --strickly speaking that probably wasn't necessary to do
end

function isn_getTruePosition()  --in case this is called externally, otherwise I'd delete it
	return storage.truepos
end
