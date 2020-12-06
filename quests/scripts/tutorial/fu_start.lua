require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
	setPortraits()
	storage.initCount=(storage.initCount and (storage.initCount+1)) or 1
	if (storage.initCount>1) and (not storage.missionStage) then setStage(1) end
end

function questStart()
	setStage(1)
end

function questComplete()
	player.setIntroComplete(true)
	questutil.questCompleteActions()
end

function update(dt)
	updateStage(dt)
end

function uninit()

end

function setStage(newStage)
	if newStage ~= storage.missionStage then
		if newStage == 1 then -- has a Matter Assembler
			player.radioMessage("fu_start_greetings0", 1)
			player.radioMessage("fu_start_greetings1", 1)
			player.radioMessage("fu_start_greetings2", 1)
			if storage.hasPickaxe ~= 1 then
				player.radioMessage("fu_start_greetingspickaxe", 1)
				player.giveItem("pickaxe")
				storage.hasPickaxe = 1
			end
		elseif newStage == 2 then
			player.radioMessage("fu_start_makeFurnace", 1)
		elseif newStage == 3 then
			player.radioMessage("fu_start_makeForaging", 1)
		elseif newStage == 4 then
			player.radioMessage("fu_start_makeTable", 1)
		elseif newStage == 5 then
			player.radioMessage("fu_start_makeWire", 1)
		elseif newStage == 6 then
			player.radioMessage("fu_start_makeElectromagnet", 1)
			player.radioMessage("fu_start_Complete1a", 1)
			player.radioMessage("fu_start_Complete1b", 1)
			player.radioMessage("fu_start_Complete1c", 1)
			player.giveItem("fuancientkey")
		end
		storage.missionStage = newStage
	end
end

function updateStage(dt)
	if storage.missionStage == 1 then
		if player.hasItem("craftingfurnace") then
			setStage(2)
		else
			quest.setObjectiveList({{config.getParameter("descriptions.makeFurnace"), false}})
		end
	elseif storage.missionStage == 2 then
		if player.hasItem("craftingfarm") then
			setStage(3)
		else
			quest.setObjectiveList({{config.getParameter("descriptions.makeForaging"), false}})
		end
	elseif storage.missionStage == 3 then
		if player.hasItem("prototyper") then
			setStage(4)
		else
			quest.setObjectiveList({{config.getParameter("descriptions.makeTable"), false}})
		end
	elseif storage.missionStage == 4 then
		if player.hasItem("wire") then
			player.consumeItem("wire")
			setStage(5)
		else
			quest.setObjectiveList({{config.getParameter("descriptions.makeWire"), false}})
		end
	elseif storage.missionStage == 5 then
		if player.hasItem("electromagnet") then
			player.consumeItem("electromagnet")
			setStage(6)
		else
			quest.setObjectiveList({{config.getParameter("descriptions.makeElectromagnet"), false}})
		end
	elseif storage.missionStage == 6 then
		player.upgradeShip(config.getParameter("shipUpgrade"))
		player.startQuest("fu_scienceoutpost") -- make sure they are aware of the Sci Outpost
		player.playCinematic(config.getParameter("scienceoutpostCinema"))
		quest.complete()
	end
end
