function init()
	effect.addStatModifierGroup({
		{stat = "jumpModifier", amount = 0.5}
	})
end

function update(dt)
	mcontroller.controlModifiers({
		airJumpModifier = 1.5
	})
end

function uninit()

end
