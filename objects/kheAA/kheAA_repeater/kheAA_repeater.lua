require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	storage.inContainers={}
	storage.outContainers={}
end

function update(dt)
	deltatime=(deltatime or 0)+dt
	if deltatime < 1 then
		return
	end
	deltatime=0
	transferUtil.updateInputs();
	transferUtil.updateOutputs();
	object.setOutputNodeLevel(storage.inDataNode,util.tableSize(storage.outContainers))
end
