-- Manages keyboard and mouse input.
local utils   = require "lib.utils"
local config  = require "_game-config"
local Vector2 = require "lib.vector2"
local Sprite  = require "lib.sprite"
local temp = require "lib.input-sprite-paths"
local keyboardIconPaths, gamepadIconPaths = temp.keyboardPaths, temp.gamepadPaths

local BUFFER_SIZE = config.input.bufferSize -- size of the input buffer in seconds
-- gamepad analog values lower than this are clamped to 0
local LOW_DEADZONE = config.input.lowDeadzone
-- gamepad analog values higher than this are clamped to 1
local HIGH_DEADZONE = config.input.highDeadzone

local gamepad -- the active gamepad (if any)
local _gamepadConnected = false
local _vibrationSupported = false
local _gamepadType = "xbox" -- xbox or ps
local _swapThumbsticks = false

-- Which input type was last used, either "keyboard" or "gamepad"
local _currentInputType = "keyboard"

---@type table[] All currently managed actions.
local activeActions = {}

---@type table<string, boolean> The state of every key and mouse button
local keyStates = {}
-- makes keys that have never been pressed default to false (instead of nil)
setmetatable(keyStates, {
  __index = function() return false end
})

---@type table<string, boolean> The state of all gamepad buttons.
local gamepadButtonStates = {}
setmetatable(gamepadButtonStates, {
  __index = function() return false end
})

---@type table<string, number> The position of all gamepad axes.
local gamepadAxisValues = {}
setmetatable(gamepadAxisValues, {
  __index = function() return 0 end
})

---@type table[] Which actions should be reset on the next update.
local clearedActions = {}

--lookup table for converting love2d mouse button names into ones used by action configs 
local mouseButtonNames = {
  "left mouse",
  "right mouse",
  "middle mouse",
  "mouse 4",
  "mouse 5"
}

-- lookup table for converting love2d gamepad button names into ones used by action configs
local gamepadButtonNames = {
  a = "a", -- x on playstation controllers
  b = "b", -- circle on playstation controllers
  x = "x", -- square on playstation controllers
  y = "y", -- triangle on playstation controllers
  dpup = "dpad up",
  dpdown = "dpad down",
  dpleft = "dpad left",
  dpright = "dpad right",
  back = "share",
  start = "options",
  leftstick = "left stick click", -- l3 on playstation controllers
  rightstick = "right stick click", -- r3 on playstation controllers
  leftshoulder = "left bumper", -- l1 on playstation controllers
  rightshoulder = "right bumper" -- r1 on playstation controllers
}

-- lookup table for converting love2d gamepad axis names into ones used by action configs
local gamepadAxisNames = {
  leftx = "left stick x",
  lefty = "left stick y",
  rightx = "right stick x",
  righty = "right stick y",
  triggerleft = "left trigger",
  triggerright = "right trigger"
}

local mousePos = Vector2() -- Current mouse position.
local mouseDelta = Vector2() -- How far the mouse has moved since the last mouse movement event.

-- Checks whether a gamepad is connected and runs some setup if it is.
local function initGamepad()
  if love.joystick.getJoystickCount() > 0 then
    gamepad = love.joystick.getJoysticks()[1]

    print("Joystick Found:")
    print("Is gamepad: "..tostring(gamepad:isGamepad()))
    if gamepad:isGamepad() then
      _currentInputType = "gamepad"
      _gamepadConnected = true
      _vibrationSupported = gamepad:isVibrationSupported()
      local name = gamepad:getName():lower() ---@type string
      print("ID: "..gamepad:getID()..
          "\nName: ".. name..
          "\nGUID: "..gamepad:getGUID()..
          "\nDevice Info: "..gamepad:getDeviceInfo()..
          "\nAxis count: "..gamepad:getAxisCount()..
          "\nButton count: "..gamepad:getButtonCount()..
          "\nSupports vibration: "..tostring(_vibrationSupported))

      if name:find("ps3") or name:find("ps4") or name:find("ps5") then
        _gamepadType = "ps"
      end
    end
  end
end

---@class ActionConfig An object with data for an input action.
---@field name string
---@field keys string[]
---@field gamepadButtons string[]
---@field mode string Optional, defaults to "continuous".
---@field chord boolean Optional, defaults to false.

