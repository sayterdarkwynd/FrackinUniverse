require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
  message.setHandler("enterMissionArea", function(_, _, areaName)
      stageEnterArea(areaName)
    end)

  message.setHandler("protectorateManagerId", function(_, _, id)
      self.managerId = id
      world.sendEntityMessage(self.managerId, "setSpecies", world.entitySpecies(entity.id()))
    end)

  message.setHandler("giveBeamaxe", function(...)
      if self.missionStage == 5 then
        setStage(6)
      end
    end)

  quest.setParameter("uniformLocker", {type = "item", item = "protectoratelobbylockers2"})
  quest.setParameter("beamaxe", {type = "item", item = "protectoratebeamaxe"})
  quest.setParameter("weaponChest", {type = "item", item = "weaponchest"})
  quest.setIndicators({})

  setPortraits()

  self.startingMusicTimer = config.getParameter("startingMusicTime")
  self.midpointMusicTimer = 0

  self.pesterTimer = 0

  setStage(1)

  status.setPersistentEffects("protectorateProtection", {
    { stat = "breathProtection", amount = 1.0 },
    { stat = "fallDamageMultiplier", effectiveMultiplier = 0.0}
  })
end

function questStart()
  player.giveEssentialItem("inspectiontool", "inspectionmode")

  if player.introComplete() then
    for _, item in pairs(config.getParameter("skipIntroItems", {})) do
      player.giveItem(item)
    end
    giveBeamaxe()
    quest.complete()
    return
  end

  storage.starterChest = player.equippedItem("chest")
  storage.starterLegs = player.equippedItem("legs")
end

function questComplete()
  player.setIntroComplete(true)

  questutil.questCompleteActions()
end

function update(dt)
  if self.startingMusicTimer > 0 then
    self.startingMusicTimer = self.startingMusicTimer - dt
    if self.startingMusicTimer <= 0 then
      world.sendEntityMessage(entity.id(), "playAltMusic", config.getParameter("startingMusicTracks"))
    end
  end

  if self.midpointMusicTimer > 0 then
    self.midpointMusicTimer = self.midpointMusicTimer - dt
    if self.midpointMusicTimer <= 0 then
      world.sendEntityMessage(entity.id(), "playAltMusic", config.getParameter("midpointMusicTracks"))
    end
  end

  updateStage(dt)

  updatePester(dt)
end

function uninit()
  status.clearPersistentEffects("protectorateProtection")

  if quest.state() == "Active" then
    -- player hasn't finished the mission
    -- confiscate any items they got during this attempt
    for _, item in pairs(config.getParameter("confiscateItems", {})) do
      player.consumeItem(item, true)
    end
    player.consumeItem(storage.starterChest)
    player.consumeItem(storage.starterLegs)

    player.removeEssentialItem("beamaxe")

    -- cleanup and sort inventory to put default clothes back into slots
    player.cleanupItems()
    player.giveItem(storage.starterChest)
    player.giveItem(storage.starterLegs)
  end
end

-- MISSION STAGES
-- 1 - start -> exit bed
-- 2 - dorm room
-- 3 - lounge
-- 4 - has uniform (optional)
-- 5 - auditorium cutscene
-- 6 - has MM
-- 7 - storeroom
-- 8 - has weapon
-- 9 -
-- 10 - reach ship -> finish

function setStage(newStage)
  if newStage ~= self.missionStage then
    if newStage == 1 then
      self.hasLounged = false
      setPester("protectorateExitBedPester", 20)
      quest.setObjectiveList({{config.getParameter("descriptions.graduate"), false}})
    elseif newStage == 2 then
      player.radioMessage("protectorateDormRoomTutorial", 1)
      setPester("protectorateDormRoomPester", 40)
    elseif newStage == 3 then
      quest.setIndicators({"uniformLocker"})
      player.radioMessage("protectorateLoungeTutorial")
      setPester()
    elseif newStage == 4 then
      quest.setIndicators({})
    elseif newStage == 5 then
      self.midpointTransitionTimer = 2.0
      self.midpointMusicTimer = config.getParameter("midpointMusicTime")
      world.sendEntityMessage(entity.id(), "playAltMusic", nil, 1.0)
      world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("midpointCinematic"))
    elseif newStage == 6 then
      quest.setIndicators({})
      giveBeamaxe()
      world.sendEntityMessage(entity.id(), "playCinematic", "/cinematics/beamaxe.cinematic")
      quest.setObjectiveList({{config.getParameter("descriptions.escape"), false}})
    elseif newStage == 7 then
      quest.setIndicators({"weaponChest"})
      player.radioMessage("protectorateGetWeapon")
    elseif newStage == 8 then
      quest.setIndicators({})
      setPester("protectorateWeaponPester", 15)
    elseif newStage == 10 then
      world.sendEntityMessage(entity.id(), "playAltMusic", nil, 1.0)
      world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("endpointCinematic"))
      self.missionCompleteTimer = 2.0
    end
    self.missionStage = newStage
  end
end

