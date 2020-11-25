require "/scripts/vec2.lua"
require "/scripts/util.lua"


function init()

  self.detectEntityTypes = config.getParameter("detectEntityTypes")
  self.detectBoundMode = config.getParameter("detectBoundMode", "CollisionArea")
  self.detectDamageTeam = config.getParameter("detectDamageTeam")
  local detectArea = config.getParameter("detectArea")
  local pos = object.position()
  if type(detectArea[2]) == "number" then
    --center and radius
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      detectArea[2]
    }
  elseif type(detectArea[2]) == "table" and #detectArea[2] == 2 then
    --rect corner1 and corner2
    self.detectArea = {
      {pos[1] + detectArea[1][1], pos[2] + detectArea[1][2]},
      {pos[1] + detectArea[2][1], pos[2] + detectArea[2][2]}
    }
  end
  self.timer = 3
  self.triggerTimer = 0
  script.setUpdateDelta(5)
end



function update(dt)

  if self.triggerTimer > 0 then
    self.triggerTimer = self.triggerTimer - dt
  elseif self.triggerTimer <= 0 then
    local entityIds = world.entityQuery(self.detectArea[1], self.detectArea[2], {
        withoutEntityId = entity.id(),
        includedTypes = self.detectEntityTypes,
        boundMode = self.detectBoundMode
      })

    if #entityIds < 1 then
      if self.timer > 0 then
        self.timer = self.timer -dt
      else
        object.smash(true)
      end
    end

  end
end

function uninit()

end
