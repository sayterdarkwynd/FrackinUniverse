function init()
	message.setHandler("print",scanButton)
end

item =
{
	parameters= {
		tooltipFields= {
			subtitle= "",
			objectImage= {
			}
		},
		podUuid=nil,
		description="",
		podItemHasPriority= false,
		pets=
		{
			{
				description="",
				collisionPoly= {
					{-1.75, 2.55},
					{-2.25, 2.05},
					{-2.75, -3.55},
					{-2.25, -3.95},
					{2.25, -3.95},
					{2.75, -3.55},
					{2.25, 2.05},
					{1.75, 2.55}
				},
				name= "",
				portrait= {
				},
				config= {
					parameters= {
						aggressive= true,
						level= 1,
						familyIndex= 0,
						seed= "0"
					},
					type= ""
				}
			}
		}
	},
	name= "botpod",
	count= 1
}

function scanButton()
	local items=world.containerItems(entity.id())
	if not items then return end
	if not (#items > 0) then return end
	for index,invItem in pairs(items)do
		if index==1 then
			if loadMonster(invItem) then return end
		elseif index==2 then
			return
		end
	end
	
	printMonster()
end

function loadMonster(invItem)
	local data=root.itemConfig(invItem).config
	if not data.botspawner then return true end
	if not data.botspawner.type then return true end
	
	local name=data.shortdescription or "Broken Bot"
	local desc=data.description or "Yup, you broke it."
	local myType=data.botspawner.type
	local imgData=root.monsterPortrait(myType)
	local monsterData=root.monsterParameters(myType)
	
	item.parameters.tooltipFields.subtitle=name
	item.parameters.description=desc
	item.parameters.tooltipFields.objectImage=imgData

	local buffer={}
	for _,pet in pairs(item.parameters.pets) do
		pet.description=desc
		pet.name=name

		pet.portrait=imgData
		pet.collisionPoly=monsterData.movementSettings.collisionPoly
		
		pet.config.type=myType
		table.insert(buffer,pet)
	end
	item.parameters.pets=buffer
	return false
end

function printMonster()
	item.parameters.podUuid=sb.makeUuid()
	if world.containerPutItemsAt(entity.id(),item,1) == nil then
		world.containerTakeNumItemsAt(entity.id(),0,1)
	end
end

function update(dt)
  if #world.containerItems(entity.id()) > 0 then
    animator.setAnimationState("powerState", "on")
  else
    animator.setAnimationState("powerState", "off")
  end
end