---Adds an action to the input manager
---@param actionConfig ActionConfig
local function addAction(actionConfig)
  -- unpack config values + default parameter hack
  local name = actionConfig.name
  local keys = actionConfig.keys
  local gamepadButtons = actionConfig.gamepadButtons or {}
  local mode = actionConfig.mode or "continuous"
  local chord = actionConfig.chord or false

  -- object to hold the action's methods
  local action = {
    keys = keys,
    gamepadButtons = gamepadButtons,
    mode = mode,
    active = 0 -- the input is active if this is > 0
  }

  if chord then
    -- chord actions require all keys to be pressed at the same time
    function action:isPressed()
      if _currentInputType == "gamepad" then
        return utils.arrayEvery(self.gamepadButtons, function (i)
          return gamepadButtonStates[i]
        end)
      else
        return utils.arrayEvery(self.keys, function (i)
          return keyStates[i]
        end)
      end
    end
  else
    -- non-chord actions only require (at least) one key to be pressed
    function action:isPressed()
      if _currentInputType == "gamepad" then
        return utils.arrayAny(self.gamepadButtons, function (i)
          return gamepadButtonStates[i]
        end)
      else
        return utils.arrayAny(self.keys, function (i)
          return keyStates[i]
        end)
      end
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

---Returns the position of a gamepad analog axis.
---@param name string
---@return number
---@nodiscard
local function getAxisValue(name)
  if _swapThumbsticks then
    if name == "left stick x" then
      name = "right stick x"
    elseif name == "left stick y" then
      name = "right stick y"
    elseif name == "right stick x" then
      name = "left stick x"
    elseif name == "right stick y" then
      name = "left stick y"
    end
  end
  return gamepadAxisValues[name]
end

---Returns the position of a stick as a *non-normalized* Vector2.
---@param stick string
---@return Vector2
---@nodiscard
local function getStickVector(stick)
  local v
  if (not _swapThumbsticks and stick == "left") or (_swapThumbsticks and stick == "right") then
    v = Vector2(
      gamepadAxisValues["left stick x"],
      gamepadAxisValues["left stick y"]
    )
  else
    v = Vector2(
      gamepadAxisValues["right stick x"],
      gamepadAxisValues["right stick y"]
    )
  end

  return v
end

---Returns a normalized vector constructed using 4 actions.
---@param up string
---@param down string
---@param left string
---@param right string
---@return Vector2
local function getDpadVector(up, down, left, right)
  local v = Vector2()
  if isActive(up) then
    v.y = v.y - 1
  end
  if isActive(down) then
    v.y = v.y + 1
  end
  if isActive(left) then
    v.x = v.x - 1
  end
  if isActive(right) then
    v.x = v.x + 1
  end

  return v:normalize()
end

---Returns the current position of the mouse.
---@return Vector2
---@nodiscard
local function getMousePos()
  return mousePos:copy()
end

---Returns how far the mouse has moved since the last mouse movement event.
---@return Vector2
---@nodiscard
local function getMouseDelta()
  return mouseDelta.copy()
end

---Sets the vibration of the gamepad, if possible.
---@param left number Strength of the left motor. Must be in the range [0, 1].
---@param right number Strength of the right motor. Must be in the range [0, 1].
---@param duration number Duration of the rumble in seconds. < 0 means infinite duration.
local function setGamepadRumble(left, right, duration)
  if _gamepadConnected and _vibrationSupported then
    gamepad:setVibration(left, right, duration)
  end
end

local function setCurrentInputType(type)
  _currentInputType = type
  love.mouse.setVisible(type == "keyboard")
end

