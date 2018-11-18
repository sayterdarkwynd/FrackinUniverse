function bossReset()
  animator.setAnimationState("head", "sleeping")
  animator.setAnimationState("hands", "invisible")
  animator.resetTransformationGroup("lefthand")
  animator.resetTransformationGroup("righthand")

  local dolls = world.entityQuery(mcontroller.position(), 60, { includedTypes = {"monster"} })
  for _,doll in pairs(dolls) do
    if world.monsterType(doll) == "doll2" then
      world.callScriptedEntity(doll, "monster.setDropPool", nil)
      world.callScriptedEntity(doll, "status.setResource", "health", 0)
    end
  end

  mcontroller.setPosition(self.spawnPosition)
end
