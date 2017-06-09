require "/objects/power/isn_sharedpowerscripts.lua"
require "/objects/isn_sharedobjectscripts.lua"

function init()
	storage.active = storage.active or false
	isn_powerInit()
end

function isn_getCurrentPowerOutput()
	if storage.active then
		return isn_getCurrentPowerInput(storage.powerInNode)
	end
	return 0
end

function nodeStuff()
	storage.active=false
	if storage.logicInNode and storage.powerOutNode then
		if (not object.isInputNodeConnected(storage.logicInNode)) or object.getInputNodeLevel(storage.logicInNode) then
			if isn_checkValidOutput(storage.powerOutNode) then
				if isn_getCurrentPowerInput()>0 then
					storage.active=true
				end
			end
		end
	end
	animator.setAnimationState("switchState",(storage.active and "on") or "off")
	if storage.logicOutNode then
		object.setOutputNodeLevel(storage.logicOutNode, storage.active)
	end
end

function onNodeConnectionChange()
	nodeStuff()
end

function onInputNodeChange()
	nodeStuff()
end

function update(dt)
	nodeStuff()
end