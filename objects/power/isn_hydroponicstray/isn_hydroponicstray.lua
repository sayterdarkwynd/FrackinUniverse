require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"

local deltaTime=0
function init()
  power.init()
	transferUtil.init()
	object.setInteractive(true)
	
	storage.fertSpeed = storage.fertSpeed or 0
	storage.fertYield = storage.fertYield or 0
	storage.liquidMod = storage.liquidMod or 2
	storage.seedMod = storage.seedMod or 3
	
	storage.growth = storage.growth or 0
	storage.water = storage.water or 0
	storage.yield = storage.yield or 0
	storage.growthcap = storage.growthcap or config.getParameter("isn_growthCap")
	storage.activeConsumption = storage.activeConsumption or false
	storage.seedslot = 1
	storage.waterslot = 2
	storage.fertslot = 3
	storage.primaryItems = storage.primaryItems or nil
	storage.secondaryItems = storage.secondaryItems or nil
	storage.secondaryYield = storage.secondaryYield or 0
	storage.saplingParameters = storage.saplingParameters or nil
end

function update(dt)
  power.update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	storage.activeConsumption = false
	
	if storage.currentseed == nil or storage.currentcrop == nil then
		if isn_doSeedIntake() ~= true then animator.setAnimationState("powlight", "off") return end
	end
	
	if power.consume(config.getParameter('isn_requiredPower')*dt) then
	  growthmod = 1
	  animator.setAnimationState("powlight", "on")
	else
	  growthmod = 0.434782609
	  animator.setAnimationState("powlight", "off")
	end
	
	local growthperc = isn_getXPercentageOfY(storage.growth,storage.growthcap)
	if growthperc >= 75 then
		animator.setAnimationState("growth", "3")
	elseif growthperc >= 50 then
		animator.setAnimationState("growth", "2")
	elseif growthperc >= 25 then
		animator.setAnimationState("growth", "1")
	else
		animator.setAnimationState("growth", "0")
	end
	
	if storage.water <= 0 and isn_doWaterIntake() ~= true then return end
	storage.water = storage.water - dt / 2
	storage.activeConsumption = true
	storage.growth = storage.growth + growthmod * dt
	
	if storage.fertSpeed then
		storage.growth = storage.growth + growthmod + storage.fertSpeed * dt
	end
	
	if storage.growth >= storage.growthcap then
		if storage.saplingParameters then
			if storage.saplingParameters.stemName then
			world.containerAddItems(entity.id(), {name = storage.currentseed, count = 1, parameters = storage.saplingParameters})
			end
		else
			world.containerAddItems(entity.id(), {name = storage.currentseed, count = math.random(1,3), data={}})
		end	
		if storage.primaryItems then
			for _,item in pairs (storage.primaryItems) do
				fu_sendOrStoreItems(0, {name = item, count = storage.yield}, {0, 1, 2})
			end
			if storage.secondaryItems then
				for _,item in pairs (storage.secondaryItems) do
				if item == "sapling" then
					if storage.saplingParameters.stemName then
						world.containerAddItems(entity.id(), {name = storage.currentseed, count = math.random(0,1), parameters = storage.saplingParameters})
					end
				else
					fu_sendOrStoreItems(0, {name = item, count = storage.secondaryYield}, {0, 1, 2})
				end
			end
			end
		else
			fu_sendOrStoreItems(0, {name = storage.currentcrop, count = storage.yield}, {0, 1, 2})
		end

		isn_doFertIntake()
		isn_doSeedIntake()
	end
end

function isn_doWaterIntake()
	local contents = world.containerItems(entity.id())
	local water = contents[storage.waterslot]
	if water == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_waterInputs")) do
		if water.name == key then
			storage.water = value
			world.containerConsume(entity.id(), {name = water.name, count = storage.liquidMod, data={}})
			return true
		end
	end
	return false
end

