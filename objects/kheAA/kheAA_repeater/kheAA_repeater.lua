require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}
end

function update(dt)
	deltatime=(deltatime or 0)+dt
	if deltatime < 1 then
		return
	end
	deltatime=0
	transferUtil.updateInputs()
	transferUtil.updateOutputs()
	object.setOutputNodeLevel(transferUtil.vars.inDataNode,util.tableSize(transferUtil.vars.outContainers))
end
