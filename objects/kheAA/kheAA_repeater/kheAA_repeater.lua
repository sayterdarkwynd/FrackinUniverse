require "/scripts/kheAA/transferUtil.lua"
local deltatime=0
storage={}

function init()
	transferUtil.init()
	storage.inContainers={}
	storage.outContainers={}
	inDataNode=0
	outDataNode=0
end

function update(dt)
	deltatime=deltatime+dt
	if deltatime < 1 then
		return
	end
	deltatime=0
	transferUtil.updateInputs(inDataNode);
	transferUtil.updateOutputs(outDataNode);
	object.setOutputNodeLevel(outDataNode,util.tableSize(storage.outContainers))
end
