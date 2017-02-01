require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	message.setHandler("transferUtil.sendConfig",transferUtil.sendConfig);
	message.setHandler("transferItem", transferItem);
	object.setInteractive(true);
	inDataNode=0
end

function update()
	transferUtil.updateInputs(inDataNode)
end

function transferItem(_, _, location)
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

