require "/scripts/util.lua"
--require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fupower.lua"

-- You might notice there's no timer here.
-- The time between outputs and power consumption is determined by
-- the object's "scriptDelta".

-- Added in the scanTimer variable as it's common in any lua code which
-- interacts with Item Transference Device (transferUtil) code.
local scanTimer	-- Making it local is faster than leaving it global.
local tenantNumber
local happinessAmount
local hasPower
local parentCore --save the colony core as a local so you don't have to look for it every time

function init()
	--transferUtil.loadSelfContainer()
	storage.position=entity.position()
    object.setInteractive(false)
	self.powerConsumption = config.getParameter("isn_requiredPower")
    productionTime = (config.getParameter("productionTime",120))/60
	power.init()
	happinessAmount =  (config.getParameter("happiness",0))
--  self.maxWeight = {}
 -- self.outputMap = {}
	tenantNumber = 0
	hasPower = 0
  --initMap(world.type())
	wellRange=config.getParameter("wellRange",256)
	wellInit()
--	self.rarityInfoLevel=config.getParameter("rarityInfoLevel",0)
	self.overrideScanTooltip=config.getParameter("overrideScanTooltip",true)
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
	power.update(dt)
	if not scanTimer or (scanTimer > 1) then
		--transferUtil.loadSelfContainer()
		wellInit()
		setDesc()
		scanTimer = 0
	else
		scanTimer=scanTimer+dt
	end
	if power.consume(config.getParameter('isn_requiredPower')) then
		hasPower = 1
	else
		hasPower = 0
	end
end

function clearSlotCheck(checkname)
	return world.containerItemsCanFit(entity.id(), checkname) > 0
end

function setDesc()
	if not self.overrideScanTooltip then return end
	local tooltipString="^white;Range:^gray; "..wellRange.."\n^white;Tenants: ^"
	local wellCount=((wellsDrawing or 0)-1)

	--colony stuff calc
	if tenantNumber>0 then
		tooltipString=tooltipString.."green"
	else
		tooltipString=tooltipString.."red"
	end
	tooltipString=tooltipString..";"..tenantNumber.." ^white;\nSimilar Objects:^"

	if wellCount>0 then
		tooltipString=tooltipString.."red"
	else
		tooltipString=tooltipString.."green"
	end
	tooltipString=tooltipString.."; "..wellCount.."\n^white;Happiness Factor:^"

	local happy=amountHappiness()
	if happy>0 then
		tooltipString=tooltipString.."green"
	else
		tooltipString=tooltipString.."white"
	end
	tooltipString=tooltipString.."; "..happy.."\n^white;Powered:^"

	if hasPower>0 then
		tooltipString=tooltipString.."green"
	else
		tooltipString=tooltipString.."red"
	end
	tooltipString=tooltipString.."; "..(hasPower>0 and "true" or "false").."^reset;"

	object.setConfigParameter('description',tooltipString)
end

function wellInit()
	--transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))
	getTenantNumber()
	if not wellRange then wellRange=config.getParameter("wellRange",256) end
	wellsDrawing=1+#(world.entityQuery(entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="fu_isAddonFTLCommsDish"}) or {})
end

function fu_fu_isAddonFTLCommsDish() return true end

function getTenantNumber()
	tenantNumber = 0
	if parentCore and world.entityExists(parentCore) then
		tenantNumber = world.callScriptedEntity(parentCore,"getTenantsNum")
	else
		--transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))

		local objectIds = world.objectQuery(storage.position, wellRange/2, { order = "nearest" })

		for _, objectId in pairs(objectIds) do
			if world.callScriptedEntity(objectId,"fu_isColonyCore") then
				tenantNumber = world.callScriptedEntity(objectId,"getTenantsNum")
				parentCore = objectId
			end
		end
	end

end

function providesHappiness() return true end

function amountHappiness()
	if wellsDrawing == 1 then
		return (happinessAmount*hasPower)
	else
		return 0
	end

end

function firstToUpper(str)
	--sb.logInfo("%s",str)
    return (str:gsub("^%l", string.upper))
end