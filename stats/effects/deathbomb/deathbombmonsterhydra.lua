function init()
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) then
		effect.expire()
	end
	self.blinkTimer = 0
end

function update(dt)
	self.blinkTimer = self.blinkTimer - dt
	if self.blinkTimer <= 0 then self.blinkTimer = 0.5 end

	if self.blinkTimer < 0.2 then
		effect.setParentDirectives(config.getParameter("flashDirectives", ""))
	else
		effect.setParentDirectives("")
	end

	if not status.resourcePositive("health") and status.resourceMax("health") >= config.getParameter("minMaxHealth", 0) then
		explode()
	end
end

function uninit()
  
end

function explode()
	if world.entityType(entity.id()) ~= "monster" then
		self.exploded=true
	end
	if not self.exploded then
		local monsterParams=world.callScriptedEntity(entity.id(),"monster.uniqueParameters")
		local monsterData=root.monsterParameters(world.monsterType(entity.id()))
		if monsterData and monsterData.behaviorConfig then
			for _,piece in pairs(monsterData.behaviorConfig) do
				if type(piece)=="table" then
					for _,shard in pairs(piece) do
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
		
		monsterParams.level=world.callScriptedEntity(entity.id(),"monster.level")
		monsterParams.seed=world.callScriptedEntity(entity.id(),"monster.seed")
		monsterParams.familyIndex=world.callScriptedEntity(entity.id(),"monster.familyIndex")
		monsterParams.aggressive=world.entityAggressive(entity.id())
		
		for _=1,config.getParameter("count",1) do
			world.spawnMonster(world.monsterType(entity.id()),entity.position(),monsterParams)
		end
		self.exploded = true
	end
end
