require "/scripts/kheAA/transferUtil.lua"

function init()
  transferUtil.init()
	  self.isLiquidBased = config.getParameter("isLiquidBased",0) -- can this generate creatures in water? default 0
	  self.timer = math.random(600,5000) --hard time cap
	  self.randomCheck = math.random(100) -- rat spawn chance
end

function update(dt)
	  self.depth = world.oceanLevel(entity.position()) -- current depth in the ocean
	  if self.isLiquidBased == 0 then
		  if world.liquidAt(entity.position()) or self.depth > 1 then  --cannot work unless out of liquid and above ground
		    return 
		  end
	  elseif self.isLiquidBased == 1 then
	  	if world.type() == "ocean" or world.type() == "arctic" or world.type() == "tidewater" then
		  if not world.liquidAt(entity.position()) or self.depth < 50 then  --cannot work unless in ocean liquid, and not too deep
		    return 
		  end   		  		
	  	end  	  	
	  end	 

	  self.timer = self.timer - 1
	  if self.timer <= 0 then
		  transferUtil.loadSelfContainer()
		  storage.waterCount = math.min((storage.waterCount or 0) + dt,1200)
		  
		  for i=2,#config.getParameter('wellslots') do
		    if world.containerItemAt(entity.id(),i-1) and world.containerItemAt(entity.id(),i-1).name ~= config.getParameter('wellslots')[i].name then
		      world.containerConsumeAt(entity.id(),i-1,world.containerItemAt(entity.id(),i-1).count)
		      world.spawnItem(world.containerItemAt(entity.id(),i-1),entity.position())
		    end
		  end
		  
		  local item = world.containerItemAt(entity.id(),0) or {name=config.getParameter('wellslots')[1].name,count=0}
		  
		  if item.name ~= config.getParameter('wellslots')[1].name then
		    world.spawnItem(item,entity.position())
		    world.containerConsumeAt(entity.id(),0,item.count)
		    item.count = 0
		  elseif item.count > config.getParameter('wellslots')[1].max then
		    local dropitem = item
		    dropitem.count = dropitem.count - config.getParameter('wellslots')[1].max
		    world.spawnItem(dropitem,entity.position())
		    world.containerConsumeAt(entity.id(),0,dropitem.count)
		    item.count = config.getParameter('wellslots')[1].max
            --does a rat spawn?
			if self.randomCheck == 1 then
				world.spawnMonster("squeekcritter", entity.position())
			elseif self.randomCheck == 2 then
				world.spawnMonster("mousecritter", entity.position())
			end		    
		  end
		  
		  local amount = math.min(math.floor(storage.waterCount/config.getParameter('wellslots')[1].ratio),config.getParameter('wellslots')[1].max - item.count)
		  world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[1].name,count=amount},0)
		  storage.waterCount = storage.waterCount - amount * config.getParameter('wellslots')[1].ratio
		  
		  if amount > 0 and #config.getParameter('wellslots') > 1 then
		    for i=(storage.count or 0)+1,(storage.count or 0) + amount do
		      for j=2,#config.getParameter('wellslots') do
			amountmod = math.min(math.floor(math.max(config.getParameter('wellslots')[j].count/config.getParameter('wellslots')[j].amount,1)),config.getParameter('wellslots')[j].amount)
			if config.getParameter('wellslots')[j].chance > 0 and math.fmod(i,config.getParameter('wellslots')[j].count/amountmod) == 0 and math.random() <= config.getParameter('wellslots')[j].chance then
			  world.containerPutItemsAt(entity.id(),{name=config.getParameter('wellslots')[j].name,count=config.getParameter('wellslots')[j].amount/amountmod},j-1)
			end
		      end
		    end
		    storage.count = (storage.count or 0) + amount
		  end	  
	  	self.timer = math.random(600,5000)  -- randomly reset so rates are never the same or reliable
	  end


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