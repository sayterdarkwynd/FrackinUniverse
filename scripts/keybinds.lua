--[[
Keybinds Library (https://github.com/Silverfeelin/Starbound-Keybinds)
Licensed under MIT (https://github.com/Silverfeelin/Starbound-Keybinds/blob/master/LICENSE)
This file may be redistributed without including a copy of the license, as long as this header remains unmodified.
]]

keybinds = {
  binds = {},
  initialized = false,
  version = "1.3.4",
  debug = false
}

--- Util

-- {"a"} = {"a" = true}. {"a"} = {f("a") = true}.
local set = function(values, f) local v = {};  for _,value in pairs(values) do v[f and f(value) or value] = true end return v; end
-- vec1-vec2
local sub = function(a, b) return { a[1] - b[1], a[2] - b[2] } end
-- http://lua-users.org/wiki/SplitJoin
function string:split(sep) local fields = {}; local pattern = string.format("([^%s]+)", sep or ":"); self:gsub(pattern, function(c) fields[#fields+1] = c end); return fields; end
-- Sets the tostring of of a table to "vec2"
function keybinds.setVec2(point) setmetatable(point, { __tostring = function() return "vec2" end }) end

keybinds.inputs = set({
  "up", "down", "left", "right",
  "primaryFire", "altFire",
  "shift", "running", "walking",
  "onGround", "jumping",
  "facingDirection", "liquidPercentage",
  "position", "aimPosition", "aimRelative",
  "specialOne", "f",
  "specialTwo", "g",
  "specialThree", "h",
  -- Flags
  "aimOffset", "time", "only", "all"
}, string.lower)

-- Binds that are specifically bound to keys users can hold down.
-- Used by flag 'only' and is incompatible with options 'f' 'g' 'h'.
keybinds.keys = set({
  "up", "down", "left", "right",
  "primaryFire", "altFire",
  "shift",
  "specialOne",
  "specialTwo",
  "specialThree",
}, string.lower)

-- Default values, do not touch.
keybinds.input = {
  onground = true, facingdirection = 1, liquidpercentage = 0,
  position = {0, 0}, aimposition = {0, 0}, aimoffset = {2, 2}, aimrelative = {0, 0},
  time = 0
}

-- Unique Bind identifier.
local uid = 1

-- Tracks when time-bound binds can activate.
local timeActive = {}

-- Finalizes Keybinds by injecting function keybinds.update in the tech's main update function.
function keybinds.init()
  if keybinds.initialized then return end
  keybinds.initialized = true
  local og = update
  update = og and function(args) keybinds.update(args); og(args); end or keybinds.update
  sb.logInfo("Keybinds v%s initialized.", keybinds.version)
end

-- Updates Keybinds
function keybinds.update(args)
  keybinds.updateInput(args)

  if keybinds.debug then
    sb.setLogMap("player_rel", string.format("%s %s", keybinds.input.aimrelative[1], keybinds.input.aimrelative[2]))
  end

  for _,bind in pairs(keybinds.binds) do
    local isMatch, matches, noMatches = bind:matches(keybinds.input)

    -- Run function if the current input matches the arguments of the bind.
    -- Disables consecutive calls unless the bind is repeatable.
    if isMatch and (bind.repeatable or not bind.executed) and (not bind.options.all or bind.argCount == matches) then
      bind.f(bind)
      bind.executed = true
    elseif not isMatch and bind.executed and (not bind.options.all or bind.argCount == noMatches) then
      bind.executed = false
    end
  end
end

--[[ Updates all values that can be used by keybinds.]]
function keybinds.updateInput(args)
  local input = keybinds.input

  input.up = args.moves.up
  input.left = args.moves.left
  input.down = args.moves.down
  input.right = args.moves.right

  input.primaryfire = args.moves.primaryFire
  input.altfire = args.moves.altFire

  input.shift = not args.moves.run

  input.onground = mcontroller.onGround()
  input.running = mcontroller.running()
  input.walking = mcontroller.walking()
  input.jumping = args.moves.jump
  input.facingdirection = mcontroller.facingDirection()
  input.liquidpercentage = mcontroller.liquidPercentage()

  input.position = mcontroller.position()
  input.aimposition = tech.aimPosition()
  input.aimrelative = sub(input.aimposition, input.position)

  input.specialone = args.moves.special1
  input.specialtwo = args.moves.special2
  input.specialthree = args.moves.special3
  input.f = input.specialone
  input.g = input.specialtwo
  input.h = input.specialthree
end

--[[ Returns a keybind table from the given string.
See file header for syntax and supported arguments.]]
function keybinds.stringToKeybind(s)
  args = {}

  for _,v in pairs(s:split(" ")) do
    local separator = v:find("=")
    local key = v:sub(0, separator and separator - 1 or nil):lower()
    local valueString =  separator and v:sub(separator + 1) or ""

    -- Default value is true
    local value = true
    if valueString == "false" then
      value = false
    elseif valueString == valueString:match("%-?%f[%.%d]%d*%.?%d*%f[^%.%d]") then
      -- Float
      value = tonumber(valueString)
    elseif valueString == valueString:match("%-?%f[%.%d]%d*%.?%d*%f[^%.%d],%-?%f[%.%d]%d*%.?%d*%f[^%.%d]") then
      -- Vec2
      local x = tonumber(valueString:sub(0,valueString:find(",") - 1))
      local y = tonumber(valueString:sub(valueString:find(",") + 1))
      value = {x,y}

      keybinds.setVec2(value)
    end

    args[key] = value
  end

  return args
end

Bind = {}
Bind.__index = Bind

function Bind.create(args, f, repeatable, disable)
  -- Creating a bind will finalize the set-up, if not done already.
  keybinds.init()

  local bind = {}
  setmetatable(bind, Bind)

  bind.id = uid
  uid = uid + 1
  bind.options = {}

  bind:change(args, f, repeatable)

  bind.active = not disable
  if bind.active then
    keybinds.binds[bind.id] = bind
  end

  return bind
end

function Bind:change(args, f, repeatable)
  if type(f) == "function" then self.f = f end
  if type(repeatable) ~= "nil" then self.repeatable = repeatable end

  self.args = type(args) == "string" and keybinds.stringToKeybind(args) or args or self.args
  if self.args.all then self.options.all = true; self.args.all = nil end
  if self.args.aimoffset then self.options.aimOffset = self.args.aimoffset; self.args.aimoffset = nil; end
  if self.args.only then self.options.only = true; self.args.only = nil end
  if self.args.time then self.options.time = self.args.time; self.args.time = nil end

  self.argCount = 0;
  for _ in pairs(self.args) do self.argCount = self.argCount + 1 end

  self.executed = false

  -- Set the tostring of valid tables to vec2.
  for _,v in pairs(self.args) do
    if type(v) == "table" and #v == 2 and type(v[1]) == "number" and type(v[2]) == "number" then keybinds.setVec2(v) end
  end

  -- If "only" is set, set missing keys to false.
  if self.options.only then
    for k in pairs(keybinds.keys) do
      if self.args[k] == nil then self.args[k] = false end
    end
  end
end

-- Swaps self.f with target.f
function Bind:swap(target)
  self.f, target.f = target.f, self.f
end

-- Activates a bind.
function Bind:rebind()
  self.active = true
  keybinds.binds[self.id] = self
end

-- Deactivates a bind.
function Bind:unbind()
  self.active = false
  keybinds.binds[self.id] = nil
end

-- Toggles the bind. See Bind:rebind and Bind:unbind
function Bind:toggle(active)
  if active == nil then active = not self.active end
  if active then self:rebind() else self:unbind() end
end

-- bind:isActive() = bind.active
function Bind:isActive() return self.active end

-- Checks if input matches bind.args.
-- Returns:
-- * true if bind matches, false otherwise
-- * amount of matching arguments
-- * amount of non-matching arguments
function Bind:matches(input)
  local matches, noMatches = 0, 0

  -- For every bind, check every arg.
  -- If an arg does not match the current input, prevent the function for this bind from being called.
  for k,v in pairs(self.args) do
    if keybinds.input[k] == v then
      matches = matches + 1
    else
      -- Value for this argument does not match expected value for keybind.

      if tostring(v) == "vec2" then
        -- Check if positions are within the allowed range.
        local dx = math.abs(v[1] - keybinds.input[k][1])
        local dy = math.abs(v[2] - keybinds.input[k][2])

        local offset = self.options.aimOffset or keybinds.input.aimoffset

        if dx > offset[1] or dy > offset[2] then
          noMatches = noMatches + 1
        else
          matches = matches + 1
        end
      else
        noMatches = noMatches + 1
      end
    end
  end

  -- Special handling for timed binds.
  local timeMatch = true
  if self.options.time then
    local clock = os.clock()
    if (self.options.all and matches ~= self.argCount) or noMatches > 0 then
      timeActive[self.id] = nil
    elseif not timeActive[self.id] then
      timeActive[self.id] = clock + self.options.time
      timeMatch = false
    elseif timeActive[self.id] > clock then
      timeMatch = false
    end

  end

  local isMatch = timeMatch and noMatches == 0
  return isMatch, matches, noMatches
end
