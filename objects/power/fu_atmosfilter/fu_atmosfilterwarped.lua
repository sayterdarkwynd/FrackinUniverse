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
	teleportercore={{status="autowarp",team="enemy",durationMod=0.99}},
	vaashcontainer={{status="akkimariacidburn",team="enemy"}},
	voxel10k={{status="deathbombmoney",team="enemy"}},
	researchvoxellarge={{status="deathbombresearch",team="enemy"}},
	artifact1={{status="deathbombmadness",team="enemy"}},
	artifact2={{status="deathbombmoney",team="enemy"}},
	artifact3={{status="deathbombessence",team="enemy"}},
	artifact4={{status="deathbombresearch",team="enemy"}},
	artifact5={{status="deathbombnpc100steal1",team="enemy"}},
	wtfisthis={{status="deathbombmadness",team="enemy"},{status="deathbombmoney",team="enemy"},{status="deathbombessence",team="enemy"},{status="deathbombresearch",team="enemy"}},
	madnesstoken1={{status="insanity",team="enemy"}},
	madnesstoken2={{status="insanity",team="enemy"}},
	madnesstoken3={{status="insanity",team="enemy"},{status="deathbombmadness",team="enemy"}},
	scorchedcore={{status="burningnapalm",team="enemy"}},
	staticcell={{status="overload",team="enemy"},{status="shocked",team="enemy"}},
	powercore={{status="paralysis",team="enemy",durationMod=0.99},{status="overload",team="enemy"}},
	moltencore={{status="melting",team="enemy"}},
	nuclearcore={{status="radiationburn2",team="enemy"}},
	gluesprayer={{status="glueslow",team="enemy"}},
	cryonicextract={{status="slow",team="enemy"},{status="frozenburning",team="enemy"}},
	venomsample={{status="biooozepoison2",team="enemy"}},
	phasematter={{status="ghostlyglow",team="enemy"},{status="invisible",team="enemy"},{status="invulnerable",team="enemy"}},
	fu_precursorspawner={{status="deathbombmonsterhydra1",team="enemy"}}
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
		if effects[i]=="" then
			effects[i] = nil
		end
	end
	storage.effects = #effects > 0 and effects or nil
end