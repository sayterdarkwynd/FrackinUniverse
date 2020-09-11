require "/scripts/util.lua"
require "/scripts/kheAA/transferUtil.lua"
--require "/scripts/fupower.lua"

-- You might notice there's no timer here.
-- The time between outputs and power consumption is determined by
-- the object's "scriptDelta".

-- Added in the scanTimer variable as it's common in any lua code which
-- interacts with Item Transference Device (transferUtil) code.
local scanTimer	-- Making it local is faster than leaving it global.
local tenantNumber 
local happinessAmount
local parentCore --save the colony core as a local so you don't have to look for it every time

function init()
    transferUtil.init()
    object.setInteractive(true)
--  self.powerConsumption = config.getParameter("isn_requiredPower")
    productionTime = (config.getParameter("productionTime",120))/60
--  power.init()
	happinessAmount =  (config.getParameter("happiness",0))
    self.maxWeight = {}
    self.outputMap = {}
	tenantNumber = 0
--    initMap(world.type())
	wellRange=config.getParameter("wellRange",256)
	wellInit()
	self.rarityInfoLevel=config.getParameter("rarityInfoLevel",0)
	self.overrideScanTooltip=config.getParameter("overrideScanTooltip",false)
	setDesc()
end

function initMap(worldtype)
    -- Set up output here so it won't take up time later
    local outputConfig = config.getParameter("outputs")
    local outputTable = outputConfig["default"]
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
--	power.update(dt)
	
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
		
		--and power.consume(self.powerConsumption)
		if clearSlotCheck("fuscienceresource") then
			if object.outputNodeCount() > 0 then
				object.setOutputNodeLevel(0,true)
			end
		--	animator.setAnimationState("machineState", "active")
			world.containerAddItems(entity.id(), {name="fuscienceresource",count=tenantNumber})
		else
			if object.outputNodeCount() > 0 then
				object.setOutputNodeLevel(0,false)
			end
		--	animator.setAnimationState("machineState", "idle")
		end
		storage.timer=0
	else
		if wellsDrawing == 1 then
			storage.timer=storage.timer+(dt)
		end
	end
end

function clearSlotCheck(checkname)
	return world.containerItemsCanFit(entity.id(), checkname) > 0
end


function setDesc()
	if not self.overrideScanTooltip then return end

	object.setConfigParameter('description',"^red;Range:^gray; "..wellRange.."\n^red;Similar Objects:^gray; "..((wellsDrawing or 0)-1).."\n^red;Tenants:^gray; "..tenantNumber.."\n^red;Happiness Factor: ^gray; "..happinessAmount.."^reset;")
end


function wellInit()
	if not wellRange then wellRange=config.getParameter("wellRange",256) end
	wellsDrawing=1+#(world.entityQuery(entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="fu_isAddonHiddenCameras"}) or {})
	getTenantNumber()
end

function fu_isAddonHiddenCameras() return true end

function getTenantNumber()
	tenantNumber = 0
	if parentCore then
		tenantNumber = world.callScriptedEntity(parentCore,"getTenants")
	else
		transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))

		local objectIds = world.objectQuery(storage.position, wellRange/2, { order = "nearest" })
	
		for _, objectId in pairs(objectIds) do
				if world.callScriptedEntity(objectId,"fu_isColonyCore") then
					tenantNumber = world.callScriptedEntity(objectId,"getTenants")
					parentCore = objectId
				end
		end
	end
	
end


function providesHappiness() return true end

function amountHappiness() 
	if wellsDrawing == 1 then
		return happinessAmount 
	else
		return 0 
	end
	
end



function firstToUpper(str)
	--sb.logInfo("%s",str)
    return (str:gsub("^%l", string.upper))
end