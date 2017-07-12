require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.idleArmAngle = config.getParameter("idleArmAngle", -1.25)
  self.idleBrushAngle = config.getParameter("idleBrushAngle", -0.2)

  self.sweepSpeed = config.getParameter("sweepSpeed", 0.15)
  self.sweepArmAngle = config.getParameter("sweepArmAngle", {0.1, 0.2})
  self.sweepBrushAngle = config.getParameter("sweepBrushAngle", {-1.6, -1.45})

  self.targetOffset = config.getParameter("targetOffset", {1.325, 0.0})
  self.minOnFossilTime = config.getParameter("minOnFossilTime", 0.5)
  self.onFossilTime = 0

  self.gameOpen = false
  message.setHandler("fossilGameClosed", function(...)
      self.gameOpen = false
      idle()
    end)

  idle()
end

function activate(fireMode, shiftHeld)
  self.active = true
end

function update(dt, fireMode, shiftHeld)
  if not self.gameOpen then
    self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
    activeItem.setFacingDirection(self.aimDirection)
  end

  if self.active then
    if fireMode == "primary" or self.gameOpen then
      self.activeTime = self.activeTime + dt

      local armRatio = math.sin(self.activeTime * math.pi / self.sweepSpeed)
      activeItem.setArmAngle(self.aimAngle + util.lerp(armRatio, self.sweepArmAngle))

      local brushRatio = math.sin((self.activeTime - self.sweepSpeed * 0.25) * math.pi / self.sweepSpeed)
      animator.resetTransformationGroup("brush")
      animator.rotateTransformationGroup("brush", util.lerp(brushRatio, self.sweepBrushAngle))

      if self.gameOpen then
        self.onFossilTime = 0
        animator.setAnimationState("brush", "onFossil")
      else
        local onFossilId = onFossil()
        if onFossilId then
          self.onFossilTime = self.onFossilTime + dt

          if self.onFossilTime >= self.minOnFossilTime then
            if not world.getObjectParameter(onFossilId, "inUse") then
              local configData = root.assetJson("/interface/games/fossilgame/fossilgamegui.config")
              configData.ownerId = activeItem.ownerEntityId()
              configData.toolType = config.getParameter("toolType")
              activeItem.interact("ScriptPane", configData, onFossilId)

              item.consume(1)

              if item.count() > 0 then
                self.gameOpen = true
              end
            end
          end

          animator.setAnimationState("brush", "onFossil")
        else
          self.onFossilTime = 0
          animator.setAnimationState("brush", "idle")
        end
      end
    else
      idle()
    end
  end
end

function uninit()

end

function idle()
  self.active = false
  self.activeTime = 0
  self.onFossilTime = 0
  activeItem.setArmAngle(self.idleArmAngle)
  animator.resetTransformationGroup("brush")
  animator.rotateTransformationGroup("brush", self.idleBrushAngle)
  animator.setAnimationState("brush", "idle")
end

function onFossil()
  local targetPos = vec2.add(mcontroller.position(), activeItem.handPosition(self.targetOffset))
  local objectId = world.objectAt(targetPos)
  if objectId and root.itemHasTag(world.entityName(objectId), "dirtyfossil") then
    return objectId
  end
  return false
end
