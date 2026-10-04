require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/quests/scripts/portraits.lua"

function init()
  self.descriptions = config.getParameter("descriptions")

  setPortraits()
  if not player.hasQuest("gaterepair") then --the player must have chosen their ship, checked for with the gaterepair quest
    player.interact("ShowPopup", {message = tostring(config.getParameter("shipRepairMessage"))})
    quest.setObjectiveList({{self.descriptions.gaterepair, false}})
  end

  for _,quest in pairs(config.getParameter("questList")) do --start the quests that the command will complete
    player.startQuest(quest)
  end
end

function update(dt)
  if player.hasCompletedQuest("gaterepair") then --gaterepair has a killswitch to autocomplete if this quest has started
    quest.complete()
  end
end

function questComplete()
  questutil.questCompleteActions()

  for _,quest in pairs(config.getParameter("questList2")) do --start the quests that auto-complete
    player.startQuest(quest)
  end

  player.addTeleportBookmark(config.getParameter("outpostBookmark")) --add the Ark and SciOutpost teleports
  player.addTeleportBookmark(config.getParameter("outpostBookmark2"))

  player.giveEssentialItem("inspectiontool", "scanmode") --Scanning tool from the Outpost scan quest

  if player.hasCompletedQuest("fu_byos") then
    quest.addReward(config.getParameter("BYOSRewards")) --Free FTL drive for BYOS players
  else
    quest.setCompletionText(config.getParameter("vanillaCompletionText")) --Mentions ship repair
  end
end
