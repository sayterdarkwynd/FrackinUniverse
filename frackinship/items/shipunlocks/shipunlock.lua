require "/scripts/vec2.lua"

function init()
  self.recoil = 0
  self.recoilRate = 0

  self.fireOffset = config.getParameter("fireOffset")
  updateAim()

  self.active = false
  storage.fireTimer = storage.fireTimer or 0

  self.miscShipConfig = root.assetJson("/frackinship/configs/misc.config")
  self.universeFlag = config.getParameter("universeFlag")
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  storage.fireTimer = math.max(storage.fireTimer - dt, 0)

  if self.active then
    self.recoilRate = 0
  else
    self.recoilRate = math.max(1, self.recoilRate + (10 * dt))
  end
  self.recoil = math.max(self.recoil - dt * self.recoilRate, 0)

  if self.active and not storage.firing and storage.fireTimer <= 0 then
    self.recoil = math.pi/2 - self.aimAngle
    activeItem.setArmAngle(math.pi/2)
    if animator.animationState("firing") == "off" then
      animator.setAnimationState("firing", "fire")
    end
    storage.fireTimer = config.getParameter("fireTime", 1.0)
    storage.firing = true

  end

  self.active = false

  if storage.firing and animator.animationState("firing") == "off" and self.unlockCheck:finished() then
    if self.unlockCheck:succeeded() then
	  local results = self.unlockCheck:result()
	  if results.disableUnlockableShips then
	    player.interact("ShowPopup", {message = self.miscShipConfig.shipUnlockMessages.disabled or ""})
	  elseif results.unlocked then
	    player.interact("ShowPopup", {message = self.miscShipConfig.shipUnlockMessages.alreadySet or ""})
	  else
	    player.setUniverseFlag(self.universeFlag)
	    player.interact("ShowPopup", {message = self.miscShipConfig.shipUnlockMessages.success or ""})
	    item.consume(1)
	    return
	  end
	end
	storage.firing = false
  end
end

function activate(fireMode, shiftHeld)
  if not storage.firing then
	if world.type() ~= "unknown" then
		player.interact("ShowPopup", {message = self.miscShipConfig.shipUnlockMessages.notOnShip or ""})
	else
		self.active = true
		self.unlockCheck = world.sendEntityMessage("frackinshiphandler", "checkUnlockableShipUnlocked", self.universeFlag)
	end
  end
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  self.aimAngle = self.aimAngle + self.recoil
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

function holdingItem()
  return true
end

function recoil()
  return false
end

function outsideOfHand()
  return false
end