---Returns an array with sprites for the first keyboard key and the first gamepad button bound to an
---action (if the key or button does not exist, the array item is nil).
---@param name string
---@return [Sprite, Sprite]
local function getActionIcons(name)
  local icons = {}

  if #activeActions[name].keys > 0 then
    local keyName = activeActions[name].keys[1]
    local path
    if keyboardIconPaths[keyName] ~= nil then
      path = "assets/icons/keyboard/"..keyboardIconPaths[keyName]
    else
      path = "assets/icons/keyboard/kb_"..keyName..".png"
    end
    icons[#icons+1] = Sprite(path, true, "assets/icons/keyboard/kb_blank_square.png")
  else
    icons[#icons+1] = nil
  end

  if #activeActions[name].gamepadButtons > 0 then
    local path
    local button = activeActions[name].gamepadButtons[1]
    if gamepadIconPaths[button] then
      path = "assets/icons/".._gamepadType.."/".._gamepadType.."_"..gamepadIconPaths[button]
    else
      path = "assets/icons/".._gamepadType.."/".._gamepadType.."_"..button..".png"
    end
    icons[#icons+1] = Sprite(path, true)
  else
    icons[#icons+1] = nil
  end

  return icons
end

---Returns a sprite with the icon for a keyboard key.
---@param name string
---@return Sprite
local function getKeyboardIcon(name)
  local path
  if keyboardIconPaths[name] ~= nil then
    path = "assets/icons/keyboard"..keyboardIconPaths[name]
  else
    path = "assets/icons/keyboard/kb_"..name..".png"
  end
  return Sprite(path, true, "assets/icons/keyboard/kb_blank_square.png")
end

---Returns a sprite with the icon for a gamepad button or joystick.
---@param name string
---@return Sprite
local function getGamepadIcon(name)
  local filename = gamepadIconPaths[name]
  local path = "assets/icons/".._gamepadType.."/".._gamepadType.."_"..filename
  return Sprite(path, true)
end

---Updates the internal state when a key is pressed. Call in `love.keypressed()`.
---@param key string
local function keyPressed(key)
  setCurrentInputType("keyboard")
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
  setCurrentInputType("keyboard")
  keyStates[mouseButtonNames[button]] = true
end

---Updates the internal state when a mouse button is released. Call in `love.mousereleased()`.
---@param button integer
local function mouseReleased(button)
  keyStates[mouseButtonNames[button]] = false
end

---Updates the internal state when the mouse is moved. Call in `love.mousemoved()`.
---@param x number
---@param y number
---@param dx number
---@param dy number
local function mouseMoved(x, y, dx, dy)
  -- setCurrentInputType("keyboard")
  mousePos.x = x
  mousePos.y = y
  mouseDelta.x = x
  mouseDelta.y = y
end

---Updates the internal state when a gamepad button is pressed. Call in `love.gamepadpressed()`.
---@param button string
local function gamepadPressed(button)
  setCurrentInputType("gamepad")
  gamepadButtonStates[gamepadButtonNames[button]] = true
end

---Updates the internal state when a gamepad button is released. Call in `love.gamepadreleased()`.
---@param button string
local function gamepadReleased(button)
  setCurrentInputType("gamepad")
  gamepadButtonStates[gamepadButtonNames[button]] = false
end

---Updates the internal state when a gamepad axis is moved. Call in `love.gamepadaxis()`
---@param axis string
---@param value number
local function gamepadAxis(axis, value)
  axis = gamepadAxisNames[axis]

  -- apply deadzones
  if value > 0 then
    if value < LOW_DEADZONE then
      value = 0
    elseif value > HIGH_DEADZONE then
      value = 1
    else
      value = utils.map(value, LOW_DEADZONE, HIGH_DEADZONE, 0, 1)
    end
  else
    if value > -LOW_DEADZONE then
      value = 0
    elseif value < -HIGH_DEADZONE then
      value = -1
    else
      value = utils.map(value, -LOW_DEADZONE, -HIGH_DEADZONE, 0, -1)
    end
  end

  -- prevents some really weird issues when trying to use a keyboard while a gamepad is connected
  if gamepadAxisValues[axis] ~= value then
    gamepadAxisValues[axis] = value
    setCurrentInputType("gamepad")
  end

  -- triggers also activate a button on a full pull
  if axis == "left trigger" or axis == "right trigger" then
    gamepadButtonStates[axis] = (value == 1)
  end
end

return {
  initGamepad = initGamepad,
  addAction = addAction,
  addActionList = addActionList,
  update = update,
  isActive = isActive,
  getAxisValue = getAxisValue,
  getStickVector = getStickVector,
  getDpadVector = getDpadVector,
  getMousePos = getMousePos,
  getMouseDelta = getMouseDelta,
  getActionIcons = getActionIcons,
  getKeyboardIcon = getKeyboardIcon,
  getGamepadIcon = getGamepadIcon,
  setGamepadRumble = setGamepadRumble,
  keyPressed = keyPressed,
  keyReleased = keyReleased,
  mousePressed = mousePressed,
  mouseReleased = mouseReleased,
  mouseMoved = mouseMoved,
  gamepadPressed = gamepadPressed,
  gamepadReleased = gamepadReleased,
  gamepadAxis = gamepadAxis,
  gamepadConnected = function() return _gamepadConnected end,
  currentInputType = function() return _currentInputType end,
  swapThumbsticks = function() return _swapThumbsticks end,
  setSwapThumbsticks = function(state) _swapThumbsticks = state end
}