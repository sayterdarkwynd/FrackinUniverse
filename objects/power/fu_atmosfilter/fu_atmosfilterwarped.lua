require "/scripts/effectUtil.lua"

itemList={
	bluegravball={{status="gravrain",team="enemy"}},
	orangegravball={{status="orangegravrain",team="enemy"}},
	killpod={{status="killpod",team="enemy"}},
	quantumball={{status="timefreeze",team="enemy"}},
	gregskittlegun={{status="timefreezeSkittles",team="enemy"}},
	gregskittlegunfake={{status="marvinSkittles",team="enemy"},{status="nude",team="all"}},
	perfectlygenericitem={{status="vulnerability",team="enemy"}},
	gyrostabilizer={{status="gyrostat",team="enemy"}},
	madnesstoken3={{status="autowarp",team="enemy",durationMod=0.99}},
	vaashcontainer={{status="akkimariacidburn",team="enemy"}}
}

function init()
	power.init()
	if not config.getParameter("slotCount") then
		object.setInteractive(false)
	end
	self=config.getParameter("atmos")
end

function update(dt)
	if self and self.range and (storage.effects or self.objectEffects) and power.consume(config.getParameter('isn_requiredPower')) then
		animator.setAnimationState("switchState", "on")
		if storage.effects then
			for _,effect in pairs(storage.effects) do
				effectUtil.effectAllOfTeamInRange(effect.status,self.range,dt*(effect.durationMod or 2),effect.team)
			end
		end
		if self.objectEffects then
			for _,effect in pairs (self.objectEffects) do
				effectUtil.effectAllInRange(effect,self.range,5)
			end
		end
	else
		animator.setAnimationState("switchState", "off")
	end
end

function containerCallback()
	local effects = {}
	for _,item in pairs(world.containerItems(entity.id(), slot)) do
		if item and itemList[item.name] then
			for _,effect in pairs(itemList[item.name]) do
				table.insert(effects,effect)
			end
		end
	end
	for i=1,#effects - 1 do
		for j=i+1,#effects do
			if effects[j] == effects[i] then
				effects[j] = nil
			end
		end
	end
	storage.effects = #effects > 0 and effects or nil
end