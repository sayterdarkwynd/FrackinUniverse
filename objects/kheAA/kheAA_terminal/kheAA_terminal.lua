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

function transferItem(_, _, itemData)
	--itemData={containerID, index}, item, conf,posRect
	local source = itemData[1][1];
	local sourceRect=itemData[4]
	local slot = itemData[1][2];
	if not transferUtil.zoneAwake(sourceRect) then return end
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

