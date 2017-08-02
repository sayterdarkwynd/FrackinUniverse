function init()
	
end

function update(dt)
  if power.consume(config.getParameter('isn_requiredPower')) then
	animator.setAnimationState("switchState", "off")
  else
	animator.setAnimationState("switchState", "on")
    isn_effectAllInRange("isn_atmosregen",500)
    --isn_projectileAllInRange("isn_atmosregen",500)
  end
end