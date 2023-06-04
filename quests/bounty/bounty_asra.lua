require "/quests/bounty/bounty.lua"

local asraFixQuestComplete=questComplete
local asraFixQuestStart=questStart
local asraFixQuestFail=questFail

function questStart(...)
	if asraFixQuestStart then asraFixQuestStart(...) end
	player.startQuest("fu_asraNoxSailFix")
end

function questFail(...)
    world.sendEntityMessage(entity.id(),"swansongFailed")
	if asraFixQuestFail then asraFixQuestFail(...) end
end

function questComplete(...)
	world.sendEntityMessage(entity.id(),"swansongComplete")
	if asraFixQuestComplete then asraFixQuestComplete(...) end
end