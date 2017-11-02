function init()

end

function update(dt)
  mcontroller.controlModifiers({
      airJumpModifier = 0.3,
      speedModifier = 0.1
    })
  if mcontroller.yVelocity() < 0 then
      mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), -1))
    end
  if effect.duration() < 0.3 then
    if world.material({mcontroller.position()[1],mcontroller.position()[2] - 1.5}, "foreground") == "spidersilkblockmik" then
      effect.modifyDuration(0.1)
	elseif world.material({mcontroller.position()[1],mcontroller.position()[2] - 2.5}, "foreground") == "spidersilkblockmik" then
      effect.modifyDuration(0.1)
	end
  end
    
end

function uninit()

end