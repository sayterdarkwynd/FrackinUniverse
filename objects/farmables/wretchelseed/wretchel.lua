function init(virtual)
	if virtual == true then return end
end

function update(dt)
	--isn_projectileAllInRange("gravgenprojectile",100)
        local active = 1
	physics.setForceEnabled("jumpForce", active)	
	
end