function updateStage(dt)
  if self.missionStage < 5 then
    mcontroller.controlModifiers({runningSuppressed = true})
  end

  if self.missionStage == 1 then
    if self.hasLounged == false then
      local loungeables = world.loungeableQuery(entity.position(), 10, {order = "nearest"})
      if #loungeables > 0 then
        self.hasLounged = player.lounge(loungeables[1])
      end
    end

    if self.hasLounged and not player.isLounging() then
      setStage(2)
    end
  elseif self.missionStage == 2 then

  elseif self.missionStage == 3 then
    if hasUniform() then
      setStage(4)
    end
  elseif self.missionStage == 4 then

  elseif self.missionStage == 5 then
    -- transition during cinematic, then need to get MM
    if self.midpointTransitionTimer > 0 then
      self.midpointTransitionTimer = self.midpointTransitionTimer - dt
      if self.midpointTransitionTimer <= 0 then
        player.radioMessage("protectorateStage5")
        world.sendEntityMessage(self.managerId, "midpointSwitch")
        quest.setIndicators({"beamaxe"})
        mcontroller.setPosition(config.getParameter("midpointTeleportPosition"))
        quest.setObjectiveList({{config.getParameter("descriptions.matterManipulator"), false}})
      end
    end
  elseif self.missionStage == 6 then
    -- needs to reach storeroom
  elseif self.missionStage == 7 then
    -- needs to pick up sword
    if player.hasItem("brokenprotectoratebroadsword") then
      setStage(8)
    end
  elseif self.missionStage == 8 then
    -- needs to break barrier (maybe nothing here)
    setStage(9)
  elseif self.missionStage == 9 then
    -- needs to reach ship
  elseif self.missionStage == 10 then
    if self.missionCompleteTimer > 0 then
      self.missionCompleteTimer = self.missionCompleteTimer - dt
      if self.missionCompleteTimer <= 0 then
          player.warp("ownship")
          quest.complete()
      end
    end
  end
end

-- MISSION AREAS
-- lounge
-- courtyard
-- lobby
-- auditorium
-- collapsedGallery
-- pastCollapsedGallery
-- floodedHallway
-- rooftop
-- duct
-- ductExit
-- collapsedHallway
-- storeroom
-- tentacleBarrier
-- shipPlatform
-- ship

function stageEnterArea(areaName)
  -- repeatable messages
  if areaName == "lounge" then
    setStage(3)
  elseif areaName == "courtyard" then

  elseif areaName == "lobby" then

  elseif areaName == "auditorium" then
    if self.missionStage < 5 then
      setStage(5)
    end
  elseif areaName == "collapsedGallery" then
    if self.missionStage == 5 then
      player.radioMessage("protectorateCollapsedGalleryNoMM")
    else
      player.radioMessage("protectorateCollapsedGallery")
      setPester("protectorateCollapsedGalleryPester", 20)
    end
  elseif areaName == "pastCollapsedGallery" then
    setPester()
  elseif areaName == "floodedDoor" then
    player.radioMessage("protectorateFloodedDoor")
  elseif areaName == "rooftop" then
    player.radioMessage("protectorateRooftop")
  elseif areaName == "duct" then
    player.radioMessage("protectorateDuct")
    setPester("protectorateDuctPester", 15)
  elseif areaName == "ductExit" then
    setPester()
  elseif areaName == "storeroom" then
    if self.missionStage < 7 then
      setStage(7)
    end
  elseif areaName == "tentacleBarrier" then
    if self.missionStage == 7 then
      player.radioMessage("protectorateTentacleBarrier")
    end
  elseif areaName == "shipPlatform" then
    setPester()
    player.radioMessage("protectorateShipPlatform")
  elseif areaName == "ship" then
    setStage(10)
    world.sendEntityMessage(entity.id(), "playCinematic", config.getParameter("endpointCinematic"))
  end
end

function hasUniform()
  return player.hasItem("protectoratechest") and player.hasItem("protectoratepants")
end

function hasEquippedUniform()
  local chestItem = player.equippedItem("chest")
  local chestCosmeticItem = player.equippedItem("chestCosmetic")
  local legsItem = player.equippedItem("legs")
  local legsCosmeticItem = player.equippedItem("legsCosmetic")
  return ((chestItem and chestItem.name == "protectoratechest") or
          (chestCosmeticItem and chestCosmeticItem.name == "protectoratechest")) and
         ((legsItem and legsItem.name == "protectoratepants") or
          (legsCosmeticItem and legsCosmeticItem.name == "protectoratepants"))
end

function setPester(messageId, timeout)
  self.pesterMessage = messageId
  self.pesterTimer = timeout or 0
end

function updatePester(dt)
  if self.pesterTimer > 0 then
    self.pesterTimer = self.pesterTimer - dt
    if self.pesterTimer <= 0 then
      player.radioMessage(self.pesterMessage)
    end
  end
end

function giveBeamaxe()
    local frconfig = root.assetJson("/frackinraces.config").manipulators
    if frconfig[player.species()] then
        mm = root.createItem(frconfig[player.species()].item or "beamaxe")
    else
        mm = root.createItem('beamaxe')
    end
    if frconfig[player.species()] and frconfig[player.species()].collectLiquid then
        mm.parameters.upgrades = { "liquidcollection" }
        mm.parameters.canCollectLiquid = true
    end
    if frconfig[player.species()] and frconfig[player.species()].rangeBonus then
        status.setStatusProperty("bonusBeamGunRadius", frconfig[player.species()].rangeBonus)
    end
    player.giveEssentialItem("beamaxe", mm)
end
