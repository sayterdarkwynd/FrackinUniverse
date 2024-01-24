require "/scripts/kheAA/transferUtil.lua"
require "/scripts/poly.lua"
require "/scripts/vec2.lua"

function init()
	wellRange=config.getParameter("wellRange",20)
	wellInit()
	setDesc()
end

function update(dt)
	if world.type() ~= 'unknown' and world.type() ~= 'playerstation' then
		if not scanTimer or (scanTimer > 1) then
			scanTimer=0
			transferUtil.loadSelfContainer()
			wellInit()
			setDesc()
		else
			scanTimer=scanTimer+dt
		end

		storage.waterCount = math.min((storage.waterCount or 0) + (dt/math.sqrt(wellsDrawing)),100)

		for i=2,#config.getParameter('wellslots') do
			local slotItem=world.containerItemAt(entity.id(),i-1)
			if slotItem and slotItem.name ~= config.getParameter('wellslots')[i].name then
				local didConsume=world.containerConsumeAt(entity.id(),i-1,slotItem.count)
				if didConsume then
					world.spawnItem(slotItem,entity.position())
				end
			end
		end

		local item = world.containerItemAt(entity.id(),0) or {name=config.getParameter('wellslots')[1].name,count=0}
		if item.name ~= config.getParameter('wellslots')[1].name then
			local didConsume=world.containerConsumeAt(entity.id(),0,item.count)
			if didConsume then world.spawnItem(item,entity.position()) end
			item.count = 0
		elseif item.count > config.getParameter('wellslots')[1].max then
			local dropitem = copy(item)
			dropitem.count = dropitem.count - config.getParameter('wellslots')[1].max
			world.spawnItem(dropitem,entity.position())
			world.containerConsumeAt(entity.id(),0,dropitem.count)
			item.count = config.getParameter('wellslots')[1].max
		end

		local amount = math.min(math.floor(storage.waterCount/config.getParameter('wellslots')[1].ratio),config.getParameter('wellslots')[1].max - item.count)
		world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[1].name,count=amount},0)
		storage.waterCount = storage.waterCount - amount * config.getParameter('wellslots')[1].ratio

		if amount > 0 and #config.getParameter('wellslots') > 1 then
			for i=(storage.count or 0)+1,(storage.count or 0)+amount do
				for j=2,#config.getParameter('wellslots') do
					amountmod = math.min(math.floor(math.max(config.getParameter('wellslots')[j].count/config.getParameter('wellslots')[j].amount,1)),config.getParameter('wellslots')[j].amount)
					if config.getParameter('wellslots')[j].chance > 0 and math.fmod(i,config.getParameter('wellslots')[j].count/amountmod) == 0 and math.random() <= config.getParameter('wellslots')[j].chance then
						world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[j].name,count=config.getParameter('wellslots')[j].amount/amountmod},j-1)
					end
				end
			end
			storage.count = (storage.count or 0) + amount
		end
		else
	end
end

function wellInit()
	if (not storage.wellPos) and object.spaces() then storage.wellPos=vec2.add(poly.center(object.spaces()),object.position()) end
	wellsDrawing=1+#(world.entityQuery(storage.wellPos or entity.position(),wellRange,{includedTypes={"object"},withoutEntityId = entity.id(),callScript="fu_isWell"}) or {})
end

function fu_isWell() return true end

function setDesc()
	if not storage.wellPos then storage.wellPos=vec2.add(poly.center(object.spaces()),object.position()) end
	object.setConfigParameter('description',"^red;Range:^gray; "..wellRange.."\n^red;Wells in range:^gray; "..((wellsDrawing or 0)-1).."^reset;")
end
