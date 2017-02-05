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
	dbg(itemData)
	--itemData={containerID, index}, item, conf,pos
	local source = itemData[1][1];
	if type(source)=="string"then
		source=tonumber(source)
	end
	local sourcePos=itemData[4]
	local slot = itemData[1][2];
	local awake,ping=transferUtil.containerAwake(source,sourcePos)
	if not awake==true then
		return
	else
		if ping~=nil then
			source=ping
		end
		local item = world.containerTakeAt(source, slot - 1);
		if item ~= nil then
			world.spawnItem(item, entity.position())
		end
	end
end

function transferUtil.sendConfig()
	return storage;
end

