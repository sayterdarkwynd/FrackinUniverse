require "/scripts/kheAA/transferUtil.lua"

function init()
end

function heal(item)
	local healedParams = copy(item.parameters) or {}
	jremove(healedParams, "inventoryIcon")
	jremove(healedParams, "currentPets")
	for _,pet in pairs(healedParams.pets) do
		jremove(pet, "status")
	end
		healedParams.podItemHasPriority = true

	local healed = {
		name = item.name,
		count = item.count,
		parameters = healedParams
	}
	return healed
end


function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	local buffer=world.containerItems(entity.id())
	if #buffer==1 then
		if buffer[1] and not buffer[2] then
			if buffer[1].name == "filledcapturepod" then
				if not healTimer then
					healTimer=0.0
					animator.setAnimationState("healState", "on")
				elseif healTimer<1.0 then
					healTimer=healTimer+dt
					animator.setAnimationState("healState", "on")
				else
					output=heal(world.containerItemAt(entity.id(),0))
					--sb.logInfo("%s",output)
					world.containerTakeAt(entity.id(),0,1)
					world.containerPutItemsAt(entity.id(),output,1)
					animator.setAnimationState("healState", "off")
					healTimer=nil
				end
			else
				animator.setAnimationState("healState", "off")
				healTimer=nil
			end
		else
			animator.setAnimationState("healState", "off")
			healTimer=nil
		end
	end
	animator.setAnimationState("powerState", (buffer[1] or buffer[2]) and "on" or "off")
end