function init()
	self.played = false
end

function update(dt)
  if not self.played and mcontroller.crouching() then
    animator.playSound("pandorasboxChuckleCrouchSound")
    self.played = true
  end
  if not mcontroller.crouching() then self.played = false end
end
