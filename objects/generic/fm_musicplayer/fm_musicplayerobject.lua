require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require "/scripts/stagehandutil.lua"

function init()
	self.players = {}
	wired = wireCheck()
	setLightState(wired)
	message.setHandler("changeMusic", function(_, _, music)
		sb.logInfo(tostring(music))
		object.setConfigParameter("soundEffect", music)
	end)
end

function update()
	for playerId, _ in pairs(self.players) do
		playerNearby = playerInRange(playerId)
		if not playerNearby then
			self.players[playerId] = nil
			world.sendEntityMessage(playerId, "stopAltMusic", 2.0)
		end
	end
	local newPlayers = broadcastAreaQuery({ includedTypes = {"player"} })
	for _, playerId in pairs(newPlayers) do
		if not self.players[playerId] then
			self.players[playerId] = true
		end
	end
	wired = wireCheck()
	setLightState(wired)
end

function setLightState(newState)
  if newState then
    animator.setAnimationState("light", "on")
    object.setSoundEffectEnabled(true)
	startMusic()
	if animator.hasSound("on") then
      animator.playSound("on");
    end
  else
    animator.setAnimationState("light", "off")
    object.setSoundEffectEnabled(false)
	stopMusic()
	if animator.hasSound("off") then
      animator.playSound("off");
    end
  end
end

function startMusic()
  for playerId, _ in pairs(self.players) do
    world.sendEntityMessage(playerId, "playAltMusic", config.getParameter("soundEffect"), 2.0)
  end
end

function stopMusic()
  for playerId, _ in pairs(self.players) do
    world.sendEntityMessage(playerId, "stopAltMusic", 2.0)
  end
end

function playerInRange(id)
	if not world.entityExists(id) then
		-- Player died or left the mission
		return false
	end
	local newPlayers = broadcastAreaQuery({ includedTypes = {"player"} })
	for _, playerId in pairs(newPlayers) do
		if id == playerId then
			return true
		end
	end
	return false
end

function uninit()
	stopMusic()
end

function die()
	stopMusic()
end

function wireCheck()
	if object.isInputNodeConnected(0) == true then
		if object.getInputNodeLevel(0) == true then
			return true
		else
			return false
		end
	else
	return false
	end
	return false
end