require "/scripts/util.lua"
require "/scripts/poly.lua"
require "/scripts/vec2.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fupower.lua"

-- You might notice there's no timer here.
-- The time between outputs and power consumption is determined by
-- the object's "scriptDelta".

-- Added in the scanTimer variable as it's common in any lua code which
-- interacts with Item Transference Device (transferUtil) code.
local scanTimer	-- Making it local is faster than leaving it global.

function init()
    object.setInteractive(true)
    self.powerConsumption = config.getParameter("isn_requiredPower")
    productionTime = (config.getParameter("productionTime",120))/60
    power.init()

    self.maxWeight = {}
    self.outputMap = {}

    initMap(world.type())
	wellRange=config.getParameter("wellRange",20)
	wellInit()
	self.rarityInfoLevel=config.getParameter("rarityInfoLevel",0)
	self.overrideScanTooltip=config.getParameter("overrideScanTooltip",false)
	setDesc()
end

function initMap(worldtype)
    -- Set up output here so it won't take up time later
    local outputConfig = config.getParameter("outputs")
    local outputTable = outputConfig[worldtype] or outputConfig["default"]
    if type(outputTable) == "string" then
        outputTable = outputConfig[outputTable]
    end
    local weights = config.getParameter("namedWeights")
    self.maxWeight[worldtype] = 0
    self.outputMap[worldtype] = {}
    for _,myTable in ipairs(outputTable or {}) do
        local weight = weights[myTable.weight] or myTable.weight
        self.maxWeight[worldtype] = self.maxWeight[worldtype] + weight
        self.outputMap[worldtype][weight] = myTable.items
    end
end

function update(dt)
    power.update(dt)

	-- Notify ITD but no faster than once per second.
	if not scanTimer or (scanTimer > 1) then
		transferUtil.loadSelfContainer()
		wellInit()
		setDesc()
		scanTimer = 0
	else
		scanTimer=scanTimer+dt
	end

	if not storage.timer then
		storage.timer=0
	end
	if storage.timer>=productionTime then

		local worldtype = world.type()
		if worldtype == 'unknown' then
			worldtype = world.getProperty("ship.celestial_type") or worldtype
		end
		if not self.outputMap[worldtype] then
			initMap(worldtype)
		end

		local output = nil
		local rarityroll = math.random(1, self.maxWeight[worldtype])

		-- Goes through the list adding values to the range as it goes.
		-- This keeps the chance ratios while allowing the list to be in any order.
		local total = 0
		for weight,myTable in pairs(self.outputMap[worldtype]) do
			total = total + weight
			if rarityroll <= total then
				output = util.randomFromList(myTable)
				break
			end
		end

		if output and clearSlotCheck(output) and power.consume(self.powerConsumption) then
			if object.outputNodeCount() > 0 then
				object.setOutputNodeLevel(0,true)
			end
			animator.setAnimationState("machineState", "active")
			world.containerAddItems(entity.id(), output)
		else
			if object.outputNodeCount() > 0 then
				object.setOutputNodeLevel(0,false)
			end
			animator.setAnimationState("machineState", "idle")
		end
		storage.timer=0
	else
		storage.timer=storage.timer+(dt/math.sqrt(wellsDrawing))
	end
end

function clearSlotCheck(checkname)
	return world.containerItemsCanFit(entity.id(), checkname) > 0
end


function setDesc()
	if not self.overrideScanTooltip then return end

	local worldtype = world.type()
	if worldtype == 'unknown' then
		worldtype = world.getProperty("ship.celestial_type") or worldtype
	end

	local buffer={}
    local outputConfig = config.getParameter("outputs")
    local outputTable = outputConfig[worldtype] or outputConfig["default"] or {}

	--sb.logInfo("%s",outputTable)

	if type(outputTable) == "string" then
		outputTable = outputConfig[outputTable] or outputConfig["default"] or {}
	end

	local buffer2=""

	if self.rarityInfoLevel > 0 then
		buffer2={}
		for _,myTable in pairs(outputTable) do
			local weight=myTable.weight
			if weight=="common" then
				local items=myTable.items
				buffer[weight]={}
				for _,item in pairs(items) do
					local dummy=string.gsub(root.itemConfig(item).config.shortdescription,"%^.-;","")
					table.insert(buffer[weight],dummy)
				end
				buffer[weight]=table.concat(buffer[weight],", ")
				buffer2[1]="^reset;"..firstToUpper(weight).."^gray;: "..buffer[weight].."^reset;"
			elseif weight=="uncommon" and self.rarityInfoLevel > 1 then
				local items=myTable.items
				buffer[weight]={}
				for _,item in pairs(items) do
					local dummy=string.gsub(root.itemConfig(item).config.shortdescription,"%^.-;","")
					table.insert(buffer[weight],dummy)
				end
				buffer[weight]=table.concat(buffer[weight],", ")
				buffer2[2]="^green;"..firstToUpper(weight).."^gray;: "..buffer[weight].."^reset;"
			elseif weight=="rare" and self.rarityInfoLevel > 2 then
				local items=myTable.items
				buffer[weight]={}
				for _,item in pairs(items) do
					local dummy=string.gsub(root.itemConfig(item).config.shortdescription,"%^.-;","")
					table.insert(buffer[weight],dummy)
				end
				buffer[weight]=table.concat(buffer[weight],", ")
				buffer2[3]="^cyan;"..firstToUpper(weight).."^gray;: "..buffer[weight].."^reset;"
			end
		end
		buffer=table.concat(buffer2,"\n")
		buffer2="^blue;Outputs:^reset;\n"..buffer.."\n"
	end

	object.setConfigParameter('description',buffer2.."^red;Well Range:^gray; "..wellRange.."\n^red;Wells in range:^gray; "..((wellsDrawing or 0)-1).."^reset;")
end


function wellInit()
	if not wellRange then wellRange=config.getParameter("wellRange",20) end
	if (not storage.wellPos) and object.spaces() then storage.wellPos=vec2.add(poly.center(object.spaces()),object.position()) end
	wellsDrawing=1+#(world.entityQuery(storage.wellPos or entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="fu_isAirWell"}) or {})
end

function fu_isAirWell() return (animator.animationState("machineState")=="active") end

function firstToUpper(str)
	--sb.logInfo("%s",str)
    return (str:gsub("^%l", string.upper))
end
