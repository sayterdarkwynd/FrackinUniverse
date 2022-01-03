require "/scripts/util.lua"

local statusList={--progress status doesnt matter, but for any other status indicators, this should be used. it's used for the item network variant to determine completion state
	waiting="^yellow;Waiting for subject...",
	queenID="^green;Queen identified",
	youngQueenID="^green;Larva identified",
	droneID="^green;Drone identified",
	fossilID="^green;Fossil identified",
	mediumFossilID="^green;Fossil identified",
	smallFossilID="^green;Fossil identified",
	artifactID="^green;Artifact identified",
	artifactElderID="^green;Artifact identified",
	artifactProtheonID="^green;Artifact identified",
	artifactBasicID="^green;Artifact identified",
	geodeID="^green;Artifact identified",
	--bugID="^green;Insectoid identified",
	invalid="^red;Invalid sample detected"
}

local tagList={
	--FORMAT: <itemTag>={range=<math.rand max>,currencies={<currency variable name 1>=<bonusValue>,...},<optional override parameter>
	queen={range=25,currencies={bonusResearch=3,bonusGene=1}},
	youngQueen={range=25,currencies={bonusResearch=3,bonusGene=1}},
	drone={range=100,currencies={bonusGene=1}},
	--bug={range=25,currencies={bonusResearch=15,bonusGene=3},overrideCategory="bugResearched"},
	fossil={range=65,currencies={bonusResearch=60,bonusEssence=1},overrideCategory="fossilResearched"},
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
	storage.status = storage.status or statusList.waiting

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

function checkTags(item)
	if (not item) then return end
	local tags=fetchTags(item)
	local buffer=nil
	for tag,_ in pairs(tagList) do
		for _,t in pairs(tags) do
			if t==tag then
				buffer=tag
				break
			end
		end
	end
	return buffer
end

function startProcessing(itm,itmParams,lastTag)
	if lastTag~="drone" then itm.count=1 end
	if world.containerConsume(entity.id(),itm) then
		storage.processTag=lastTag
		storage.currentItem=itm
		storage.mergedParams=itmParams

		storage.futureItem=copy(storage.currentItem)
		if tagList[storage.processTag].overrideCategory then storage.futureItem.parameters.category = tagList[storage.processTag].overrideCategory end
		storage.futureItem.parameters.genomeInspected = true

		storage.progress=0
		storage.multiplier=0
		storage.status = "^cyan;"..storage.progress.."%"
	end
end

function finishProcessing()
	storage.status=statusList[storage.processTag.."ID"]

	local protheonRank=(storage.mergedParams.protheonRank or 0)
	local geneRank=(storage.mergedParams.geneRank or 0)
	local essenceRank=(storage.mergedParams.essenceRank or 0)
	local researchRank=(storage.mergedParams.researchRank or 0)

	local bonusEssence=0
	local bonusGene=0
	local bonusProtheon=0
	local bonusResearch=0

	local itemCount=storage.futureItem.count or 1

	for _=1,storage.multiplier do
		local randCheck = math.random(tagList[storage.processTag].range or 100)

		if (randCheck == self.researchSlot) and (tagList[storage.processTag].currencies.bonusResearch) then
			bonusResearch=bonusResearch+((tagList[storage.processTag].currencies.bonusResearch+microscopeRank)*itemCount) -- Gain research as this is used
		elseif (randCheck == self.essenceSlot) and (tagList[storage.processTag].currencies.bonusEssence) then
			bonusEssence=bonusEssence+((tagList[storage.processTag].currencies.bonusEssence+microscopeRank)*itemCount) -- Gain essence as this is used
		elseif (randCheck == self.protheonSlot) and (tagList[storage.processTag].currencies.bonusProtheon) then
			bonusProtheon=bonusProtheon+((tagList[storage.processTag].currencies.bonusProtheon+microscopeRank)*itemCount) -- Gain protheon as this is used
		elseif (randCheck == self.protheonSlot) and (tagList[storage.processTag].currencies.bonusGene) then
			bonusGene=bonusGene+((tagList[storage.processTag].currencies.bonusGene+microscopeRank)*itemCount) -- Gain protheon as this is used
		end
	end
	storage.multiplier=0

	storage.bonusResearch=bonusResearch+(itemCount*(researchRank))
	storage.bonusGene=bonusGene+(itemCount*(geneRank))
	storage.bonusEssence=bonusEssence+(itemCount*(essenceRank))
	storage.bonusProtheon=bonusProtheon+(itemCount*(protheonRank))
	storage.progress=0
	storage.mergedParams=nil
	storage.processTag=nil
	storage.finishedProcessing=true
end

function update(dt)
	if playerUsing or selfWorking then
		if storage.currentItem then
			if not storage.finishedProcessing then
				if playerUsing then
					storage.progress = math.min(100,storage.progress + (playerWorkingEfficiency * dt))
				else
					storage.progress = math.min(100,storage.progress + (selfWorkingEfficiency * dt))
				end
				storage.multiplier=storage.multiplier+1
				storage.progress = math.floor(storage.progress * 100) * 0.01
				storage.status = "^cyan;"..storage.progress.."%"
				if storage.progress >= 100 then
					finishProcessing()
				end
			else
				if storage.futureItem then
					if not shoveLoop(dt,storage.futureItem,self.outputSlot) then return end
					storage.futureItem=nil
				else
					if storage.bonusResearch>0 then
						shoveItem({name="fuscienceresource",count=storage.bonusResearch},self.researchSlot)
						storage.bonusResearch=0
					end
					if storage.bonusEssence>0 then
						shoveItem({name="essence",count=storage.bonusEssence},self.essenceSlot)
						storage.bonusEssence=0
					end
					if storage.bonusProtheon>0 then
						shoveItem({name="fuprecursorresource",count=storage.bonusProtheon},self.protheonSlot)
						storage.bonusProtheon=0
					end
					if storage.bonusGene>0 then
						shoveItem({name="fugeneticmaterial",count=storage.bonusGene},self.protheonSlot)
						storage.bonusGene=0
					end
					storage.currentItem=nil
					storage.finishedProcessing=false
				end
			end
		else
			local currentItem = world.containerItemAt(entity.id(), self.inputSlot)
			if currentItem == nil then
				storage.status = statusList.waiting
			else
				local currentItemParameters=currentItem and mergedParams(root.itemConfig(currentItem))
				local lastTag=checkTags(currentItemParameters)
				if not lastTag then
					storage.status = statusList.invalid
					if not shoveLoop(dt,currentItem,self.outputSlot) then return end
					world.containerTakeAt(entity.id(), self.inputSlot)
				else
					if currentItem.parameters.genomeInspected then
						storage.status=statusList[lastTag.."ID"]
						if not shoveLoop(dt,currentItem,self.outputSlot) then return end
						world.containerTakeAt(entity.id(), self.inputSlot)
					else
						startProcessing(currentItem,currentItemParameters,lastTag)
					end
				end
			end
		end
	else
		script.setUpdateDelta(-1)
	end
end

function shoveLoop(dt,currentItem,slot)
	shoveTimer=(shoveTimer or 0.0) + dt
	if not (shoveTimer >= 1.0) then
		return false
	else
		shoveTimer=0.0
	end
	if (nudgeCount or 0)>3 then
		shoveItem(currentItem,slot)
	else
		if not nudgeItem(currentItem,slot) then
			nudgeCount=(nudgeCount or 0)+1
			return false
		end
	end
	nudgeCount=0
	return true
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

function nudgeItem(item,slot)
	local slotItem=world.containerItemAt(entity.id(),self.outputSlot)
	if not item then return end
	if not slotItem then
		world.containerPutItemsAt(entity.id(),item,slot)
		return true
	end
	if slotItem.name~=item.name then return false end

	local cItem=copy(item)
	local cSlotItem=copy(slotItem)
	cItem.count=1
	cSlotItem.count=1
	if not compare(cItem,cSlotItem) then return false end

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
	if storage.status then return storage.status end
end

function currentlyWorking()
	for _,label in pairs(statusList) do
		if storage.status==label then return false end
	end
	return true
end

function die()
	if storage.finishedProcessing then
		if storage.bonusResearch>0 then
			world.spawnItem({name="fuscienceresource",count=storage.bonusResearch},entity.position())
			storage.bonusResearch=0
		end
		if storage.bonusEssence>0 then
			world.spawnItem({name="essence",count=storage.bonusEssence},entity.position())
			storage.bonusEssence=0
		end
		if storage.bonusProtheon>0 then
			world.spawnItem({name="fuprecursorresource",count=storage.bonusProtheon},entity.position())
			storage.bonusProtheon=0
		end
		if storage.bonusGene>0 then
			storage.bonusGene=0
			world.spawnItem({name="fugeneticmaterial",count=storage.bonusGene},entity.position())
		end
		if storage.futureItem then
			storage.futureItem=nil
			world.spawnItem(storage.futureItem,entity.position())
		end
		storage.currentItem=nil
	elseif storage.currentItem then
		world.spawnItem(currentItem,entity.position())
		storage.currentItem=nil
		storage.futureItem=nil
	end
end
