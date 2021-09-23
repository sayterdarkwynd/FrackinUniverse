function init()
  object.setInteractive(true)
  if storage.state == nil then
    output(config.getParameter("defaultSwitchState", false))
  else
    output(storage.state)
  end
  storage.entityId = nil
  self.queryRange = config.getParameter("guardRange", 30)
  self.callCooldownDef = config.getParameter("guardCooldown", 5.0)
  self.callCooldown = self.callCooldownDef
  self.position = entity.position()
end

function state()
  return storage.state
end

function onInteraction(args)
  storage.entityId = args.sourceId
  output(not storage.state)
end

function update(dt)
  if storage.state and storage.entityId then
    self.callCooldown = self.callCooldown - dt
    if self.callCooldown <= 0 then
      self.callCooldown = self.callCooldownDef
      -- send a fake object break message
      local npcs = world.entityQuery(self.position, self.queryRange, { includedTypes = {"npc"} })
      for _,npcId in pairs(npcs) do
        if world.entityDamageTeam(npcId).team == 1 then
          world.sendEntityMessage(npcId, "notify", {type="objectBroken", sourceId=entity.id(), targetPosition=self.position, targetId=storage.entityId})
        end
      end
    end
  end
end

function output(state)
  storage.state = state
  if state then
    animator.setAnimationState("switchState", "on")
    if not (config.getParameter("alwaysLit")) then object.setLightColor(config.getParameter("lightColor", {0, 0, 0, 0})) end
    object.setSoundEffectEnabled(true)
    animator.playSound("on");
    object.setAllOutputNodes(true)
  else
    animator.setAnimationState("switchState", "off")
    if not (config.getParameter("alwaysLit")) then object.setLightColor(config.getParameter("lightColorOff", {0, 0, 0})) end
    object.setSoundEffectEnabled(false)
    animator.playSound("off");
    object.setAllOutputNodes(false)
  end
end
