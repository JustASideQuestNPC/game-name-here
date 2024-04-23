-- Manages keyboard and mouse input.
local utils = require("utils")

local BUFFER_SIZE = 0.5 -- size of the input buffer in seconds

---@class ActionConfig An object with data for an input action.
---@field name string
---@field keys table
---@field mode string Optional, defaults to "continuous".
---@field chord boolean Optional, defaults to false.

-- all managed actions
local activeActions = {}

-- the state of every key and mouse button
local keyStates = {}
-- makes keys that have never been pressed default to false (instead of nil)
setmetatable(keyStates, {
  __index = function () return false end
})

local clearedActions = {} -- which actions should be reset on the next update

-- Mouse buttons are bound to numbers in love, so I give them placeholder names for the state table.
local mouseButtonNames = {
  "left mouse",
  "right mouse",
  "middle mouse",
  "mouse 4",
  "mouse 5"
}

---Adds an action to the input manager
---@param actionConfig ActionConfig
local function addAction(actionConfig)
  -- unpack config values + default parameter hack
  local name = actionConfig.name
  local keys = actionConfig.keys
  local mode = actionConfig.mode or "continuous"
  local chord = actionConfig.chord or false
  
  -- object to hold the action's methods
  local action = {
    keys = keys,
    mode = mode,
    active = 0 -- the input is active if this is > 0
  }

  if chord then
    -- chord actions require all keys to be pressed at the same time
    function action:isPressed()
      return utils.arrayEvery(self.keys, function (i)
        return keyStates[i]
      end)
    end
  else
    -- non-chord actions only require (at least) one key to be pressed
    function action:isPressed()
      return utils.arrayAny(self.keys, function (i)
        return keyStates[i]
      end)
    end
  end

  -- set update function based on activation mode
  if mode == "continuous" then
    -- continuous actions are active every frame they are pressed
    function action:update()
      if self:isPressed() then
        self.active = BUFFER_SIZE
      end
    end

  elseif mode == "press" then
    -- press actions are active for a single frame when initially pressed
    action.wasActive = false
    function action:update()
      if self:isPressed() then
        if not self.wasActive then
          self.active = BUFFER_SIZE
          self.wasActive = true
        end
      else
        self.wasActive = false
      end
    end
  else
    -- release actions are active for a single frame when initially released
    action.wasActive = true
    function action:update()
      if not self:isPressed() then
        if not self.wasActive then
          self.active = BUFFER_SIZE
          self.wasActive = true
        end
      else
        self.wasActive = false
      end
    end
  end

  -- add the action to the manager
  activeActions[name] = action
end

---Adds a list of actions to the input manager
---@param actionList table
local function addActionList(actionList)
  for _, action in ipairs(actionList) do
    addAction(action)
  end
end

---Updates all actions; should be called in love.update().
---@param dt number
local function update(dt)
  -- clear marked actions (if any)
  for _, name in ipairs(clearedActions) do
    activeActions[name].active = 0
  end
  clearedActions = {}

  -- update all actions
  for _, action in pairs(activeActions) do
    -- I don't know who decided Lua shouldn't have += or -=, but I hope Taco Bell gets their orders
    -- wrong for the next decade.
    action.active = action.active - dt;
    action:update()
  end
end

---Returns whether the named action is currently active.
---@param name string
---@return boolean
---@nodiscard
local function isActive(name)
  if activeActions[name].active > 0 then
    table.insert(clearedActions, name)
    return true
  end
  return false
end

---Updates the internal state when a key is pressed. Call in `love.keypressed()`.
---@param key string
local function keyPressed(key)
  keyStates[key] = true
end

---Updates the internal state when a key is released. Call in `love.keyreleased()`.
---@param key string
local function keyReleased(key)
  keyStates[key] = false
end

---Updates the internal state when a mouse button is pressed. Call in `love.mousepressed()`.
---@param button integer
local function mousePressed(button)
  keyStates[mouseButtonNames[button]] = true
end

---Updates the internal state when a mouse button is released. Call in `love.mousereleased()`.
---@param button integer
local function mouseReleased(button)
  keyStates[mouseButtonNames[button]] = false
end

return {
  addAction = addAction,
  addActionList = addActionList,
  update = update,
  isActive = isActive,
  keyPressed = keyPressed,
  keyReleased = keyReleased,
  mousePressed = mousePressed,
  mouseReleased = mouseReleased
}