require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require("/quests/scripts/portraits.lua")

function init()
  self.radioMessages = config.getParameter("radioMessages")
  self.debug = config.getParameter("debug")
  message.setHandler("growItem", function(...) growItem(...) end)
end

function growItem(message,isLocal,itemName)
	player.giveItem(itemName)
	if self.debug then
		local messageTemp = self.radioMessages.received
		messageTemp.text="Spawning item "..itemName
		player.radioMessage(messageTemp)
	end
end

function questStart()
	
end

function questComplete()
	questutil.questCompleteActions()
end

function update(dt)
end