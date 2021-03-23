function init()
  self.detectArea = config.getParameter("detectArea")
  self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
  self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])
  self.containsPlayers = {}
  object.setInteractive(true)
  self.chatIndex = 0
end

function update(dt)
  local newPlayers = world.entityQuery(self.detectArea[1], self.detectArea[2], {
      includedTypes = {"player"},
      boundMode = "CollisionArea"
    })
  local oldPlayers = table.concat(self.containsPlayers, ",")
  for _, id in pairs(newPlayers) do
    if not string.find(oldPlayers, id) then
      animator.setAnimationState("boothState", "wave")
      break
    end
  end
  self.containsPlayers = newPlayers
end

function onInteraction(args)
  local chatOptions = config.getParameter("chatOptions", {})
  object.say(chatOptions[(self.chatIndex % #chatOptions) + 1])
  self.chatIndex = self.chatIndex + 1
  animator.playSound("chatter")
end
