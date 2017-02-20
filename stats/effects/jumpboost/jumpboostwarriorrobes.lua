function init()
  local bounds = mcontroller.boundBox()
end

function update(dt)
  mcontroller.controlModifiers({
      airJumpModifier = 1.25,
      speedModifier = 1.25
    })
end

function uninit()
  
end
