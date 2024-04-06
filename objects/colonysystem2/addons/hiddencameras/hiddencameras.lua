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
local tenantNumberModifier
local happinessAmount
local parentCore --save the colony core as a local so you don't have to look for it every time

function init()
	transferUtil.loadSelfContainer()

    object.setInteractive(true)
--  self.powerConsumption = config.getParameter("isn_requiredPower")
    productionTime = (config.getParameter("productionTime",120))/60
--  power.init()
	happinessAmount =  (config.getParameter("happiness",0))
    self.maxWeight = {}
    self.outputMap = {}
	tenantNumber = 0
	tenantNumberModifier=1
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

			local count=tenantNumberModifier
			if count>0 then
				count=math.sqrt(count)
				if math.floor(count)~=count then
					count=math.floor(count+(((math.random()>count-math.floor(count)) and 1) or 0))
				end
				world.containerAddItems(entity.id(), {name="fuscienceresource",count=count})
			end

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
	--tooltipString=tooltipString..
	if not self.overrideScanTooltip then return end
	local tooltipString="^white;Range:^gray; "..wellRange.."\n^white;Tenants: "
	local wellCount=((wellsDrawing or 0)-1)

	--colony stuff calc
	if tenantNumber>0 then
		tooltipString=tooltipString.."^green;"
	else
		tooltipString=tooltipString.."^red;"
	end
	tooltipString=tooltipString..tenantNumber.." ^white;(Yield: x"

	local tenantModRounded=util.round(tenantNumberModifier,2)
	if tenantNumberModifier>1 then
		tooltipString=tooltipString.."^green;"
	else
		tooltipString=tooltipString.."^white;"
	end
	tooltipString=tooltipString..tenantModRounded.."^white;)\nSimilar Objects: "

	if wellCount>0 then
		tooltipString=tooltipString.."^red;"
	else
		tooltipString=tooltipString.."^green;"
	end
	tooltipString=tooltipString..wellCount.."\n^white;Happiness: "

	local happy=amountHappiness()
	if happy<0 then
		tooltipString=tooltipString.."^red;"
	else
		tooltipString=tooltipString.."^white;+"
	end
	tooltipString=tooltipString..happy.."^reset;"

	object.setConfigParameter('description',tooltipString)
end

function wellInit()
	--transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))
	getTenantNumber()
	if not wellRange then wellRange=config.getParameter("wellRange",256) end
	wellsDrawing=1+#(world.entityQuery(entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="fu_isAddonHiddenCameras"}) or {})
end

function fu_isAddonHiddenCameras() return true end

function getTenantNumber()
	tenantNumber = 0
	if parentCore and world.entityExists(parentCore) then
		tenantNumber = world.callScriptedEntity(parentCore,"getTenantsNum") or 0
	else
		--transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))

		local objectIds = world.objectQuery(storage.position, wellRange/2, { order = "nearest" })

		for _, objectId in pairs(objectIds) do
			if world.callScriptedEntity(objectId,"fu_isColonyCore") then
				tenantNumber = world.callScriptedEntity(objectId,"getTenantsNum") or 0
				parentCore = objectId
			end
		end
	end
	if tenantNumber>0 then
		tenantNumberModifier=tenantNumber/(tenantNumber^(1/3))
	else
		tenantNumberModifier=0
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