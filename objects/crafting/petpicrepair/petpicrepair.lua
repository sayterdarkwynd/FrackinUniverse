function init()
	message.setHandler("print",scanButton)
end

function scanButton()
	local items=world.containerItems(entity.id())
	if (not items) or (items[2]) or (not items[1]) then return end
	invItem=loadMonster(items[1])
	if not invItem then return end
	world.containerTakeAt(entity.id(),0)
	world.containerPutItemsAt(entity.id(),invItem,1)
end

function loadMonster(invItem)
	local imgData={}
	local buffer={}
	if not invItem.parameters.pets then return end
	for _,pet in pairs(invItem.parameters.pets) do
		if isGenerated(pet.config.type) then return end
		imgData=root.monsterPortrait(pet.config.type)
		pet.portrait=imgData
		table.insert(buffer,pet)
	end
	invItem.parameters.pets=buffer
	invItem.parameters.tooltipFields.objectImage=imgData
	return invItem
end

function update(dt)
  if #world.containerItems(entity.id()) > 0 then
    animator.setAnimationState("powerState", "on")
  else
    animator.setAnimationState("powerState", "off")
  end
end

function isGenerated(type)
	if type=="smallquadruped" then return true end
	if type=="largequadruped" then return true end
	if type=="largeflying" then return true end
	if type=="smallflying" then return true end
	if type=="bonebird" then return true end
	if type=="smallfish" then return true end
	if type=="largefish" then return true end
	if type=="smallbiped" then return true end
	if type=="largebiped" then return true end

	return false
end