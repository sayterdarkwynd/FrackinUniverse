function init()

end

function update(dt)
  mcontroller.controlParameters({
        normalGroundFriction = 4,
        groundForce = 40,
        slopeSlidingFactor = 0.1,
        bounceFactor = 0.25
    })
end

function uninit()

end