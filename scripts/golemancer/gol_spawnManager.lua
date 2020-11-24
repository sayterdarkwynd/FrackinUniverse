function spawn(pattern)
	local initialPosition = vec2.add(self.position, {-pattern.offset[1], -pattern.offset[2]})
	local spawnPosition = vec2.add(initialPosition, {pattern.boundingBox[1]/2, pattern.boundingBox[2]/2})
	spawnResult(pattern, spawnPosition)
end

function evolve(evolution)
	local eType = entity.entityType()
	local myType = config.getParameter("isMultiplier",0)

	if eType == "monster" then
		monster.setDropPool("empty")
	elseif eType == "npc" then
		npc.setDropPool("empty")
	end
	if myType == 0 then	--Unless the monster is set to isMultiplier, they die on spawning the new variant.
		status.setResource("health", 0)
	end
	spawnResult(evolution, self.position)
end

function spawnResult(result, position)
	if result.npcSpawn then
		world.spawnNpc(position, result.npcSpawn.species, result.npcSpawn.npcType, world.threatLevel(), nil, result.npcSpawn.parameters or {})
	end
	if result.monsterSpawn then
		local params={}
		local mParams=monster.uniqueParameters()

		if result and result.monsterSpawn and result.monsterSpawn.parameters then
			params=result.monsterSpawn.parameters
			if not params.seed then
				params.seed=monster.seed()
			end
		else
			params.seed=monster.seed()
		end

		if mParams then
			if (params.aggressive==nil) and (mParams.aggressive~=nil) then
				params.aggressive=mParams.aggressive
			end
		end
		if (params.aggressive==nil) then
			params.aggressive=world.entityAggressive(entity.id())
		end

		world.spawnMonster(result.monsterSpawn.type, vec2.add(position, {0, 3}), params)
	end
	if result.itemSpawn then
		world.spawnItem(result.itemSpawn.name, position, result.itemSpawn.count or 1, result.itemSpawn.parameters or {})
	end
end
