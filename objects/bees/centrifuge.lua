require "/objects/generic/centrifuge_recipes.lua"
require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require '/scripts/fupower.lua'

function init()
	if config.getParameter('powertype') then
		power.init()
		powered = true
	else
		powered = false
	end
	--storage.activeConsumption = storage.activeConsumption or false
	self.requiredPower=config.getParameter("isn_requiredPower")
	self.powered=(type(self.requiredPower)=="number") and (self.requiredPower>0)

	self.centrifugeType = config.getParameter("centrifugeType") or error("centrifugeType is undefined in .object file") -- die horribly

	self.itemChances = config.getParameter("itemChances")
	self.inputSlot = config.getParameter("inputSlot",1)

	self.initialCraftDelay = config.getParameter("craftDelay",1)
	--script.setUpdateDelta(self.initialCraftDelay*60.0)
	script.setUpdateDelta(1)

	if self.powered then
		self.effectiveRequiredPower=self.requiredPower*self.initialCraftDelay
	end

	--storage.craftDelay = storage.craftDelay or self.initialCraftDelay
	storage.combsProcessed = storage.combsProcessed or { count = 0 }
	--sb.logInfo("centrifuge: %s", storage.combsProcessed)

	self.combsPerJar = 3 -- ref. recipes

	self.recipeTable = getRecipes()
	self.recipeTypes = self.recipeTable.recipeTypes[self.centrifugeType]

	handleOnOff()
	math.randomseed(util.seedTime())
	object.setInteractive(true)
end

function deciding(item)
	for i=#self.recipeTypes,1,-1 do
		if self.recipeTable[self.recipeTypes[i]][item.name] then
			return self.recipeTable[self.recipeTypes[i]][item.name]
		end
	end
	return nil
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	if not storage.timer then storage.timer=self.initialCraftDelay end
	if storage.timer > 0 then
		storage.timer = math.max(storage.timer - dt,0)
	elseif storage.timer == 0 then
		if storage.activeConsumption then
			storage.currentinput={ name = storage.input.name, count = 1}
			stashHoney(storage.input.name)
			storage.input = nil
			storage.activeConsumption = false
			local rnd = math.random()
			for item, chancePair in pairs(storage.output) do
				local chanceBase,chanceDivisor = table.unpack(chancePair)
				local chance = self.itemChances[chanceBase] / chanceDivisor
				local done=false
				if rnd <= chance then
					local throw={parameters={}, name=item, count=1}
					local contSize=world.containerSize(entity.id())
					for i=self.inputSlot,contSize-1 do
						if throw then
							throw = world.containerPutItemsAt(entity.id(),throw,i)
						end
						if not throw then
							done=true
							break
						end
					end
					if throw then
						world.spawnItem(throw, entity.position())
						done=true
					end
					if done then
						break
					end
				end
				storage.currentinput=nil
				rnd = rnd - chance
			end
			storage.output=nil
			storage.timer=-1
		end
		local input
		for i=0,self.inputSlot-1 do
			input = world.containerItemAt(entity.id(),i)
			if input then
				local output = deciding(input)
				if output then
					if ((not self.powered) or (power.getTotalEnergy()>=self.effectiveRequiredPower)) and world.containerConsume(entity.id(), { name = input.name, count = 1, data={}}) and ((not self.powered) or power.consume(self.effectiveRequiredPower)) then
						storage.output = output
						storage.input = input
						storage.activeConsumption = true
					else
						storage.activeConsumption = false
					end
					break
				end
			end
		end
	else
		handleOnOff()
		storage.timer = self.initialCraftDelay
	end

	if storage.combsProcessed and storage.combsProcessed.count > 0 then
		-- discard the stash if unclaimed by a jarrer within a reasonable time (twice the craft delay)
		storage.combsProcessed.stale = (storage.combsProcessed.stale or (self.initialCraftDelay * 2)) - dt
		if storage.combsProcessed.stale == 0 then
			drawHoney() -- effectively clear the stash, stopping the jarrer from getting it
		end
	end

	if powered then
		power.update(dt)
	end
end

function handleOnOff()
	animator.setAnimationState("centrifuge", storage.activeConsumption and "working" or "idle")
	if object.outputNodeCount() > 0 then
		object.setOutputNodeLevel(0,storage.activeConsumption)
	end
end

function stashHoney(comb)
	-- For any nearby jarrer (if this is an industrial centrifuge),
	-- Record that we've processed a comb.
	-- The stashed type is the jar object name for the comb type.
	-- If the stashed type is different, reset the count.

	local jar = honeyCheck and honeyCheck(comb)

	if jar then
		if storage.combsProcessed == nil then storage.combsProcessed = { count = 0 } end
		if storage.combsProcessed.type == jar then
			storage.combsProcessed.count = math.min(storage.combsProcessed.count + 1, self.combsPerJar) -- limit to one jar's worth	in stash at any given time
			storage.combsProcessed.stale = nil
		else
			storage.combsProcessed = { type = jar, count = 1 }
		end
		--sb.logInfo("STASH: %s %s", storage.combsProcessed.count,storage.combsProcessed.type)
	end
end

-- Called by the honey jarrer
function drawHoney()
	if not storage.combsProcessed or storage.combsProcessed.count == 0 then return nil end
	local ret = storage.combsProcessed
	storage.combsProcessed = { count = 0 }
	--sb.logInfo("STASH: Withdrawing")
	return ret
end

function die()
	--safety for fringe cases
	if storage.currentinput then
		world.spawnItem(storage.currentinput,entity.position())
	end
	storage.currentinput=nil
end
