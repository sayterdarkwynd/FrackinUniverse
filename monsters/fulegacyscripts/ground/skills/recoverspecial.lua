recoverSpecial = {}

function recoverSpecial.enter()
  if self.skillCooldownTimers["recoverSpecial"] <= 0 then
    local healthFraction = status.resource("health") / entity.maxHealth()
    if healthFraction <= config.getParameter("recoverSpecial.triggerHealthFraction") then
      return { healthPerSecond = (entity.maxHealth() * config.getParameter("recoverSpecial.recoverHealthFraction")) / config.getParameter("recoverSpecial.skillTimeLimit") }
    end
  end

  return nil
end

function recoverSpecial.enterWith(args)
  if not args.recoverSpecial then return nil end

  return { healthPerSecond = (entity.maxHealth() * config.getParameter("recoverSpecial.recoverHealthFraction")) / config.getParameter("recoverSpecial.skillTimeLimit") }
end

function recoverSpecial.enteringState(stateData)
  setAggressive(true, false)

  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("attack", "idle")
  monster.setActiveSkillName("recoverSpecial")

  entity.setEffectActive("recover", true)
end

function recoverSpecial.update(dt, stateData)
  if not canContinueSkill() or status.resource("health") <= 0 then return true end

  entity.heal(stateData.healthPerSecond * script.updateDt())

  return false
end

function recoverSpecial.leavingState(stateData)
  entity.setEffectActive("recover", false)
end
