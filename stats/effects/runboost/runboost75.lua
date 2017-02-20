function init()
  local bounds = mcontroller.boundBox()
end

function update(dt)
  mcontroller.controlModifiers({
      speedModifier = 1.75
    })
end

function uninit()
  
end