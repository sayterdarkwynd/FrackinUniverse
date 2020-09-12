require "/scripts/util.lua"

Timer = {
  key = nil,
  delay = nil, 
  timeCallback = nil,
  completeCallback = nil,
  loop = false
}

-- Methods for creating and setting up timers:
function Timer:new(storageKey, o)
  o = o or {}
  o.key = storageKey
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Methods for using and updating timers:
function Timer:update(dt)
  if not self:active() then return end

  if not self.timeCallback then
    storage[self.key] = storage[self.key] - dt
  end
  if self:complete() and self.completeCallback then
    self.completeCallback()
    if self.loop then
      self:reset()
    else
      self:stop()
    end
  end
end

function Timer:active()
  return storage[self.key] ~= nil
end

function Timer:complete()
  if not self:active() then
    return false
  end
  if self.timeCallback then
    return self.timeCallback() >= storage[self.key]
  else
    return storage[self.key] <= 0
  end
end

function Timer:generateDelay(delay)
  if delay == nil then
    delay = self.delay
  end
  if type(delay) == "table" then
    return delay[1] + math.random() * (delay[2] - delay[1])
  elseif type(delay) == "string" then
    return util.randomInRange(config.getParameter(delay))
  elseif type(delay) == "function" then
    return delay()
  else
    return delay
  end
end

function Timer:start(delay)
  storage[self.key] = self:generateDelay(delay)
  if storage[self.key] and self.timeCallback then
    storage[self.key] = storage[self.key] + self.timeCallback()
  end
  return self
end

-- reset() restarts the timer only if it was currently running
function Timer:reset(delay)
  if self:active() then
    self:start(delay)
  end
end

function Timer:stop()
  storage[self.key] = nil
end

-- TimerManager calls update on a list of timers and can automatically start and stop them when
-- certain callback predicates hold.
TimerManager = {}

function TimerManager:new()
  o = {
      timers = {}
    }
  setmetatable(o, self)
  self.__index = self
  return o
end

function TimerManager:manage(timer)
  self.timers[#self.timers+1] = {timer, nil}
end

function TimerManager:runWhile(timer, predicate)
  self.timers[#self.timers+1] = {timer, predicate}
end

function TimerManager:update(dt)
  for _,entry in ipairs(self.timers) do
    local timer = entry[1]
    local predicate = entry[2]
    if predicate then
      if predicate() then
        if not timer:active() then timer:start() end
      else
        timer:stop()
      end
    end
    timer:update(dt)
  end
end
