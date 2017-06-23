function init()
		if storage.init==nil then
			storage.init=true
			storage.state=true
		end
end

function update(dt)
	if object.isInputNodeConnected(0) then
		storage.state=object.getInputNodeLevel(0)
	else
		storage.state=true
	end
	if storage.state then
		--isn_projectileAllInRangeParams("fu_genericBlankProjectile",30,{statusEffects={"isn_atmosprotection"}})
		isn_effectAllInRange("gravgenfield",30)
	end
	--physics.setForceEnabled("jumpForce", storage.state)		
end