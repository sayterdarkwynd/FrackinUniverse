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

  object.setInteractive(config.getParameter("interactive", true))
  object.setAllOutputNodes(false)
  animator.setAnimationState("switchState", "off")
  self.triggerTimer = 0
end

function trigger()
  object.setAllOutputNodes(true)
  animator.setAnimationState("switchState", "on")
  object.setSoundEffectEnabled(true)
  self.triggerTimer = config.getParameter("detectDuration")
end

function onInteraction(args)
  trigger()
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

    if self.detectDamageTeam then
      entityIds = util.filter(entityIds, function (entityId)
          local entityDamageTeam = world.entityDamageTeam(entityId)
          if self.detectDamageTeam.type and self.detectDamageTeam.type ~= entityDamageTeam.type then
            return false
          end
          if self.detectDamageTeam.team and self.detectDamageTeam.team ~= entityDamageTeam.team then
            return false
          end
          return true
        end)
    end

    if #entityIds > 0 then
              hostile = 0
        for i in pairs(entityIds) do
            if world.entityAggressive(entityIds[i]) == false then
                hostile = -1
                i = #entityIds
            else
                hostile = 1
            end
        end

        if hostile ~= 1 then
            trigger()
        end
    else
      object.setAllOutputNodes(false)
      object.setSoundEffectEnabled(false)
      animator.setAnimationState("switchState", "off")
    end
  end
end
