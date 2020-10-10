
function init()
	if status.isResource("shieldHealth") then
		status.modifyResource("shieldHealth",-status.resource("shieldHealth"))
	end
	if status.isResource("damageAbsorption") then
		status.modifyResource("damageAbsorption",-status.resource("damageAbsorption"))
	end
	if status.isResource("shieldStamina") then
		status.modifyResource("shieldStamina",-status.resource("shieldStamina"))
	end
end