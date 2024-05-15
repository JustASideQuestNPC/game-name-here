local input      = require "lib.input"
local gameConfig = require "_gameConfig"
local json       = require "lib.json"

-- My engine class is accessed through the global Engine variable so this is completely unused, but
-- everything crashes and burns for some reason unless I require the file in main. This is truly a
-- coconut.jpg moment.
local _ = require "lib.engine"

local LevelBackground = require "entities.levelBackground"
local Player = require "entities.player"
local Wall = require "entities.wall"
local WaveLauncherEnemy = require "entities.waveLauncherEnemy"

-- called once on program start
function love.load()
  love.filesystem.setIdentity(gameConfig.saveDirectory)

  local userSettings
  -- if the user settings file doesn't exist (probably because this is the first time the game has
  -- has been run), create it using the default settings
  if love.filesystem.getInfo("userSettings.json") == nil or
     DEBUG_CONFIG.FORCE_RESET_USER_SETTINGS then

    userSettings = gameConfig.defaultUserSettings
    love.filesystem.write("userSettings.json", json.encode(userSettings))
  else
    userSettings = json.decode(love.filesystem.read("userSettings.json"))
  end

  -- convert some graphics configs from human-readable formats into the love2d format
  local vsync
  if  userSettings.graphics.vsync == "adaptive" then
    vsync = -1 -- adaptive vsync where supported
  elseif  userSettings.graphics.vsync == false then
    vsync = 0 -- vsync disabled
  else
    vsync = 1 -- vsync enabled
  end

  -- start love2d 
  love.window.setMode(
    userSettings.graphics.width,
    userSettings.graphics.height,
    { -- flags
      fullscreen = userSettings.graphics.fullscreen,
      vsync = vsync,
      msaa = userSettings.graphics.msaaSamples,
      resizable = true
    }
  )
  love.window.setTitle("[GAME NAME HERE]")

  local xZoom = userSettings.graphics.width / gameConfig.engine.viewportWidth
  local yZoom = userSettings.graphics.height / gameConfig.engine.viewportHeight
  Engine.setCameraZoom(math.min(xZoom, yZoom))

  local font = love.graphics.newFont("assets/fonts/RedHatDisplay-Regular.ttf", 30)
  love.graphics.setFont(font)

  -- set up input
  input.initGamepad()

  -- load user keybinds
  local actions = {}
  for _, action in ipairs(gameConfig.input.actions) do
    if action.name == "aim release" then
      action.keys = userSettings.input.keyboardBinds["aim"]
      action.gamepadButtons = {}
    else
      if userSettings.input.keyboardBinds[action.name] ~= nil then
        action.keys = userSettings.input.keyboardBinds[action.name]
      else
        action.keys = {}
      end

      if userSettings.input.gamepadBinds[action.name] ~= nil then
        action.gamepadButtons = userSettings.input.gamepadBinds[action.name]
      else
        action.gamepadButtons = {}
      end
    end
    
    actions[#actions+1] = action
  end

  input.addActionList(actions)
  input.setSwapThumbsticks(gameConfig.input.swapThumbsticks)

  -- start the game engine
  Engine.addEntity(LevelBackground())
  Engine.addEntity(Wall(0, -100, gameConfig.gameplay.roomWidth, 100))
  Engine.addEntity(Wall(0, gameConfig.gameplay.roomHeight, gameConfig.gameplay.roomWidth, 100))
  Engine.addEntity(Wall(-100, -100, 100, gameConfig.gameplay.roomHeight + 200))
  Engine.addEntity(Wall(gameConfig.gameplay.roomWidth, -100, 100, gameConfig.gameplay.roomHeight + 200))

  -- global reference to the player
---@diagnostic disable-next-line: assign-type-mismatch
  PlayerEntity = Engine.addEntity(Player(Engine.roomCenter())) ---@type Player

  Engine.addEntity(WaveLauncherEnemy(Engine.roomWidth() / 2 - 500, Engine.roomHeight() / 2))
end

---Called once per frame to update the game.
---@param dt number The time between the previous two frames in seconds.
function love.update(dt)
  if input.isActive("toggle fullscreen") then
    love.window.setFullscreen(not love.window.getFullscreen())
  end

  input.update(dt)
  Engine.update(dt)
end

---Called once per frame to draw the game
function love.draw()
  love.graphics.clear(love.math.colorFromBytes(50, 49, 59))
  Engine.draw()
end

---Called when a key is pressed.
---@param key string
function love.keypressed(key)
  input.keyPressed(key)
end

---Called when a key is released.
---@param key string
function love.keyreleased(key)
  input.keyReleased(key)
end

---Called when the mouse is pressed.
---@param x number The x position of the mouse in pixels.
---@param y number The y position of the mouse in pixels.
---@param button integer The button index that was pressed.
---@param istouch boolean Whether the button press originated from a touchscreen press.
function love.mousepressed(x, y, button, istouch)
  input.mousePressed(button)
end

---Called when the mouse is released.
---@param x number The x position of the mouse in pixels.
---@param y number The y position of the mouse in pixels.
---@param button integer The button index that was release.
---@param istouch boolean Whether the button release originated from a touchscreen touch-released
function love.mousereleased(x, y, button, istouch)
  input.mouseReleased(button)
end

---Called when a gamepad button is pressed.
---@param joystick table The joystick/gamepad object.
---@param button string The button that was pressed.
function love.gamepadpressed(joystick, button)
  input.gamepadPressed(button)
end

---Called when the mouse is moved.
---@param x number The x position of the mouse in pixels.
---@param y number The y position of the mouse in pixels.
---@param dx number The x movement since `love.mousemoved()` was last called, in pixels.
---@param dy number The y movement since `love.mousemoved()` was last called, in pixels.
---@param istouch boolean Whether the mouse movement originated from a touchscreen movement.
function love.mousemoved(x, y, dx, dy, istouch)
  input.mouseMoved(x, y, dx, dy)
end

---Called when a gamepad button is released.
---@param joystick table The joystick/gamepad object.
---@param button string The button that was released.
function love.gamepadreleased(joystick, button)
  input.gamepadReleased(button)
end

---Called when a gamepad axis is moved.
---@param joystick table The joystick/gamepad object.
---@param axis string The axis that was moved.
---@param value number The new axis value.
function love.gamepadaxis(joystick, axis, value)
  input.gamepadAxis(axis, value)
end