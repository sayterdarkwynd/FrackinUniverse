require "/scripts/rails.lua"
require "/scripts/vec2.lua"

function init()
  message.setHandler("positionTileDamaged", function()
      if not world.isTileProtected(mcontroller.position()) then
        popVehicle()
      end
    end)

  mcontroller.setRotation(0)

  local railConfig = config.getParameter("railConfig", {})
  railConfig.facing = config.getParameter("initialFacing", 1)

  self.railRider = Rails.createRider(railConfig)
  self.railRider:init(storage.railStateData)

  vehicle.setInteractive(false)
end

function update(dt)
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
    return
  end

  if mcontroller.isColliding() then
    popVehicle()
  else
    self.railRider:update(dt)
    storage.railStateData = self.railRider:stateData()
  end

  if self.railRider.onRailType and self.railRider.moving then
    animator.setAnimationState("rail", "on")
  else
    animator.setAnimationState("rail", "off")
  end

end

function uninit()
  self.railRider:uninit()
end

function popVehicle()
  local popItem = config.getParameter("popItem")
  if popItem then
    world.spawnItem(popItem, entity.position(), 1)
  end
  vehicle.destroy()
end
