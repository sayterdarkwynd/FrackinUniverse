function init()
  baseValue = config.getParameter("healthBonus",0)
  baseValue2 = config.getParameter("jumpBonus",0)

  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(5)


end

function update(dt)
	mcontroller.controlModifiers({
			speedModifier = 1.1,
			airJumpModifier = 1.05
		})	
end

function uninit()
  
end