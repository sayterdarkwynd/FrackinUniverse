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

function loadMonster()

	local botspawner=config.getParameter("botspawner")
	if not botspawner then return false end
	if not botspawner.type then return false end
	
	local name=config.getParameter("shortdescription") or "Broken Bot"
	local desc=config.getParameter("description") or "Yup, you broke it."
	
	local imgData=root.monsterPortrait(botspawner.type)
	local monsterData=root.monsterParameters(botspawner.type)
	
	item.parameters.tooltipFields.subtitle=name
	item.parameters.description=desc
	item.parameters.tooltipFields.objectImage=imgData

	local buffer={}
	for _,pet in pairs(item.parameters.pets) do
		pet.description=desc
		pet.name=name

		pet.portrait=imgData
		pet.collisionPoly=monsterData.movementSettings.collisionPoly
		
		pet.config.type=botspawner.type
		table.insert(buffer,pet)
	end
	item.parameters.pets=buffer
	return true
end

function printMonster()
	item.parameters.podUuid=sb.makeUuid()
	if world.spawnItem(item,entity.position()) then
		object.setInteractive(false)
		object.smash(true)
	end
end

function init()
    object.setInteractive(true)
end

function onInteraction()
	if loadMonster() then
		printMonster()
	end
end