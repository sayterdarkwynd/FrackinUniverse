function init()
  self.detectArea = config.getParameter("detectArea")
  self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
  self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])
  self.containsPlayers = {}
  object.setInteractive(true)
  self.chatIndex = 0
  self.chatTimer = -1
  self.chatOptions = config.getParameter("chatOptions", {})
end

function update(dt)
  local newPlayers = world.entityQuery(self.detectArea[1], self.detectArea[2], { includedTypes = {"player"},boundMode = "CollisionArea"} )
  local oldPlayers = table.concat(self.containsPlayers, ",")
  for _, id in pairs(newPlayers) do
    if not string.find(oldPlayers, id) then
      animator.setAnimationState("boothState", "wave")
      break
    end
  end
  self.containsPlayers = newPlayers
  
  
  if self.chatTimer == 0 and self.chatIndex ~= 0  then
  chatOptions = config.getParameter("chatOptions", {})
	object.say(chatOptions[(self.chatIndex % #chatOptions)])
	--animator.playSound("chatter")
	self.chatTimer = self.chatTimer - 1
	else
		if self.chatTimer >= 0 then
		self.chatTimer = self.chatTimer - 1
		--object.say(self.chatTimer)
		end
	end
  
end

function onInteraction(args)
  chatOptions = config.getParameter("chatOptions", {})
  object.say(chatOptions[(self.chatIndex % #chatOptions) + 1])
  self.chatTimer = 50
  self.chatIndex = self.chatIndex + 1
  animator.playSound("chatter")
end
