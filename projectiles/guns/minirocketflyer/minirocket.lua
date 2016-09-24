require "/scripts/vec2.lua"

function init()
  self.approach = vec2.norm(mcontroller.velocity())

  self.maxSpeed = config.getParameter("maxSpeed")
  self.controlForce = config.getParameter("controlForce")

end

function update(dt)
  mcontroller.approachVelocity(vec2.mul(self.approach, self.maxSpeed), self.controlForce)
end

function setApproach(approach)
  self.approach = approach
end
