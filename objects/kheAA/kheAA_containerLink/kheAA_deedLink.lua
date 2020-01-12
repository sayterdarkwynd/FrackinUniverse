require "/scripts/kheAA/transferUtil.lua"

function init()
	storage.position=entity.position()
	storage.linkRange=config.getParameter("kheAA_linkRange",32)
end

function update(dt)
	if not object.isInputNodeConnected(0) or object.getInputNodeLevel(0) then
		deltatime = (deltatime or 0) + dt;
		if deltatime < 1 then
			return;
		end
		deltatime=0
		object.setOutputNodeLevel(0,false)
		scan()
		object.setOutputNodeLevel(0,true)
	else
		deltatime=0
	end
end

function scan()
	transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))

	local objectIds = world.objectQuery(storage.position, storage.linkRange, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		if world.getObjectParameter(objectId,"deed") then
			if world.callScriptedEntity(objectId,"isOccupied") then
				if world.callScriptedEntity(objectId,"isRentDue") then
					local args={sourceId=entity.id()}
					world.callScriptedEntity(objectId,"onInteraction",args)
				end
			end
		end
	end
end
