require "/scripts/kheAA/transferUtil.lua"

local bonusHappiness
-- This is a modified well script. wellsDrawing is being used to represent how many tenants are active under this colony core.
local rentTimer
local rentTime
local offlineTicks=0

-- This object keep work even if it's unloaded. The trick is simple
-- It simply remembers the time it was unloaded. When is loaded it will try to compensate all missed ticks.
-- It will compensate maximum 24 hours of work.

function init()
	transferUtil.loadSelfContainer()
	wellRange=config.getParameter("wellRange",128)
	rentTime=config.getParameter("productionTime",150)
	wellSlots=config.getParameter('wellslots')
	maxOfflineSeconds=config.getParameter("maxOfflineSeconds",86400)--86400 1 day
	bonusHappiness = 10
	rentTimer = 0
	wellInit()
	setDesc()

	--figuring out how many ticks we missed
	local leftTime = config.getParameter("leftTime")
	if leftTime then
		local diff=os.time() - leftTime
		if diff>0 then
			diff=math.min(math.floor(diff/rentTime),math.floor(maxOfflineSeconds/rentTime))
			offlineTicks=math.max(-1, diff - 1)
            rentTimer=rentTime+1
		end
	end
end

function update(dt)
	if not scanTimer or (scanTimer > 1) then
		scanTimer=0
		transferUtil.loadSelfContainer()
		wellInit()
		setDesc()
	else
		scanTimer=scanTimer+dt
	end
	rentTimer = rentTimer + 1
	if (rentTimer > rentTime) then
		world.containerPutItemsAt(entity.id(),{name=wellSlots[1].name,count=(10 * (wellsDrawing) * (bonusHappiness/10))*(1+offlineTicks)},0)
		offlineTicks=0
		rentTimer = 0
	end
end

function wellInit()
	transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))
	wellsDrawing=#(world.entityQuery(entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="isOccupiedMk2", callScriptResult = true}) or {})
	tallyHappiness()
end

function tallyHappiness()
	transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))
	bonusHappiness = 10
	local objectIds = world.objectQuery(storage.position, wellRange, { order = "nearest" })

	for _, objectId in pairs(objectIds) do
		if (world.callScriptedEntity(objectId,"fu_isColonyCore") and objectId ~= entity.id()) then
			object.smash()
		end
		if world.callScriptedEntity(objectId,"providesHappiness") then
			bonusHappiness = (bonusHappiness + (world.callScriptedEntity(objectId,"amountHappiness") or 0))
		end
	end

end

function uninit()
	object.setConfigParameter("leftTime", os.time() )
end

function fu_isColonyCore() return true end

function fu_isWell() return false end

function getTenantsNum() return wellsDrawing end

function setDesc()
	object.setConfigParameter('description',"^red;Range:^gray; "..wellRange.."\n^red;Tenants in range:^gray; "..((wellsDrawing or 0)).."\n^red;Total Happiness:^gray; "..(bonusHappiness).."^reset;")
end
