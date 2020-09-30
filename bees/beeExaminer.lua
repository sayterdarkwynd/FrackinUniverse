require "/scripts/util.lua"

local statusList={--progress status doesnt matter, but for any other status indicators, this should be used. it's used for the item network variant to determine completion state
	waiting="^yellow;Waiting for subject...",
	queenID="^green;Queen identified",
	droneID="^green;Drone identified",
	artifactID="^green;Artifact identified",
	geodeID="^green;Artifact identified",
	invalid="^red;Invalid sample detected"
}

function init()
	playerUsing = nil
	selfWorking = nil
	shoveTimer = 0.0

	defaultMaxStack=root.assetJson("/items/defaultParameters.config").defaultMaxStack
	rank=config.getParameter("rank",0)
	defaultDelta=config.getParameter("scriptDelta")
	
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
			currentItem=nil
		else
			if not futureItem then futureItem=currentItem end
			local isQueen=root.itemHasTag(futureItem.name, "queen") or root.itemHasTag(futureItem.name, "youngQueen")
			local isDrone=root.itemHasTag(futureItem.name, "drone")
			local isArtifact=root.itemHasTag(futureItem.name, "artifact")
			local isGeode=root.itemHasTag(futureItem.name, "geode")
			
			if isQueen or isDrone or isArtifact or isGeode then
				if currentItem.parameters.genomeInspected or (futureItem.parameters.genomeInspected and itemsDropped) then
					if isQueen then
						status = statusList.queenID
					elseif isDrone then
						status = statusList.droneID
					elseif isArtifact then
						status = statusList.artifactID
					elseif isGeode then
						status = statusList.geodeID	
					end
					
					shoveTimer=(shoveTimer or 0.0) + dt
					if not (shoveTimer >= 1.0) then return else shoveTimer=0.0 end
					local singleCountFutureItem=copy(futureItem)
					singleCountFutureItem.count=1
					
					local slotItem=world.containerItemAt(entity.id(),3)
					local singleCountSlotItem=slotItem and copy(slotItem)
					if singleCountSlotItem then
						singleCountSlotItem.count=1
					end
					
					if slotItem and not compare(singleCountSlotItem,singleCountFutureItem) then return end
					if not nudgeItem(futureItem,3,slotItem) then return end
					
					world.containerTakeAt(entity.id(), 0)
					futureItem=nil
					currentItem=nil
				else
					if playerUsing then
						progress = math.min(100,progress + (playerWorkingEfficiency * dt))
					else
						progress = math.min(100,progress + (selfWorkingEfficiency * dt))
					end
					progress = math.floor(progress * 100) * 0.01
					
					if progress >= 100 then
						status = "^cyan;"..progress.."%"
						
						if isArtifact then futureItem.parameters.category = "^cyan;Researched Artifact^reset;" end
						if isGeode then futureItem.parameters.category = "^cyan;Researched Geode^reset;" end
						futureItem.parameters.genomeInspected = true
						
						local singleCountFutureItem=copy(futureItem)
						singleCountFutureItem.count=1
						
						local slotItem=world.containerItemAt(entity.id(),3)
						local singleCountSlotItem=slotItem and copy(slotItem)
						if singleCountSlotItem then
							singleCountSlotItem.count=1
						end
						
						if slotItem and not compare(singleCountSlotItem,singleCountFutureItem) then return end
						if not nudgeItem(futureItem,3,slotItem) then return end
						
						world.containerTakeAt(entity.id(), 0)
						futureItem=nil
						currentItem=nil
						if bonusResearch>0 then
							shoveItem({name="fuscienceresource",count=bonusResearch},1)
						end
						if bonusEssence>0 then
							shoveItem({name="essence",count=bonusEssence},2)
						end
						bonusEssence=0
						bonusResearch=0
						progress = 0
						
						if isQueen then
							status = statusList.queenID
						elseif isDrone then
							status = statusList.droneID
						elseif isArtifact then
							status = statusList.artifactID
						elseif isGeode then
							status = statusList.geodeID							
						end
						
						itemsDropped=true
					else
						status = "^cyan;"..progress.."%"
						-- ***** chance to gain research *****
						local randCheck = 0
						if isQueen then
							randCheck=math.random(25)
						elseif isDrone then
							randCheck=math.random(100)
						elseif isArtifact then
							randCheck=math.random(10)
						elseif isGeode then
							randCheck=math.random(15)							
						end
						if randCheck == 1 then
							local bonusValue=0
							if isQueen then
								bonusValue=5
							elseif isDrone then
								bonusValue=2
							elseif isArtifact then
								bonusValue=25
							elseif isGeode then
								bonusValue=5								
							end
							bonusResearch=bonusResearch+((bonusValue+rank)*currentItem.count) -- Gain research as this is used
						elseif randCheck == 2 then
							local bonusValue=0
							if isArtifact then
								bonusValue=1
							end
							if isGeode then
								bonusValue=1
							end							
							bonusEssence=bonusEssence+((1+rank)*currentItem.count)
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

function nudgeItem(item,slot,slotItem)
	--assumptive: compare(item,slotItem) prior to usage returns true, or slotItem is nil
	if not item then return end
	
	if not slotItem then
		world.containerPutItemsAt(entity.id(),item,slot)
		return true
	end
	
	local slotItemConfig=slotItem and root.itemConfig(slotItem)
	if slotItemConfig then
		slotItemConfig=util.mergeTable(slotItemConfig.config,slotItemConfig.parameters)
		slotItemConfig=slotItemConfig.maxStack or defaultMaxStack
	end
	
	if (item.count+slotItem.count > slotItemConfig) then return false end
	
	world.containerPutItemsAt(entity.id(),item,slot)
	return true
end

function paneOpened()
	script.setUpdateDelta(defaultDelta)
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