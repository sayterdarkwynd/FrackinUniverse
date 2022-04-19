function init()
	local rAmt=config.getParameter("bonusAmount", 0)
	effect.addStatModifierGroup({
		{stat = "isXi", amount = rAmt}
	})
end

function update(dt)

end

function uninit()

end
