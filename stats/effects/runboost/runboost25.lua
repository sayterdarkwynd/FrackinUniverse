function init()
  local bounds = mcontroller.boundBox()
end

function update(dt)
  mcontroller.controlModifiers({
      runModifier = 1.25
    })
end

function uninit()
  
end