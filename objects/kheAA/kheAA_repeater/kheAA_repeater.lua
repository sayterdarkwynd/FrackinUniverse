require "/scripts/kheAA/transferUtil.lua"
local deltatime=0
storage={}

function init()
	transferUtil.init()
	onInputNodeChange()
	update(999)
end

function update(dt)
	deltatime=deltatime+dt
	if deltatime < 1 then
		return
	end
	local temp=transferUtil.updateInputs(1);
	transferUtil.updateOutputs(0);
	object.setOutputNodeLevel(0,temp)
	deltatime=0
end
