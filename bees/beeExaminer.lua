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
	futureItem = nil
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
			itemsDropped=false
			progress=0
			futureItem=nil
		elseif not (root.itemHasTag(currentItem.name, "queen") or root.itemHasTag(currentItem.name, "youngQueen") or root.itemHasTag(currentItem.name, "drone") or root.itemHasTag(currentItem.name, "artifact") ) then
			progress=0
			status = statusList.invalid
			futureItem=nil
		else
			if not futureItem then futureItem=currentItem end
			
			if root.itemHasTag(futureItem.name, "queen") or root.itemHasTag(futureItem.name, "youngQueen") then
				if currentItem.parameters.genomeInspected or (futureItem.parameters.genomeInspected and itemsDropped) then
					status = statusList.queenID
					shoveTimer=(shoveTimer or 0.0) + dt
					if not (shoveTimer >= 1.0) then return else shoveTimer=0.0 end
					local slotItem=world.containerItemAt(entity.id(),3)
					if slotItem and not compare(slotItem,futureItem) then return end
					nudgeItem(0,3)
					futureItem=nil
					currentItem=nil
				else
					handleProgress(dt)

					if progress >= 100 then
						futureItem.parameters.genomeInspected = true
						local slotItem=world.containerItemAt(entity.id(),3)
						if slotItem and not compare(slotItem,futureItem) then return end
						world.containerTakeAt(entity.id(), 0)
						shoveItem(0, 3)
						futureItem=nil
						handleBonuses()
						progress = 0
						status = statusList.queenID
						itemsDropped=true
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
			elseif root.itemHasTag(futureItem.name, "drone") then
				if currentItem.parameters.genomeInspected or (futureItem.parameters.genomeInspected and itemsDropped) then
					status = statusList.droneID
					shoveTimer=(shoveTimer or 0.0) + dt
					if not (shoveTimer >= 1.0) then return else shoveTimer=0.0 end
					local slotItem=world.containerItemAt(entity.id(),3)
					if slotItem and not compare(slotItem,futureItem) then return end
					nudgeItem(futureItem,3)
					futureItem=nil
					currentItem=nil
				else
					handleProgress(dt)

					if progress >= 100 then
						futureItem.parameters.genomeInspected = true
						local slotItem=world.containerItemAt(entity.id(),3)
						if slotItem and not compare(slotItem,futureItem) then return end
						world.containerTakeAt(entity.id(), 0)
						nudgeItem(0, 3)
						futureItem=nil
						handleBonuses()
						progress = 0
						status = statusList.droneID
						itemsDropped=true
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
			elseif root.itemHasTag(futureItem.name, "artifact") then
				if currentItem.parameters.genomeInspected or (futureItem.parameters.genomeInspected and itemsDropped) then
					status = statusList.artifactID
					shoveTimer=(shoveTimer or 0.0) + dt
					if not (shoveTimer >= 1.0) then return else shoveTimer=0.0 end
					local slotItem=world.containerItemAt(entity.id(),3)
					if slotItem and not compare(slotItem,futureItem) then return end
					world.containerTakeAt(entity.id(), 0)
					shoveItem(futureItem,3)
					futureItem=nil
					currentItem=nil
				else
					handleProgress(dt)

					if progress >= 100 then
						futureItem.parameters.category = "^cyan;Researched Artifact^reset;"
						futureItem.parameters.genomeInspected = true
						local slotItem=world.containerItemAt(entity.id(),3)
						if slotItem and not compare(slotItem,futureItem) then return end
						world.containerTakeAt(entity.id(), 0)
						shoveItem(futureItem, 3)
						futureItem=nil
						handleBonuses()
						progress = 0
						status = statusList.artifactID
						itemsDropped=true
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
		end
	else
		script.setUpdateDelta(-1)
	end
end

function handleProgress(dt)
	if playerUsing then
		progress = math.min(100,progress + (playerWorkingEfficiency * dt))
	else
		progress = math.min(100,progress + (selfWorkingEfficiency * dt))
	end
	progress = math.floor(progress * 100) * 0.01
end

function handleBonuses()
	if bonusResearch>0 then
		shoveItem({name="fuscienceresource",count=bonusResearch},1)
	end
	if bonusEssence>0 then
		shoveItem({name="essence",count=bonusEssence},2)
	end
	bonusEssence=0
	bonusResearch=0
end

function shoveItem(item,slot)
	if not item then return end
	local slotItem=world.containerItemAt(entity.id(),slot)
	if slotItem and slotItem.name~=item.name then
		if world.containerTakeAt(entity.id(),slot) then
			world.spawnItem(slotItem,entity.position())
		end
	end
	local leftovers=world.containerPutItemsAt(entity.id(),item,slot)
	if leftovers then
		world.spawnItem(leftovers,entity.position())
	end
end

function nudgeItem(startSlot,endSlot)
--world.containerTakeAt(entity.id(), 0)
	if (not startSlot) or (not endSlot) then return end
	local startItem=world.containerItemAt(entity.id(),startSlot)
	local endItem=world.containerItemAt(entity.id(),endSlot)
	
	local leftovers=world.containerPutItemsAt(entity.id(),startItem,endSlot)
	if not compare(startItem,leftovers) then
		world.containerTakeAt(entity.id(),startSlot)
		world.containerPutItemsAt(entity.id(),leftovers,startSlot)
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