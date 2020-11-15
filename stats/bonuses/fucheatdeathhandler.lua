cheatDeathCooldown=7

function update(dt)
	local hp=status.resource("health")
	if hp<1.0 then
		status.addEphemeralEffect("healingpenaltycheatdeath",cheatDeathCooldown)
		hp=((math.random()<hp) and 1) or 0
		status.setResource("health",hp)
		if hp>0 then
			status.addEphemeralEffect("fuindicatorcheatdeath",cheatDeathCooldown)
		end
	end
end
