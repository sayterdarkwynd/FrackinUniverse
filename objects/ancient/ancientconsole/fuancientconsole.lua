require "/scripts/util.lua"

function init()
  self.detectArea = config.getParameter("detectArea")
  self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
  self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])

  storage.active = storage.active or config.getParameter("startActive", false)

  message.setHandler("activate", function()
    storage.active = true
    animator.setAnimationState("console", "turnon")
    object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
  end)

  message.setHandler("isActive", function()
    return storage.active == true
  end)

  self.isOutpostGate = 1

  self.vaultActiveTime = config.getParameter("vaultActiveTime", 60)
  self.vaultInstanceOptions = config.getParameter("vaultInstanceOptions")
  self.vaultAccessConfig = root.assetJson("/interface/scripted/vaultaccess/vaultaccessgui.config")

  storage.vaultActive = storage.vaultActive or false

  message.setHandler("activateVault", function()
    if not storage.vaultActive then
      storage.vaultActive = true
      storage.vaultCloseTime = world.time() + self.vaultActiveTime
      math.randomseed(util.seedTime())
      local instanceOption = util.randomFromList(self.vaultInstanceOptions)
      storage.vaultType = instanceOption[1]
      storage.vaultWorldId = string.format("InstanceWorld:%s:%s:%s", instanceOption[2], sb.makeUuid(), 8)

      animator.setGlobalTag("destination", storage.vaultType)
      animator.setAnimationState("console", "turnon")
      animator.setAnimationState("portal", "open")
      animator.playSound("on");
      object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
    end
  end)

  message.setHandler("closeVault", function()
    if storage.vaultActive then
      closeVault()
    end
  end)

  if storage.active or storage.vaultActive then
    animator.setAnimationState("console", "on")
    object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
  else
    animator.setAnimationState("console", "off")
    object.setLightColor({0, 0, 0, 0})
  end

  if storage.vaultActive then
    animator.setGlobalTag("destination", storage.vaultType)
    animator.setAnimationState("portal", "openloop")
  end
end

function onInteraction()

    if not storage.active then
      return {config.getParameter("inactiveInteractAction"), config.getParameter("inactiveInteractData")}
    else
      return {config.getParameter("interactAction"), config.getParameter("interactData")}
    end
end

function update(dt)

--promises:add(world.sendEntityMessage(playerId, "messageName"), function(variable)
--    if variable then
--        return {config.getParameter("interactAction"), config.getParameter("interactData")}
--    end
--end, function()
--    return {config.getParameter("interactAction"), config.getParameter("interactData")} --for if they don't have the quest (if you set the entity message there)
--end)

  if self.isOutpostGate == 1 then
    if storage.active then
      local players = world.entityQuery(self.detectArea[1], self.detectArea[2], {
          includedTypes = {"player"},
          boundMode = "CollisionArea"
        })

      if #players > 0 and animator.animationState("portal") == "closed" then
        animator.setAnimationState("portal", "open")
        animator.playSound("on");
        object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
      elseif #players == 0 and animator.animationState("portal") == "openloop" then
        animator.setAnimationState("portal", "close")
        object.setLightColor({0, 0, 0, 0})
      end
    end
  end
end

function closeVault()
  storage.vaultActive = false
  animator.setAnimationState("console", "off")
  animator.setAnimationState("portal", "close")
  object.setLightColor({0, 0, 0, 0})
end
