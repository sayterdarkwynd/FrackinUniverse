function init()
	canRun=false
	if (not world.entityExists(entity.id())) or (world.entityType(entity.id())~= "monster") or (world.callScriptedEntity(entity.id(),"getClass") == 'bee') or (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) then

		effect.expire()
	else
		canRun=true
		if not blocker then blocker=config.getParameter("blocker","deathbombmonsterhydra") end
	end

	self.blinkTimer = 0
end

function update(dt)
	if canRun then
		self.blinkTimer = self.blinkTimer - dt
		if self.blinkTimer <= 0 then self.blinkTimer = 0.5 end

		if self.blinkTimer < 0.2 then
			effect.setParentDirectives(config.getParameter("flashDirectives", ""))
		else
			effect.setParentDirectives("")
		end

		if (status.resourcePercentage("health") <= 0.05) and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
			explode()
		end
	end
end

function uninit()

end

function explode()
	if not blocker then blocker=config.getParameter("blocker","deathbombmonsterhydra") end
	--sb.logInfo("%s",status.stat("deathbombDud"))
	if not self.exploded and not status.statPositive("deathbombDud") and not status.statPositive(blocker) then
		local monsterParams=world.callScriptedEntity(entity.id(),"monster.uniqueParameters")
		local monsterData=root.monsterParameters(world.monsterType(entity.id()))
		if monsterData and monsterData.behaviorConfig then
			for _,piece in pairs(monsterData.behaviorConfig) do
				if type(piece)=="table" then
					for _,shard in pairs(piece) do
						if type(shard) and type(shard)=="table" then--keep getting a serious WTF issue here sometimes
							if shard.name then
								if shard.name:find("spawn") then
									self.exploded=true
									return
								end
							end
						end
					end
				end
			end

		end

		monsterParams.level=world.callScriptedEntity(entity.id(),"monster.level")
		monsterParams.seed=world.callScriptedEntity(entity.id(),"monster.seed")
		monsterParams.familyIndex=world.callScriptedEntity(entity.id(),"monster.familyIndex")
		monsterParams.aggressive=world.entityAggressive(entity.id())

		for _=1,config.getParameter("count",1) do
			world.spawnMonster(world.monsterType(entity.id()),entity.position(),monsterParams)
		end
		status.addPersistentEffect(blocker,{stat=blocker,amount=1})
		self.exploded = true
		if status.isResource("stunned") then
			status.setResource("stunned",0)
		end
	end
end
