require "/scripts/kheAA/transferUtil.lua"

local bonusHappiness
-- This is a modified well script. wellsDrawing is being used to represent how many tenants are active under this colony core.
local rentTimer
local rentGoal

function init()
	transferUtil.loadSelfContainer()
	wellRange=config.getParameter("wellRange",128)
	rentGoal=config.getParameter("productionTime",150)
	bonusHappiness = 10
	rentTimer = 0
	wellInit()
	setDesc()
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

--	  for i=2,#config.getParameter('wellslots') do
--	    if world.containerItemAt(entity.id(),i-1) and world.containerItemAt(entity.id(),i-1).name ~= config.getParameter('wellslots')[i].name then
--	      world.containerConsumeAt(entity.id(),i-1,world.containerItemAt(entity.id(),i-1).count)
--	      world.spawnItem(world.containerItemAt(entity.id(),i-1),entity.position())
--	    end
--	  end


--	  if item.name ~= config.getParameter('wellslots')[1].name then
--	    world.spawnItem(item,entity.position())
--	    world.containerConsumeAt(entity.id(),0,item.count)
--	    item.count = 0
--	  elseif item.count > config.getParameter('wellslots')[1].max then
--	    local dropitem = item
--	    dropitem.count = dropitem.count - config.getParameter('wellslots')[1].max
--	    world.spawnItem(dropitem,entity.position())
--	    world.containerConsumeAt(entity.id(),0,dropitem.count)
--	    item.count = config.getParameter('wellslots')[1].max
--	  end
	if (rentTimer > rentGoal) then
--		local item = world.containerItemAt(entity.id(),0) or {name=config.getParameter('wellslots')[1].name,count=0}
--		local amount = math.min(math.floor(storage.waterCount/config.getParameter('wellslots')[1].ratio),config.getParameter('wellslots')[1].max - item.count)
		world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[1].name,count=(10 * (wellsDrawing) * (bonusHappiness/10))},0)
	 -- storage.waterCount = math.min((storage.waterCount or 0) + dt,100)
	--	storage.waterCount = storage.waterCount - amount * config.getParameter('wellslots')[1].ratio
		rentTimer = 0
	end

--	  if amount > 0 and #config.getParameter('wellslots') > 1 then
--	    for i=(storage.count or 0)+1,(storage.count or 0)+amount do
--	      for j=2,#config.getParameter('wellslots') do
--		amountmod = math.min(math.floor(math.max(config.getParameter('wellslots')[j].count/config.getParameter('wellslots')[j].amount,1)),config.getParameter('wellslots')[j].amount)
--		if config.getParameter('wellslots')[j].chance > 0 and math.fmod(i,config.getParameter('wellslots')[j].count/amountmod) == 0 and math.random() <= config.getParameter('wellslots')[j].chance then
--		  world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[j].name,count=config.getParameter('wellslots')[j].amount/amountmod},j-1)
--		end
--	      end
--	    end
--	    storage.count = (storage.count or 0) + amount
--	  end

end

function wellInit()
	transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))
	wellsDrawing= #(world.entityQuery(entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="isOccupiedMk2", callScriptResult = true}) or {})
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

function fu_isColonyCore() return true end

function fu_isWell() return false end

function getTenantsNum() return wellsDrawing end





function setDesc()
	object.setConfigParameter('description',"^red;Range:^gray; "..wellRange.."\n^red;Tenants in range:^gray; "..((wellsDrawing or 0)).."\n^red;Total Happiness:^gray; "..(bonusHappiness).."^reset;")
end
