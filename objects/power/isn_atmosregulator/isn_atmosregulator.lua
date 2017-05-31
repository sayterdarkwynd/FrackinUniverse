require "/objects/power/isn_sharedpowerscripts.lua"
require "/objects/isn_sharedobjectscripts.lua"

function init()
	isn_powerInit()
end

function update(dt)
	storage.active=false
	if storage.powerInNode and storage.logicInNode then
		if (not object.isInputNodeConnected(storage.logicInNode)) or object.getInputNodeLevel(storage.logicInNode) then
			if isn_hasRequiredPower() then
				storage.active=true
			end
		end
	end
	if not storage.active then
		animator.setAnimationState("switchState", "off")
		return
	end
	animator.setAnimationState("switchState", "on")
	
	--isn_projectileAllInRange("isn_atmosprojectile",500)
	isn_effectAllInRange("isn_atmosprotection",500)
end