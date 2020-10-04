require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
  setPortraits()
  setStage(1)
  message.setHandler("fu_completeTutorial", function()
	setStage(4)
  end)
end

function questStart()

end

function questComplete()
  player.setIntroComplete(true)
  local messagePlayers = world.playerQuery(entity.position(player.id()), config.getParameter("completionRange"))
  if messagePlayers then
    for _, playerId in pairs (messagePlayers) do
	  if playerId ~= player.id() then
        world.sendEntityMessage(playerId, "fu_completeTutorial")
	  end
	end
  end
  questutil.questCompleteActions()
end

function update(dt)
  updateStage(dt)
end

function uninit()

end

function setStage(newStage)
  if newStage ~= self.missionStage then
    if newStage == 1 then    -- has a Matter Assembler
	      player.radioMessage("fu_start_greetings0", 1)
	      player.radioMessage("fu_start_greetings1", 1)
	      player.radioMessage("fu_start_greetings2", 1)  
        player.radioMessage("fu_start_greetingspickaxe", 1) 
        quest.setObjectiveList({{config.getParameter("descriptions.makeFurnace"), false}})
        player.giveItem("pickaxe")       
    elseif newStage == 2 then
        player.radioMessage("fu_start_makeFurnace", 1)
        quest.setObjectiveList({{config.getParameter("descriptions.makeForaging"), false}})
    elseif newStage == 3 then  
        player.radioMessage("fu_start_makeForaging", 1)
        quest.setObjectiveList({{config.getParameter("descriptions.makeTable"), false}})
    elseif newStage == 4 then  -- has Wires      
        player.radioMessage("fu_start_makeTable", 1)
        quest.setObjectiveList({{config.getParameter("descriptions.makeWire"), false}})
    elseif newStage == 5 then
        player.radioMessage("fu_start_makeWire", 1)
        quest.setObjectiveList({{config.getParameter("descriptions.makeElectromagnet"), false}})
    elseif newStage == 6 then
        player.radioMessage("fu_start_makeElectromagnet", 1)
        player.radioMessage("fu_start_Complete1a", 1)  
        player.radioMessage("fu_start_Complete1b", 1)  
        quest.setObjectiveList({{config.getParameter("descriptions.cavern"), false}})
    end
    self.missionStage = newStage
  end
end

function updateStage(dt)
  if self.missionStage == 1 then
    if hasFurnace() then       
      setStage(2)
    end
  elseif self.missionStage == 2 then
    if hasForaging() then     
      setStage(3)
    end
  elseif self.missionStage == 3 then
    if hasAssembler() then     
      setStage(4)
    end    
  elseif self.missionStage == 4 then
    if hasWire() then
      player.consumeItem("wire")      
      setStage(5)
    end      
  elseif self.missionStage == 5 then
    if hasElectromagnet() then
      player.consumeItem("electromagnet")     
      setStage(6)
    end
  elseif self.missionStage == 6 then
    player.upgradeShip(config.getParameter("shipUpgrade"))
    quest.complete()     
  end
end

function hasFurnace()--1
  return player.hasItem("craftingfurnace")
end

function hasForaging()--1
  return player.hasItem("craftingfarm")
end

function hasAssembler()--2
  return player.hasItem("prototyper")
end

function hasElectromagnet()--3
  return player.hasItem("electromagnet")
end

function hasWire()--4
  return player.hasItem("wire")
end

