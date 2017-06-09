require "/objects/generic/centrifuge_recipes.lua"
require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0


function init()
  transferUtil.init()
	storage.currentinput = nil
	storage.currentoutput = nil
	storage.bonusoutputtable = nil
	storage.activeConsumption = false

	self.centrifugeType = config.getParameter("centrifugeType") or error("centrifugeType is undefined in .object file") -- die horribly

	self.itemChances = config.getParameter("itemChances")
	self.inputSlot = config.getParameter("inputSlot",1)

	self.needsPower = config.getParameter("isn_powerReciever",false)

	self.initialCraftDelay = config.getParameter("craftDelay",0)
	storage.craftDelay = storage.craftDelay or self.initialCraftDelay
	storage.combsProcessed = storage.combsProcessed or { count = 0 }
	--sb.logInfo("centrifuge: %s", storage.combsProcessed)

	self.combsPerJar = 3 -- ref. recipes

  self.recipeTable = getRecipes()
  self.recipeTypes = self.recipeTable.recipeTypes[self.centrifugeType]

	storage.init = true

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
	if deltaTime>1 then
		transferUtil.loadSelfContainer()
		deltaTime=0
	else
		deltaTime=deltaTime+dt
	end
	local input = world.containerItems(entity.id())[self.inputSlot]
	if not self.needsPower or isn_hasRequiredPower() then
		if input then
			local output = deciding(input)
			if output then
				workingCombs(input, output)
				animator.setAnimationState("centrifuge", "working")
				storage.activeConsumption = true
				return
			end
		end
                
		if storage.combsProcessed and storage.combsProcessed.count > 0 then
			-- discard the stash if unclaimed by a jarrer within a reasonable time (twice the craft delay)
			storage.combsProcessed.stale = (storage.combsProcessed.stale or (self.initialCraftDelay * 2)) - 1
			if storage.combsProcessed.stale == 0 then
				drawHoney() -- effectively clear the stash, stopping the jarrer from getting it
			end
		end
	end

	if (self.needsPower and isn_hasRequiredPower() == false) or storage.currentoutput == nil or clearSlotCheck(storage.currentoutput) == false then
		animator.setAnimationState("centrifuge", "idle")
		storage.craftDelay = self.initialCraftDelay
		storage.activeConsumption = false
		return
	end
end

function workingCombs(input, output)
	storage.craftDelay = storage.craftDelay - 1

	if storage.craftDelay <= 0 then
		storage.craftDelay = self.initialCraftDelay
		world.containerConsume(entity.id(), { name = input.name, count = 1, data={}})
		stashHoney(input.name)

		local rnd = math.random()
		for item, chancePair in pairs(output) do
      local chanceBase,chanceDivisor = table.unpack(chancePair)
      local chance = self.itemChances[chanceBase] / chanceDivisor
			local done=false
			local throw=nil
			if rnd <= chance then
				local contSize=world.containerSize(entity.id())
				for i=1,contSize-1 do
					throw = world.containerPutItemsAt(entity.id(), { name = item, count = 1, data={}},i)
					if throw==nil then
						done=true
						break
					end
				end
				if done then
					break
				end
			end
			if throw then world.spawnItem(throw, entity.position()) end -- hope that the player or an NPC which collects items is around
			rnd = rnd - chance
		end
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
			storage.combsProcessed.count = math.min(storage.combsProcessed.count + 1, self.combsPerJar) -- limit to one jar's worth  in stash at any given time
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
