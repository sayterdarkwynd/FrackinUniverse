function init()
  local bounds = mcontroller.boundBox()
end

function update(dt)
  mcontroller.controlModifiers({
      runModifier = 0.70,
      speedModifier = 0.70
    })
end

function uninit()
  
end