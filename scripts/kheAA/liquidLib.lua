liquidLib = {}

function liquidLib.initIDs()
	liquidLib.liquidIds={}
	liquidLib.liquidIds[100]="liquidaether";
	liquidLib.liquidIds[70]="liquidorangegravrain";
	liquidLib.liquidIds[69]="liquidwastewater";
	liquidLib.liquidIds[68]="liquidmetallichydrogen";
	liquidLib.liquidIds[67]="liquiddeuterium";
	liquidLib.liquidIds[66]="fu_hydrogenmetallic";
	liquidLib.liquidIds[65]="sand";
	liquidLib.liquidIds[64]="liquidbioooze";
	liquidLib.liquidIds[63]="fu_nitrogen";
	liquidLib.liquidIds[62]="fu_hydrogen";
	liquidLib.liquidIds[61]="liquidbeer";
	liquidLib.liquidIds[60]="liquiddarkwater";
	liquidLib.liquidIds[59]="liquidcrystal";
	liquidLib.liquidIds[58]="liquidwastewater";
	liquidLib.liquidIds[57]="fu_liquidhoney";
	liquidLib.liquidIds[56]="liquidnitrogenitem";
	liquidLib.liquidIds[55]="liquidalienjuice";
	liquidLib.liquidIds[54]="fu_liquidhoney";
	liquidLib.liquidIds[53]="liquidpus";
	liquidLib.liquidIds[52]="liquidironfu";
	liquidLib.liquidIds[51]="liquidgravrain";
	liquidLib.liquidIds[50]="shadowgasliquid";
	liquidLib.liquidIds[49]="helium3gasliquid";
	liquidLib.liquidIds[48]="ff_mercury";
	liquidLib.liquidIds[47]="liquidirradium";
	liquidLib.liquidIds[46]="liquidsulphuricacid";
	liquidLib.liquidIds[45]="liquidelderfluid";
	liquidLib.liquidIds[44]="vialproto";
	liquidLib.liquidIds[43]="liquidorganicsoup";
	liquidLib.liquidIds[42]="liquidblacktar";
	liquidLib.liquidIds[41]="liquidbioooze";
	liquidLib.liquidIds[40]="liquidblood";
	liquidLib.liquidIds[13]="liquidslime";
	liquidLib.liquidIds[12]="swampwater";
	liquidLib.liquidIds[11]="liquidfuel";
	liquidLib.liquidIds[9]="liquidcoffee";
	liquidLib.liquidIds[7]="liquidmilk";
	liquidLib.liquidIds[6]="liquidhealing";
	liquidLib.liquidIds[5]="liquidoil";
	liquidLib.liquidIds[4]="liquidalienjuice";
	liquidLib.liquidIds[3]="liquidpoison";
	liquidLib.liquidIds[2]="liquidlava";
	liquidLib.liquidIds[1]="liquidwater";
end

function liquidLib.init()
	if storage.liquids == nil then
		storage.liquids = {};
	end
	if storage.liquidOuts == nil then
		storage.liquidOuts = {};
	end
	storage.liquidInNode = config.getParameter("kheAA_liquidInNode")
	storage.liquidOutNode = config.getParameter("kheAA_liquidOutNode")
	if (root.liquidConfig) then
		storage.canConfig=true
	else
		liquidLib.initIDs()
	end
end

function liquidLib.itemToLiquidId(item)
	--if storage.canConfig then
		
	--else
		for i,v in pairs(liquidLib.liquidIds) do
			if item.name==v then
				return i
			end 
		end
	--end
	return nil
end

function liquidLib.itemToLiquidLevel(itemDescriptor)
	--if storage.canConfig then
		
	--else
		for i,v in pairs(liquidLib.liquidIds) do
			if itemDescriptor.name==v then
				return {i,itemDescriptor.count}
			end 
		end
	--end
	return nil
end

function liquidLib.liquidLevelToItem(liqLvl)
	return liquidLib.liquidToItem(liqLvl[1],liqLvl[2])
end

function liquidLib.liquidToItem(liquidId,level)
	--if storage.canConfig then
		
	--else
		if(liquidLib.liquidIds[liquidId]~=nil) then
			if(level~=nil) then
				return {name=liquidLib.liquidIds[liquidId],count=level,parameters={}}
			else
				return {name=liquidLib.liquidIds[liquidId],count=1,parameters={}}
			end
		end
	--end
	return nil
end

function liquidLib.canReceiveLiquid()
	if receiveLiquid==true then
		return true
	end
	return nil
end

function liquidLib.receiveLiquid(liquid)
	if not storage.liquids then storage.liquids={} end
	storage.liquids[liquid[1]]=(storage.liquids[liquid[1]] or 0)+liquid[2]
end



function liquidLib.doPump()
	if not transferUtil.powerLevel(powerNode) then
		return;
	end
	local pos = entity.position();
	local liquid = world.liquidAt(pos);
	if liquid == nil then
		for i,v in pairs(storage.liquids) do
			if v > 0 then
				local spawned = world.spawnLiquid(pos, i, math.min(1, v));
				if spawned then
					storage.liquids[i] = v - math.min(1, v);
					break;
				end
			end
		end
	elseif (storage.liquids[liquid[1]] ~= nil) and (storage.liquids[liquid[1]]>0) then
		if (liquid[2] < 1) and (storage.liquids[liquid[1]] > -1) then
			local spawned = world.spawnLiquid(pos, liquid[1], 1 - liquid[2]);
			if spawned then
				storage.liquids[liquid[1]] = storage.liquids[liquid[1]] - (1 - liquid[2]);
			end
		end
	end
	
	local items = world.containerItems(entity.id());
	
	if items ~= nil then
		for slot,item in pairs(items) do
			if liquidLib.tryConsumeLiqitem(items[1]) then break end
		end
	end

end

function liquidLib.tryConsumeLiqitem(item)
	local liquidId = liquidLib.itemToLiquidId(item)
	if liquidId == nil then
		return false;
	end
	if storage.liquids[liquidId] == nil then
		storage.liquids[liquidId] = 0;
	end
	if storage.liquids[liquidId] < 1 then
		item.count = 1;
		local consumed = world.containerConsume(entity.id(), item);
		if consumed then
			storage.liquids[liquidId] = storage.liquids[liquidId] + 1;
		end
	else
		return false
	end
	return true
end

function liquidLib.update(dt)
	storage.liquidOuts={}
	local tempList=object.getOutputNodeIds(outLiquidNode)
	if tempList then
		for id,node in pairs(tempList) do
			local result=world.callScriptedEntity(id,"liquidLib.canReceiveLiquid")
			if result then
				storage.liquidOuts[id]=world.entityPosition(id)
			end
		end
	end
end


function liquidLib.die()
	if storage.liquids then
		for id,count in pairs(storage.liquids) do
			local liquid=liquidLib.liquidToItem(id,count)
			if liquid then
				world.spawnItem(liquid,entity.position())
			else
				world.spawnLiquid(entity.position(),id,count)
			end
		end
	end
end
