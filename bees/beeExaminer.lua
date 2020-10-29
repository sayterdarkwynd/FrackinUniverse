require "/scripts/util.lua"

local statusList={--progress status doesnt matter, but for any other status indicators, this should be used. it's used for the item network variant to determine completion state
	waiting="^yellow;Waiting for subject...",
	queenID="^green;Queen identified",
	youngQueenID="^green;Larva identified",
	droneID="^green;Drone identified",
	artifactID="^green;Artifact identified",
	artifactElderID="^green;Artifact identified",
	artifactProtheonID="^green;Artifact identified",
	artifactBasicID="^green;Artifact identified",
	geodeID="^green;Artifact identified",
	invalid="^red;Invalid sample detected"
}

local tagList={
	--FORMAT: <itemTag>={range=<math.rand max>,currencies={<currency variable name 1>=<bonusValue>,...},<optional override parameter>
	queen={range=25,currencies={bonusResearch=3}},
	youngQueen={range=25,currencies={bonusResearch=3}},
	drone={range=100,currencies={bonusResearch=0}},
	geode={range=65,currencies={bonusResearch=2,bonusEssence=1},overrideCategory="geodeResearched"},
	artifact={range=35,currencies={bonusResearch=50,bonusEssence=1,bonusProtheon=1},overrideCategory="artifactResearched"},
	artifactElder={range=25,currencies={bonusResearch=35,bonusEssence=10},overrideCategory="artifactElderResearched"},
	artifactBasic={range=50,currencies={bonusResearch=15,bonusEssence=0},overrideCategory="artifactResearched"}
}

function init()
	playerUsing = nil
	selfWorking = nil
	shoveTimer = 0.0

	defaultMaxStack=root.assetJson("/items/defaultParameters.config").defaultMaxStack
	defaultDelta=config.getParameter("scriptDelta")

	microscopeRank=config.getParameter("microscopeRank",0) -- currently not defined on microscopes, so does nothing

	playerWorkingEfficiency = nil
	selfWorkingEfficiency = nil
	status = statusList.waiting
	progress = 0
	futureItem = nil

	bonusEssence=0
	bonusResearch=0
    bonusProtheon=0

	--these are declared here, but can be moved to object parameters later as needed
	self.inputSlot=0
	self.outputSlot=4
	self.researchSlot=1
	self.essenceSlot=2
	self.protheonSlot=3

	message.setHandler("paneOpened", paneOpened)
	message.setHandler("paneClosed", paneClosed)
	message.setHandler("getStatus", getStatus)

	playerWorkingEfficiency = config.getParameter("playerWorkingEfficiency")
	selfWorkingEfficiency = config.getParameter("selfWorkingEfficiency")
	selfWorking = config.getParameter("selfWorking")
	math.randomseed(util.seedTime())
end


function fetchTags(params)
	local tags={}
	for k,v in pairs(params or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,copy(v))
		end
	end
	return tags
end

--[[function matchAny(str,tbl)
	for _,v in pairs(tbl) do
		if v==str then
			return true
		end
	end
	return false
end]]

function checkTags(item)
	if (not item) then return end
	local tags=fetchTags(item)
	local buffer=nil
	for tag,values in pairs(tagList) do
		for _,t in pairs(tags) do
			if t==tag then
				buffer=tag
				break
			end
		end
	end
	return buffer
end

function resetStats()
	bonusEssence=0
	bonusResearch=0
	bonusProtheon=0
	itemsDropped=false
	progress=0
	futureItem=nil
end

function update(dt)
	if playerUsing or selfWorking then
		local currentItem = world.containerItemAt(entity.id(), self.inputSlot)
		local currentItemParameters=currentItem and mergedParams(root.itemConfig(currentItem))
		local lastTag=checkTags(currentItemParameters)

		if currentItem == nil then
			status = statusList.waiting
		elseif (futureItem and ((futureItem.name~=currentItem.name) or (futureItem.count~=currentItem.count))) then
			--no hot-swapping exploit allowed
			status = statusList.waiting
			resetStats()
		elseif not lastTag then
			status = statusList.invalid
			resetStats()
		elseif futureItem and (currentItem.parameters.genome and futureItem.parameters.genome and (currentItem.parameters.genome~=futureItem.parameters.genome)) then
			--no hot-swapping exploit allowed
			status = statusList.waiting
			resetStats()
		else
			if not futureItem then futureItem=currentItem end

			if lastTag then
				if currentItem.parameters.genomeInspected or (futureItem.parameters.genomeInspected and itemsDropped) then
					status=statusList[lastTag.."ID"]

					shoveTimer=(shoveTimer or 0.0) + dt
					if not (shoveTimer >= 1.0) then return else shoveTimer=0.0 end
					local singleCountFutureItem=copy(futureItem)
					singleCountFutureItem.count=1

					local slotItem=world.containerItemAt(entity.id(),self.outputSlot)
					local singleCountSlotItem=slotItem and copy(slotItem)
					if singleCountSlotItem then
						singleCountSlotItem.count=1
					end

					if slotItem and not compare(singleCountSlotItem,singleCountFutureItem) then return end
					
					if lastTag=="drone" then
						if not nudgeItem(futureItem,self.outputSlot,slotItem) then return end
						world.containerTakeAt(entity.id(), self.inputSlot)
					else
						if not nudgeItem(singleCountFutureItem,self.outputSlot,slotItem) then return end
						world.containerTakeNumItemsAt(entity.id(), self.inputSlot,1)
					end


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

						if tagList[lastTag].overrideCategory then futureItem.parameters.category = tagList[lastTag].overrideCategory end
						futureItem.parameters.genomeInspected = true

						local singleCountFutureItem=copy(futureItem)
						singleCountFutureItem.count=1

						local slotItem=world.containerItemAt(entity.id(),self.outputSlot)
						local singleCountSlotItem=slotItem and copy(slotItem)
						if singleCountSlotItem then
							singleCountSlotItem.count=1
						end

						if slotItem and not compare(singleCountSlotItem,singleCountFutureItem) then return end

						if lastTag=="drone" then
							if not nudgeItem(futureItem,self.outputSlot,slotItem) then return end
							world.containerTakeAt(entity.id(), self.inputSlot)
						else
							if not nudgeItem(singleCountFutureItem,self.outputSlot,slotItem) then return end
							world.containerTakeNumItemsAt(entity.id(), self.inputSlot,1)
						end
						
						futureItem=nil
						currentItem=nil
						if bonusResearch>0 then
							shoveItem({name="fuscienceresource",count=bonusResearch},self.researchSlot)
						end
						if bonusEssence>0 then
							shoveItem({name="essence",count=bonusEssence},self.essenceSlot)
						end
						if bonusProtheon>0 then
							shoveItem({name="fuprecursorresource",count=bonusProtheon},self.protheonSlot)
						end
						bonusEssence=0
						bonusResearch=0
						bonusProtheon=0
						progress = 0

						status=statusList[lastTag.."ID"]

						itemsDropped=true
					else
						status = "^cyan;"..progress.."%"
						-- ***** chance to gain currencies *****
						local randCheck = 0
						randCheck=math.random(tagList[lastTag].range or 100)
						local rank=(currentItemParameters.rank or 0)
						--prev., the 'rank' parameter on the items did nothing, might need rebalancing
						--also, config.getParameter gets info from the calling object.
						--near the start of update is a currentItemParameters declaration to use.
						local effectiveCount=((lastTag=="drone") and currentItem.count) or 1

						if (randCheck == self.researchSlot) and (tagList[lastTag].currencies.bonusResearch) then
							bonusResearch=bonusResearch+((tagList[lastTag].currencies.bonusResearch+rank+microscopeRank)*effectiveCount) -- Gain research as this is used
						elseif (randCheck == self.essenceSlot) and (tagList[lastTag].currencies.bonusEssence) then
							bonusEssence=bonusEssence+((tagList[lastTag].currencies.bonusEssence+rank+microscopeRank)*effectiveCount) -- Gain essence as this is used
						elseif (randCheck == self.protheonSlot) and (tagList[lastTag].currencies.bonusProtheon) then
							bonusProtheon=bonusProtheon+((tagList[lastTag].currencies.bonusProtheon+rank+microscopeRank)*effectiveCount) -- Gain protheon as this is used
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
		slotItemConfig=mergedParams(slotItemConfig)
		slotItemConfig=slotItemConfig.maxStack or defaultMaxStack
	end

	if (item.count+slotItem.count > slotItemConfig) then return false end

	world.containerPutItemsAt(entity.id(),item,slot)
	return true
end

function mergedParams(item)
	if not item or not item.config then return end
	if item.config and not item.parameters then return item.config end
	return util.mergeTable(item.config,item.parameters)
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