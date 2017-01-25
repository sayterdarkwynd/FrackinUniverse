require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	message.setHandler("transferUtil.sendConfig",transferUtil.sendConfig);
	message.setHandler("transferItem", transferItem);
	object.setInteractive(true);
end

function update()
	if transferUtil.updateInputs(0) then
		for k,v in pairs(storage.input) do
			result=world.callScriptedEntity(k,"transferUtil.sendContainerInputs");
			if(result~=nil)then
				storage.containers=transferUtil.tConjunct(storage.containers,result)			
			end
		end
	end
end

function transferItem(a, b, location)
	local source = location[1];
	local slot = location[2];
	if world.entityExists(source) then
		local item = world.containerTakeAt(source, slot - 1);
		if item ~= nil then
			world.spawnItem(item, entity.position())
		end
	end

end

function transferUtil.sendConfig()
	return storage;
end

