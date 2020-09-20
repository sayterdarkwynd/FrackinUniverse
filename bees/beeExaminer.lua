local statusList={--progress status doesnt matter, but for any other status indicators, this should be used. it's used for the item network variant to determine completion state
	waiting="^yellow;Waiting for subject...",
	queenID="^green;Queen identified",
	droneID="^green;Drone identified",
	artifactID="^green;Artifact identified",
	invalid="^red;Invalid sample detected"
}

function init()
	playerUsing = nil
	selfWorking = nil

	playerWorkingEfficiency = nil
	selfWorkingEfficiency = nil
	status = statusList.waiting
	progress = 0
	oldItem = nil
	bonusEssence=0
	bonusResearch=0

	message.setHandler("paneOpened", paneOpened)
	message.setHandler("paneClosed", paneClosed)
	message.setHandler("getStatus", getStatus)

	playerWorkingEfficiency = config.getParameter("playerWorkingEfficiency")
	selfWorkingEfficiency = config.getParameter("selfWorkingEfficiency")
	selfWorking = config.getParameter("selfWorking")
end

function update(dt)
	if playerUsing or selfWorking then
	local currentItem = world.containerItemAt(entity.id(), 0)

	if currentItem == nil then
		bonusEssence=0
		bonusResearch=0
		status = statusList.waiting

		elseif compare(currentItem, oldItem) then	
			if root.itemHasTag(oldItem.name, "queen") or root.itemHasTag(oldItem.name, "youngQueen") then
				if oldItem.parameters.genomeInspected then
					status = statusList.queenID
				else
					if playerUsing then
						progress = progress + (playerWorkingEfficiency * dt)
					else
						progress = progress + (selfWorkingEfficiency * dt)
					end

					progress = math.floor(progress * 100) * 0.01

					if progress >= 100 then
						if bonusResearch>0 then
							local slotItem=world.containerItemAt(entity.id(),1)
							if slotItem and slotItem.name~="fuscienceresource" then
								if world.containerTakeAt(entity.id(),1) then
									world.spawnItem(slotItem,entity.position())
								end
							end
							local leftovers=world.containerPutItemsAt(entity.id(),{name="fuscienceresource",count=bonusResearch},1)
							if leftovers then
								world.spawnItem("fuscienceresource",entity.position(),bonusResearch)
							end
						end
						if bonusEssence>0 then
							local slotItem=world.containerItemAt(entity.id(),2)
							if slotItem and slotItem.name~="essence" then
								if world.containerTakeAt(entity.id(),2) then
									world.spawnItem(slotItem,entity.position())
								end
							end
							local leftovers=world.containerPutItemsAt(entity.id(),{name="essence",count=bonusEssence},2)
							if leftovers then
								world.spawnItem("essence",entity.position(),bonusEssence)
							end
						end
						bonusEssence=0
						bonusResearch=0
						progress = 0
						status = statusList.queenID

						oldItem.parameters.genomeInspected = true
						world.containerTakeAt(entity.id(), 0)
						world.containerPutItemsAt(entity.id(), oldItem, 3)
					else
						status = "^cyan;"..progress.."%"
						-- ***** chance to gain research *****
						local randCheck = math.random(25)
						if randCheck == 1 then
							local bonusValue = config.getParameter("bonusResearch",0)
							bonusResearch=bonusResearch+((5+bonusValue)*currentItem.count) -- Gain research as this is used
						end
					end
				end
			elseif root.itemHasTag(oldItem.name, "drone") then
				if oldItem.parameters.genomeInspected then
					status = statusList.droneID
				else
					if playerUsing then
						progress = progress + (playerWorkingEfficiency * dt)
					else
						progress = progress + (selfWorkingEfficiency * dt)
					end

					progress = math.floor(progress * 100) * 0.01

					if progress >= 100 then
						if bonusResearch>0 then
							local slotItem=world.containerItemAt(entity.id(),1)
							if slotItem and slotItem.name~="fuscienceresource" then
								if world.containerTakeAt(entity.id(),1) then
									world.spawnItem(slotItem,entity.position())
								end
							end
							local leftovers=world.containerPutItemsAt(entity.id(),{name="fuscienceresource",count=bonusResearch},1)
							if leftovers then
								world.spawnItem("fuscienceresource",entity.position(),bonusResearch)
							end
						end
						if bonusEssence>0 then
							local slotItem=world.containerItemAt(entity.id(),2)
							if slotItem and slotItem.name~="essence" then
								if world.containerTakeAt(entity.id(),2) then
									world.spawnItem(slotItem,entity.position())
								end
							end
							local leftovers=world.containerPutItemsAt(entity.id(),{name="essence",count=bonusEssence},2)
							if leftovers then
								world.spawnItem("essence",entity.position(),bonusEssence)
							end
						end
						bonusEssence=0
						bonusResearch=0
						progress = 0
						status = statusList.droneID

						oldItem.parameters.genomeInspected = true
						world.containerTakeAt(entity.id(), 0)
						world.containerPutItemsAt(entity.id(), oldItem, 0)
					else
						status = "^cyan;"..progress.."%"
						-- ***** chance to gain research *****
						local randCheck = math.random(100) --1% chance, compared to a 25% for the queen
						if randCheck == 1 then
							local bonusValue = config.getParameter("bonusResearch",0)
							bonusResearch=bonusResearch+((2+bonusValue)*currentItem.count) -- Gain less research than via queen 
						end
					end
				end				
			elseif root.itemHasTag(oldItem.name, "artifact") then
				if oldItem.parameters.genomeInspected then
					status = statusList.artifactID
				else
					if playerUsing then
						progress = progress + (playerWorkingEfficiency * dt)
					else
						progress = progress + (selfWorkingEfficiency * dt)
					end

					progress = math.floor(progress * 100) * 0.01

					if progress >= 100 then
						if bonusResearch>0 then
							local slotItem=world.containerItemAt(entity.id(),1)
							if slotItem and slotItem.name~="fuscienceresource" then
								if world.containerTakeAt(entity.id(),1) then
									world.spawnItem(slotItem,entity.position())
								end
							end
							local leftovers=world.containerPutItemsAt(entity.id(),{name="fuscienceresource",count=bonusResearch},1)
							if leftovers then
								world.spawnItem("fuscienceresource",entity.position(),bonusResearch)
							end
						end
						if bonusEssence>0 then
							local slotItem=world.containerItemAt(entity.id(),2)
							if slotItem and slotItem.name~="essence" then
								if world.containerTakeAt(entity.id(),2) then
									world.spawnItem(slotItem,entity.position())
								end
							end
							local leftovers=world.containerPutItemsAt(entity.id(),{name="essence",count=bonusEssence},2)
							if leftovers then
								world.spawnItem("essence",entity.position(),bonusEssence)
							end
						end
						bonusEssence=0
						bonusResearch=0
						progress = 0
						status = statusList.artifactID
						oldItem.parameters.category = "^cyan;Researched Artifact^reset;"
						oldItem.parameters.genomeInspected = true
						world.containerTakeAt(entity.id(), 0)
						world.containerPutItemsAt(entity.id(), oldItem, 0)
					else
						status = "^cyan;"..progress.."%"
						-- ***** chance to gain research *****
						local randCheck = math.random(10)
						if randCheck == 1 then						
							local rank = config.getParameter("rank",0)
							bonusEssence=bonusEssence+((1+rank)*currentItem.count) -- Gain research as this is used
						end
						if randCheck ==2 then
							local rank = config.getParameter("rank",0)
							rank = 1 + rank
							bonusResearch=bonusResearch+((25+rank)*currentItem.count)
						end						
					end
				end				
			else
				status = statusList.invalid
			end

		else
			progress = 0
			if not (root.itemHasTag(currentItem.name, "queen") or root.itemHasTag(currentItem.name, "youngQueen") or root.itemHasTag(currentItem.name, "drone") or root.itemHasTag(currentItem.name, "artifact") ) then
				status = statusList.invalid
			end			
		end

		oldItem = currentItem
	else
		script.setUpdateDelta(-1)
	end
end

-- Straight outta util.lua
-- because NOPE to copying an ENTIRE script just for one function
function compare(t1, t2)
	if t1 == t2 then return true end
	if type(t1) ~= type(t2) then return false end
	if type(t1) ~= "table" then return false end
	for k,v in pairs(t1) do if not compare(v, t2[k]) then return false end end
	for k,v in pairs(t2) do if not compare(v, t1[k]) then return false end end
	return true
end

function paneOpened()
	script.setUpdateDelta(config.getParameter("scriptDelta"))
	playerUsing = true
end

function paneClosed()
	playerUsing = nil
end

function getStatus()
	if status then return status end
end

function currentlyWorking()
	for id,label in pairs(statusList) do
		if status==label then return false end
	end
	return true
end