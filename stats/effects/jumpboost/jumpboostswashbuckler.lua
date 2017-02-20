function init()
  local bounds = mcontroller.boundBox()
end

function update(dt)
  mcontroller.controlModifiers({
      airJumpModifier = 1.08
    })
end

function uninit()
  
end
