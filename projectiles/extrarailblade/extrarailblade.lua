require "/scripts/rails.lua"

function init()
  local railConfig = config.getParameter("railConfig", {})
  railConfig.speed = config.getParameter("speed")

  self.railRider = Rails.createRider(railConfig)
  self.railRider:init()
end

function update(dt)
  self.railRider:update(dt)
end

function uninit()
  self.railRider:uninit()
end
