require '/scripts/power.lua'

function update(dt)
  if power.consume(config.getParameter('isn_requiredPower')) then
    animator.setAnimationState("switchState", "on")
    isn_effectAllInRange("isn_atmosregen",500)
  else
	animator.setAnimationState("switchState", "off")
    --isn_projectileAllInRange("isn_atmosregen",500)
  end
end