function init()
	self.played = false
end

function update(dt)
  if not self.played and mcontroller.jumping() then
    animator.playSound("pandorasboxPenguinJumpSound")
    self.played = true
  end
  if mcontroller.onGround() then self.played = false end
end
