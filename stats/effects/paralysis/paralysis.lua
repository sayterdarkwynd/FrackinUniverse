function init()
	stun()
end

function update(dt)
	stun()
end

function uninit()

end

function stun()
	if status.isResource("stunned") then
		if status.resourcePositive("health") then
			status.setResource("stunned",effect.duration())
			mcontroller.controlModifiers({
				facingSuppressed = true,
				movementSuppressed = true
			})
		else
			status.setResource("stunned",0)
			effect.expire()
		end
	else
		effect.expire()
	end
end