function isn_doSeedIntake()
	storage.growth = 0
	storage.currentseed = nil
	storage.currentcrop = nil
	local contents = world.containerItems(entity.id())
	local seed = contents[storage.seedslot]
	if seed == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_seedOutputs")) do
		if seed.name == key then
			storage.currentseed = key
			storage.currentcrop = value
			storage.yield = math.random(3,5)
			if storage.fertYield == 1 then storage.yield = storage.yield * 2
			elseif storage.fertYield == 2 then storage.yield = storage.yield * 3
			elseif storage.fertYield == 3 then storage.yield = storage.yield * 4 end
			world.containerConsume(entity.id(), {name = seed.name, count = storage.seedMod, data={}})
			storage.primaryItems = nil
			storage.secondaryItems = nil
			storage.saplingParameters = nil
			return true
		end
	end
	
	if seed.name == "sapling" then
		local saplings = world.containerItems(entity.id(), storage.seedslot)
		for _,sapling in pairs(saplings) do
			local stemType = sapling.parameters.stemName
			local foliageType = sapling.parameters.foliageName
			if stemType and foliageType then
				storage.primaryItems = {}
				storage.secondaryItems = {}
				storage.saplingParameters = {}
				local stemPath = root.treeStemDirectory(stemType)
				local stemJson = root.assetJson(stemPath .. stemType .. ".modularstem")
				local stemInfo = stemJson.dropConfig.drops
				for _,stemDrops in pairs(stemInfo) do
					for _,stem in pairs(stemDrops) do
						storage.primaryItems[stem.item] = stem.item
					end
					if storage.primaryItems then
						local foliagePath = root.treeFoliageDirectory(foliageType)
						local foliageJson = root.assetJson(foliagePath .. foliageType .. ".modularfoliage")
						local foliageInfo = foliageJson.dropConfig.drops
						for _,foliageDrops in pairs(foliageInfo) do
							for _,foliage in pairs(foliageDrops) do
								storage.secondaryItems[foliage.item] = foliage.item
							end
						end
						storage.saplingParameters = sapling.parameters
						storage.currentseed = "sapling"
						storage.currentcrop = "logblock"
						storage.yield = math.random(3,5)
						storage.secondaryYield = math.random(1,2)
						if storage.fertYield == 1 then storage.yield = storage.yield * 2
						storage.secondaryYield = storage.secondaryYield * 1
						elseif storage.fertYield == 2 then storage.yield = storage.yield * 3
						storage.secondaryYield = storage.secondaryYield * 2
						elseif storage.fertYield == 3 then storage.yield = storage.yield * 4 
						storage.secondaryYield = storage.secondaryYield * 3 end
						world.containerConsume(entity.id(), {name = "sapling", count = 1, data={}})
						return true
					end
				end
			end
		end
	else return false
	end
end

function isn_doFertIntake()
	storage.fertSpeed = 0
	storage.fertYield = 0
	local contents = world.containerItems(entity.id())
	local fert = contents[storage.fertslot]
	if fert == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_fertInputs")) do
		if fert.name == key then
			if value == 1 then --basic speed
				storage.fertSpeed = 1
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 2 then -- basic yield
				storage.fertYield = 1
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 3 then --basic speed, good yield
				storage.fertSpeed = 1
				storage.fertYield = 2
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 4 then -- good speed, basic yield
				storage.fertSpeed = 2
				storage.fertYield = 1
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 5 then -- great speed,good yield
				storage.fertSpeed = 3
				storage.fertYield = 2
				storage.liquidMod = 2
				storage.seedMod = 2
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 6 then -- great speed,great yield
				storage.fertSpeed = 2
				storage.fertYield = 3	
				storage.liquidMod = 2
				storage.seedMod = 1
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true	
			elseif value == 7 then -- low liquid consumption
				storage.liquidMod = 1	
				storage.fertSpeed = 1
				storage.fertYield = 1
				storage.seedMod = 2
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true	
			else
				storage.liquidMod = 2	
				storage.fertSpeed = 0
				storage.fertYield = 0
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true			
			end
		end
	end
	return false
end
