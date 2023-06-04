function minionTriggerId(operation, plan)
  -- find the trigger id related to the minions in the plan
  local minionPurpose = util.find(operation.postconditions, function(pred) return pred[1] == "Minion" end)[2][1]
  local triggerOp = util.find(plan, function(op)
      return util.find(op.preconditions, function(pred) return pred[1] == "Minion" and pred[2][1] == minionPurpose end) ~= nil
    end)
  if triggerOp then
    local triggerId = util.find(triggerOp.postconditions, function(pred) return pred[1] == "Trigger" end)[3]

    return triggerId
  end
end

function reactionSpawnMinion(operation, plan, triggerPosition)
  local triggerId = minionTriggerId(operation, plan)
  local entityId = world.spawnMonster("largeminion", triggerPosition, {
      managerUid = entity.uniqueId(),
      bossId = self.bossId,
      triggerId = triggerId,
      level = 7
    })
  world.sendEntityMessage(entityId, "setGroup", {entityId})
  world.sendEntityMessage(self.bossId, "notify", {type = "newMinion", targetId = entityId})
end
