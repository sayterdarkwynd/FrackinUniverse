require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.loadSelfContainer()
end

function update(dt)

	if not deltatime or deltatime>1.0 then
		transferUtil.loadSelfContainer()
		if not object.isInputNodeConnected(transferUtil.vars.logicNode) or object.getInputNodeLevel(transferUtil.vars.logicNode) then
			local items=world.containerTakeAll(entity.id())
			for _,item in pairs(items) do
				world.spawnItem(item,storage.position)
			end
		end
	else
		deltatime=deltatime+dt
	end
end