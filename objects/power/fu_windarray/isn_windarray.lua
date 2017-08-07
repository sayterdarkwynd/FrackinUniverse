require '/scripts/power.lua'

function update(dt)
  storage.checkticks = (storage.checkticks or 0) + dt
  if storage.checkticks >= 10 then
	storage.checkticks = 0
	if isn_powerGenerationBlocked() then
	  animator.setAnimationState("windState", "idle")
	else
	  local generated = math.min(math.abs(world.windLevel(isn_getTruePosition())),12)

	  if generated >= 12 then
	    animator.setAnimationState("windState", "active7")
	  elseif generated >= 10 then
	    animator.setAnimationState("windState", "active6")
	  elseif generated >= 8 then
	    animator.setAnimationState("windState", "active5")
	  elseif generated >= 6 then
	    animator.setAnimationState("windState", "active4")
	  elseif generated >= 4 then
	    animator.setAnimationState("windState", "active3")
	  elseif generated >= 2 then
	    animator.setAnimationState("windState", "active2")
	  elseif generated >= 1 then
	    animator.setAnimationState("windState", "active")
	  else
	    animator.setAnimationState("windState", "idle")
	  end
	  power.setPower(generated)
	end
  end
  power.update(dt)
end

function isn_powerGenerationBlocked()
  local location = isn_getTruePosition()
  if world.underground(location) then return true -- it's underground
  elseif world.liquidAt(location) then return true -- it's submerged in liquid
  elseif world.windLevel(location) < 0.2 then return true end -- not enough wind
end

function isn_getTruePosition()
  storage.truepos = storage.truepos or {entity.position()[1] + math.random(2,3), entity.position()[2] + 1}
  return storage.truepos
end