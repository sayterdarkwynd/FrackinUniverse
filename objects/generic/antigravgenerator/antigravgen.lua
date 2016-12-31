function init(virtual)
	if virtual == true then return end
end

function update(dt)
	--isn_projectileAllInRange("antigravgenprojectile",75)
        local active = 1
	physics.setForceEnabled("jumpForce", active)		
end