item =
{
	parameters= {
		tooltipFields= {
			subtitle= "",
			objectImage= {
				{
					position= {-16.5, 5.5},
					fullbright= false,
					color= {255, 255, 255},
					image= "",
					transformation= {
						{-1, 0, 73},
						{0, 1, -39.5},
						{0, 0, 1}
					}
				}
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
					{
						position= {-16.5, 5.5},
						fullbright= false,
						color= {255, 255, 255},
						image= "",
						transformation= {
							{-1, 0, 73},
							{0, 1, -39.5},
							{0, 0, 1}
						}
					}
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
	name= "filledcapturepod",
	count= 1
}

function scanButton()
	loadMonster()
	printMonster()
end

function loadMonster()
	local buffer={}
	local name="Servitor mkIII"
	local desc="Protects an assigned ecosystem with brutal force."
	local img="/monsters/flyers/servitors/servitor2.png:idle.1?"
	local myType="servitor4"
	
	item.parameters.tooltipFields.subtitle=name
	item.parameters.description=desc
	
	for _,image in pairs(item.parameters.tooltipFields.objectImage) do
		image.image=img
		table.insert(buffer,image)
	end
	item.parameters.tooltipFields.objectImage=buffer
	buffer={}
	
	for _,pet in pairs(item.parameters.pets) do
		local buffer2={}
		pet.description=desc
		pet.name=name
		
		for _,image in pairs(pet.portrait) do
			image.image=img
			table.insert(buffer2,image)
		end
		pet.portrait=buffer2
		
		pet.config.type=myType
		table.insert(buffer,pet)
	end
	item.parameters.pets=buffer
	buffer={}
end

function printMonster()
	item.parameters.podUuid=sb.makeUuid()
	world.containerAddItems(pane.containerEntityId(),item)
end


function bye()
	pane.dismiss()
end