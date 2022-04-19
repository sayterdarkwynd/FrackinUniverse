function init()
  self.chatOptions = config.getParameter("chatOptions", {})
  self.chatTimer = 0
end

function update(dt)
  self.chatTimer = math.max(0, self.chatTimer - dt)
  if self.chatTimer == 0 then
    local players = world.entityQuery(object.position(), config.getParameter("chatRadius"), {
      includedTypes = {"player"},
      boundMode = "CollisionArea"
    })

    if #players > 0 and #self.chatOptions > 0 then
      object.say(self.chatOptions[math.random(1, #self.chatOptions)])
      self.chatTimer = config.getParameter("chatCooldown")
    end
  end
end