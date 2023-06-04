function init()
  animator.setParticleEmitterOffsetRegion("iceslip", mcontroller.boundBox())
  animator.setParticleEmitterActive("iceslip", true)
end

function update(dt)
  mcontroller.controlParameters({
        normalGroundFriction = config.getParameter("groundFriction",0),
        groundForce = config.getParameter("groundForce",0),
        slopeSlidingFactor = config.getParameter("slopeSlide",0)
    })
end

function uninit()

end