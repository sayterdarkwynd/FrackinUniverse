require "/scripts/util.lua"

function init()
	if (status.resourceMax("health") < config.getParameter("minMaxHealth", 0)) or (not world.entityExists(entity.id())) or (world.entityType(entity.id())~= "npc") then
		effect.expire()
	end

	self.blinkTimer = 0
	if not blocker then blocker=config.getParameter("blocker","deathbombnpcsteal") end
end

function update(dt)
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

function uninit()

end

function explode()
	if not blocker then blocker=config.getParameter("blocker","deathbombnpcsteal") end
	if not self.exploded and not status.statPositive("deathbombDud") and not status.statPositive(blocker) then
		local chance=config.getParameter("chance",100)
		local dropPool={}
		local slotList={"head","headCosmetic","chest","chestCosmetic","legs","legsCosmetic","back","backCosmetic","primary","alt"}
		local usedSlots={}
		for _,slot in pairs(slotList) do
			local item=world.callScriptedEntity(entity.id(),"npc.getItemSlot",slot)
			local compareString=item
			if type(compareString)=="table" then
				compareString=compareString.name
			end
			if type(compareString)=="string" then
				if not compareString:find("npc") then
					dropPool[slot]=item
					table.insert(usedSlots,slot)
				end
			end
		end

		if util.tableSize(dropPool)>0 then
			for _=1,config.getParameter("bonusRolls",1) do
				if util.tableSize(dropPool) > 0 then
					if ((chance<100) and math.random(0,100)<chance) or (chance==100) then
						local point=math.random(1,util.tableSize(dropPool))
						world.spawnItem(dropPool[usedSlots[point]],entity.position())
						dropPool[usedSlots[point]]=nil
						world.callScriptedEntity(entity.id(),"npc.setItemSlot",usedSlots[point],nil)
						table.remove(usedSlots,point)
					end
				else
					break
				end
			end
		end
		status.addPersistentEffect(blocker,{stat=blocker,amount=1})
		self.exploded = true
		if status.isResource("stunned") then
			status.setResource("stunned",0)
		end
	end
end