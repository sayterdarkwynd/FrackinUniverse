require "/scripts/kheAA/transferUtil.lua"

function init()
	self=config.getParameter("wellConfig")
	self.timer = math.random(self.timeRange.min or (300),self.timeRange.max or (600)) --spawn interval in seconds
	--old numbers: script update 300 frames (5s) times 600 to 5000: 3000 to 25000 seconds. 50 to 416 minutes.
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() return end

	self.depth = world.oceanLevel(entity.position()) -- current depth in the ocean
	if self.isLiquidBased == 0 then
		if world.liquidAt(entity.position()) or self.depth > 1 then  --cannot work unless out of liquid and above ground
			return
		end
	elseif self.isLiquidBased == 1 then
		local wType=world.type()
		if (wType == "ocean" or wType == "arctic" or wType == "tidewater") and (not world.liquidAt(entity.position()) or self.depth < 50) then --cannot work unless in ocean liquid, and not too deep
			return
		end
	end

	if not scanTimer or scanTimer > 1 then
		wellInit()
		setDesc()
		scanTimer=0
	else
		scanTimer=scanTimer+dt
	end

	if not self.transferUtilTimer or self.transferUtilTimer >= 1 then
		self.transferUtilTimer=0
		transferUtil.loadSelfContainer()
	else
		self.transferUtilTimer=self.transferUtilTimer+dt
	end

	self.timer = self.timer - (dt/math.sqrt(1+wellsDrawing))
	if self.timer <= 0 then
		storage.waterCount = math.min((storage.waterCount or 0) + dt,1200)

		for i=2,#self.wellSlots do
			if world.containerItemAt(entity.id(),i-1) and world.containerItemAt(entity.id(),i-1).name ~= self.wellSlots[i].name then
				world.containerConsumeAt(entity.id(),i-1,world.containerItemAt(entity.id(),i-1).count)
				world.spawnItem(world.containerItemAt(entity.id(),i-1),entity.position())
			end
		end

		local item = world.containerItemAt(entity.id(),0) or {name=self.wellSlots[1].name,count=0}

		if item.name ~= self.wellSlots[1].name then
			world.spawnItem(item,entity.position())
			world.containerConsumeAt(entity.id(),0,item.count)
			item.count = 0
		elseif item.count > self.wellSlots[1].max then
			local dropitem = item
			dropitem.count = dropitem.count - self.wellSlots[1].max
			world.spawnItem(dropitem,entity.position())
			world.containerConsumeAt(entity.id(),0,dropitem.count)
			item.count = self.wellSlots[1].max
			--does extra spawn?
			if self.extraSpawn and self.extraSpawn.chance and self.extraSpawn.spawns then
				if math.random(100) < self.extraSpawn.chance then -- chance a critter spawns
					world.spawnMonster(math.random(#self.extraSpawn.spawns),entity.position())
				end
			end
		end

		local amount = math.min(math.floor(storage.waterCount/self.wellSlots[1].ratio),self.wellSlots[1].max - item.count)
		world.containerPutItemsAt(entity.id(),{name=self.wellSlots[1].name,count=amount},0)
		storage.waterCount = storage.waterCount - amount * self.wellSlots[1].ratio

		if amount > 0 and #self.wellSlots > 1 then
			for i=(storage.count or 0)+1,(storage.count or 0) + amount do
				for j=2,#self.wellSlots do
					amountmod = math.min(math.floor(math.max(self.wellSlots[j].count/self.wellSlots[j].amount,1)),self.wellSlots[j].amount)
					if self.wellSlots[j].chance > 0 and math.fmod(i,self.wellSlots[j].count/amountmod) == 0 and math.random() <= self.wellSlots[j].chance then
						world.containerPutItemsAt(entity.id(),{name=self.wellSlots[j].name,count=self.wellSlots[j].amount/amountmod},j-1)
					end
				end
			end
			storage.count = (storage.count or 0) + amount
		end
		self.timer = math.random(self.timeRange.min or 2500,self.timeRange.max or 30000)  -- randomly reset so rates are never the same or reliable
	end
end

function wellInit()
	local args={
		includedTypes={"object"},
		withoutEntityId = entity.id(),
		callScript="fu_pestTrapType",
		callScriptArgs={self.type or "trap"}
	}
	wellsDrawing=1+#(world.entityQuery(entity.position(),(self.range or 8),args) or {})
end

function fu_pestTrapType(args)
	if args==(self.type or "trap") then return true else return false end
end

function setDesc()
	object.setConfigParameter('description',"^red;Range:^gray; "..(self.range or 8).."\n^red;Similar traps in range:^gray; "..((wellsDrawing or 0)-1).."^reset;")
end

	-- self.randomCheck = math.random(100)
	-- if self.randomCheck == 1 then
	--	self.check2 = math.random(2)
	--	if self.check2 == 1 then
	--		world.spawnMonster("furatthing", entity.position())
	--	else
	--		world.spawnMonster("furatthing2", entity.position())
	--	end
	--elseif self.randomCheck <= 49 then
	--	world.spawnMonster("squeekcritter", entity.position())
	--  elseif self.randomCheck >= 50 then
	--	world.spawnMonster("mousecritter", entity.position())
	--  end