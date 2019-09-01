require "/scripts/effectUtil.lua"

itemList={
	bluegravball={{status="gravrain",team="enemy"}},
	orangegravball={{status="orangegravrain",team="enemy"}},
	killpod={{status="killpod",team="enemy"}},
	quantumball={{status="timefreeze2totalinvuln",team="enemy"}},
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
	fu_precursorspawner={{status="deathbombmonsterhydra1",team="enemy"}},
	brainharvester={{status="deathbombbrainharvest",team="enemy"}}
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
						 effectUtil.effectAllOfTeamInRange(buffer.status,self.range,(storage.deltaTime or 1)*(buffer.durationMod or 2),buffer.team)
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