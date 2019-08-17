require "/scripts/effectUtil.lua"

itemList={
	bluegravball={{status="gravrain",team="enemy",}},
	orangegravball={{status="orangegravrain",team="enemy"}},
	killpod={{status="killpod",team="enemy"}},
	quantumball={{status="timefreeze",team="enemy"}},
	gregskittlegun={{status="timefreezeSkittles",team="enemy"}},
	gregskittlegunfake={{status="marvinSkittles",team="enemy"},{status="nude",team="all"}},
	perfectlygenericitem={{status="vulnerability",team="enemy"}},
	gyrostabilizer={{status="gyrostat",team="enemy"}},
	madnesstoken3={{status="autowarp",team="enemy"}},
	vaashcontainer={{status="akkimariacidburn",team="enemy"}}
}

function init()
	object.setInteractive(true)
	self.range=config.getParameter("range",20)
end

function update(dt)
	if not storage.deltaTime or storage.deltaTime > 1.0 then
		local items=world.containerItems(entity.id())
		if items and #items>0 then
			animator.setAnimationState("switchState","on")
			for _,item in pairs(items) do
				if itemList[item.name] then
					for _,buffer in pairs(itemList[item.name]) do
						 effectUtil.effectTypesInRange(buffer.status,self.range,{"creature"},storage.deltaTime*2,buffer.team)
					end
				end
			end
		else
			animator.setAnimationState("switchState","off")
		end
	storage.deltaTime=0.0
	else
		storage.deltaTime=storage.deltaTime+dt
	end
end