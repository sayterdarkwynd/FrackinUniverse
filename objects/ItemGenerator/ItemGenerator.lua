item={
		parameters= {
			tooltipFields= {
				subtitle= "Servitor mkIII",
				objectImage= {{
					position= {-16.5, 5.5},
					fullbright= false,
					color= {255, 255, 255},
					image= "/monsters/flyers/servitors/servitor2.png:idle.1?",
					transformation= {
						{-1, 0, 73},
						{0, 1, -39.5},
						{0, 0, 1}
					}
				}}
			},
			podUuid=nil,
			description="Protects an assigned ecosystem with brutal force.",
			podItemHasPriority= false,
			pets= {{
				description="Protects an assigned ecosystem with brutal force.",
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
				name= "Servitor mkIII",
				portrait= {{
					position= {-16.5, 5.5},
					fullbright= false,
					color= {255, 255, 255},
					image= "/monsters/flyers/servitors/servitor2.png:idle.1?",
					transformation= {
						{-1, 0, 73},
						{0, 1, -39.5},
						{0, 0, 1}
					}
				}},
				config= {
					parameters= {
						aggressive= true,
						level= 3.09262,
						familyIndex= 0,
						seed= "8975654450380424721"
					},
					type= "servitor4"
				}
			}}
		},
		name= "filledcapturepod",
		count= 1
	}

function scanButton()
	item.parameters.podUuid=sb.makeUuid()
	world.containerAddItems(pane.containerEntityId(),item)
end

function bye()
	pane.dismiss()
end