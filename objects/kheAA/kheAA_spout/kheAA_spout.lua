require "/scripts/kheAA/liquidLib.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;

function init()
	transferUtil.init()
	if storage.liquids == nil then
		storage.liquids = {};
	end
end

function update(dt)
	deltatime = deltatime + dt;
	if deltatime < 0.05 then
		return
	end
	deltatime = 0;	
		if not transferUtil.powerLevel(0) then
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
						return;
					end
				end
			end
		elseif storage.liquids[liquid[1]] ~= nil and storage.liquids[liquid[1]] then
			if liquid[2] < 1 then
				local spawned = world.spawnLiquid(pos, liquid[1], 1 - liquid[2]);
				if spawned then
					storage.liquids[liquid[1]] = storage.liquids[liquid[1]] - (1 - liquid[2]);
					return;
				end
			end
		end

	
		local items = world.containerItems(entity.id());
		
		if items[1] ~= nil then
			tryConsumeLiquid(items[1]);
		end
		
	
end

function tryConsumeLiquid(item)
	local liquidId = -1;
	for i,v in pairs(liquidLib.liquidIds) do
		if v == item.name then
			liquidId = i;
		end
	end
	if liquidId == -1 then
		return;
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
	end
end