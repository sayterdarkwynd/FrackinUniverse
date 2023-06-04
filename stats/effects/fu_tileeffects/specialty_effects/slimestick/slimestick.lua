function init()

end

function update(dt)
  mcontroller.controlParameters({
        normalGroundFriction = 5,
        groundForce = 50,
        bounceFactor = 0.55
    })
end

function uninit()

end