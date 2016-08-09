
function init()
    effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
    local bounds = mcontroller.boundBox()
end
 
function update()
    if mcontroller.falling() then
      mcontroller.controlParameters(config.getParameter("fallingParameters"))
      mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), config.getParameter("maxFallSpeed")))
    end
		mcontroller.controlModifiers({
				airJumpModifier = 1.45,
				jumpHoldTime = 1.0
			})

end
 
function unit()

end
