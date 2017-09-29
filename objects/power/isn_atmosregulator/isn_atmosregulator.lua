function update(dt)
  if power.consume(config.getParameter('isn_requiredPower')) then
	animator.setAnimationState("switchState", "on")
	isn_effectAllInRange("isn_atmosprotection",500)
  else
	animator.setAnimationState("switchState", "off")
  end
end