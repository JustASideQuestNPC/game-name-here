local input      = require "lib.input"
local gameConfig = require "_gameConfig"
local json       = require "lib.json"
local utils      = require "lib.utils"
local engine     = require "lib.engine"
local ListMenu   = require "lib.listMenu"

local LevelBackground = require "entities.levelBackground"
local Player = require "entities.player"
local Wall = require "entities.wall"
local WaveLauncherEnemy = require "entities.waveLauncherEnemy"

---@enum Fonts
Fonts = {
  RED_HAT_DISPLAY_30 = {},
  RED_HAT_DISPLAY_56 = {},
  RED_HAT_DISPLAY_BLACK_84 = {}
}

---@enum GameState
GameState = {
  GAMEPLAY = 0,
  PAUSE_MENU = 1,
  SETTINGS_MENU = 2,
  GRAPHICS_MENU = 3
}
local currentGameState = nil
local prevMenu = nil -- pause menu or main menu
function SetGameState(state)
  if currentGameState == GameState.PAUSE_MENU then
    prevMenu = currentGameState
  end
  currentGameState = state
end

DisplayScale = 1

---@type ListMenu, ListMenu, ListMenu
local mainPauseMenu, settingsMenu, graphicsMenu

-- Draw functions for each game state.
local drawFunctions = {
  [GameState.GAMEPLAY] = function()
    love.graphics.clear(love.math.colorFromBytes(50, 49, 59))
    engine.draw()
  end,
  [GameState.PAUSE_MENU] = function()
    love.graphics.clear(love.math.colorFromBytes(50, 49, 59))
    engine.draw()

    love.graphics.setColor(love.math.colorFromBytes(50, 49, 59, 196))
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    mainPauseMenu:draw()
  end,
  [GameState.SETTINGS_MENU] = function()
    if prevMenu == GameState.PAUSE_MENU then
      love.graphics.clear(love.math.colorFromBytes(50, 49, 59))
      engine.draw()

      love.graphics.setColor(love.math.colorFromBytes(50, 49, 59, 196))
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    settingsMenu:draw()
  end,
  [GameState.GRAPHICS_MENU] = function()
    if prevMenu == GameState.PAUSE_MENU then
      love.graphics.clear(love.math.colorFromBytes(50, 49, 59))
      engine.draw()

      love.graphics.setColor(love.math.colorFromBytes(50, 49, 59, 196))
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    graphicsMenu:draw()
  end
}

-- Update functions for each game state.
local updateFunctions = {
  [GameState.GAMEPLAY] = function(dt)
    engine.update(dt)
    if input.isActive("pause") then
      input.clearAction("menu back")
      SetGameState(GameState.PAUSE_MENU)
    end
  end,
  [GameState.PAUSE_MENU] = function(dt)
    mainPauseMenu:update()
    if input.isActive("menu confirm") and mainPauseMenu.hoveredOption ~= nil then
      local selected = mainPauseMenu.hoveredOption.text
      if selected == "Resume" then
        SetGameState(GameState.GAMEPLAY)
      elseif selected == "Settings" then
        SetGameState(GameState.SETTINGS_MENU)
      elseif selected == "Quit to Desktop" then
        love.event.quit()
      end
    elseif input.isActive("menu back") then
      input.clearAction("pause")
      SetGameState(GameState.GAMEPLAY)
    end
  end,
  [GameState.SETTINGS_MENU] = function(dt)
    settingsMenu:update()
    if input.isActive("menu confirm") and settingsMenu.hoveredOption ~= nil then
      local selected = settingsMenu.hoveredOption.text
      if selected == "Graphics" then
        SetGameState(GameState.GRAPHICS_MENU)
      end
    elseif input.isActive("menu back") then
      SetGameState(prevMenu)
    end
  end,
  [GameState.GRAPHICS_MENU] = function(dt)
    graphicsMenu:update()
    if input.isActive("menu confirm") and graphicsMenu.hoveredOption ~= nil then

    elseif input.isActive("menu back") then
      SetGameState(GameState.SETTINGS_MENU)
    end
  end
}

-- Called once on program start.
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

    -- verify that the settings data is still valid
    local saveRequired
    userSettings, saveRequired = utils.verifyTable(userSettings, gameConfig.defaultUserSettings)
    if saveRequired then
      print("partially regenerated user settings")
      love.filesystem.write("userSettings.json", json.encode(userSettings))
    end
  end

  -- start love2d 
  love.window.setMode(
    userSettings.graphics.width,
    userSettings.graphics.height,
    { -- flags
      fullscreen = userSettings.graphics.fullscreen,
      vsync = userSettings.graphics.vsync,
      msaa = userSettings.graphics.msaaSamples,
      resizable = true
    }
  )
  love.window.setTitle("[GAME NAME HERE]")

  Fonts.RED_HAT_DISPLAY_30 = love.graphics.newFont("assets/fonts/RedHatDisplay-Regular.ttf", 30)
  Fonts.RED_HAT_DISPLAY_56 = love.graphics.newFont("assets/fonts/RedHatDisplay-Regular.ttf", 56)
  Fonts.RED_HAT_DISPLAY_BLACK_84 = love.graphics.newFont("assets/fonts/RedHatDisplay-Black.ttf", 84)

  local xZoom = userSettings.graphics.width / gameConfig.engine.viewportWidth
  local yZoom = userSettings.graphics.height / gameConfig.engine.viewportHeight
  DisplayScale = math.min(xZoom, yZoom)

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

    -- the left stick can always be used to navigate menus
    if action.name == "menu up" then
      action.gamepadButtons[#action.gamepadButtons+1] = "left stick up"
    elseif action.name == "menu down" then
      action.gamepadButtons[#action.gamepadButtons+1] = "left stick down"
    elseif action.name == "menu left" then
      action.gamepadButtons[#action.gamepadButtons+1] = "left stick left"
    elseif action.name == "menu right" then
      action.gamepadButtons[#action.gamepadButtons+1] = "left stick right"
    end

    actions[#actions+1] = action
  end

  input.addActionList(actions)
  input.setSwapThumbsticks(userSettings.input.swapThumbsticks)
  input.setGamepadRumbleEnabled(userSettings.input.enableGamepadRumble)

  -- setui gui menus
  mainPauseMenu = ListMenu({
    pos = {gameConfig.engine.viewportWidth / 2, gameConfig.engine.viewportHeight / 2},
    title = "Game Paused",
    titleFont = Fonts.RED_HAT_DISPLAY_BLACK_84,
    titleColor = {1, 1, 1},
    titleOffset = 150,
    optionsFont = Fonts.RED_HAT_DISPLAY_56,
    optionsColor = {1, 1, 1},
    optionsHoverColor = {love.math.colorFromBytes(95, 201, 231)},
    optionsLineSpacing = 1.8,
    options = {
      {
        type = "text",
        text = "Resume"
      },
      {
        type = "text",
        text = "Settings"
      },
      {
        type = "text",
        text = "Quit to Desktop"
      }
    },
  })
  settingsMenu = ListMenu({
    pos = {gameConfig.engine.viewportWidth / 2, gameConfig.engine.viewportHeight / 2},
    optionsFont = Fonts.RED_HAT_DISPLAY_56,
    optionsColor = {1, 1, 1},
    optionsHoverColor = {love.math.colorFromBytes(95, 201, 231)},
    optionsLineSpacing = 1.8,
    options = {
      {
        type = "text",
        text = "Graphics"
      },
      {
        type = "text",
        text = "Gamepad Binds"
      },
      {
        type = "text",
        text = "Keyboard Binds"
      }
    },
  })

  local msaaIndex
  if userSettings.graphics.msaaSamples == 0 then
    msaaIndex = 1
  else
    msaaIndex = math.ceil(math.log(userSettings.graphics.msaaSamples, 2)) + 2
  end
  graphicsMenu = ListMenu({
    pos = {gameConfig.engine.viewportWidth / 2, gameConfig.engine.viewportHeight / 2},
    optionsFont = Fonts.RED_HAT_DISPLAY_56,
    optionsColor = {1, 1, 1},
    optionsHoverColor = {love.math.colorFromBytes(95, 201, 231)},
    optionsLineSpacing = 1.8,
    options = {
      {
        type = "toggle",
        text = "Enable Fullscreen",
        trueColor = {love.math.colorFromBytes(95, 110, 231)},
        falseColor = {1, 1, 1},
        outlineColor = {love.math.colorFromBytes(50, 49, 59)},
        value = userSettings.graphics.fullscreen
      },
      {
        type = "selector",
        text = "MSAA",
        values = {
          -- {value, displayed text}
          {0, "Disabled"},
          {1, "1x"},
          {2, "2x"},
          {4, "4x"},
          {8, "8x"}
        },
        selectedIndex = msaaIndex
      },
      {
        type = "selector",
        text = "VSync",
        values = {
          {-1, "Adaptive"},
          {0, "Disabled"},
          {1, "Enabled"}
        },
        selectedIndex = userSettings.graphics.vsync + 2
      }
    },
  })
  prevMenu = GameState.PAUSE_MENU
  SetGameState(GameState.GRAPHICS_MENU)

  -- start the game engine
  engine.addEntity(LevelBackground())
  engine.addEntity(Wall(0, -100, gameConfig.gameplay.roomWidth, 100))
  engine.addEntity(Wall(0, gameConfig.gameplay.roomHeight, gameConfig.gameplay.roomWidth, 100))
  engine.addEntity(Wall(-100, -100, 100, gameConfig.gameplay.roomHeight + 200))
  engine.addEntity(Wall(gameConfig.gameplay.roomWidth, -100, 100, gameConfig.gameplay.roomHeight + 200))

  -- global reference to the player
---@diagnostic disable-next-line: assign-type-mismatch
  PlayerEntity = engine.addEntity(Player(engine.roomCenter())) ---@type Player

  engine.addEntity(WaveLauncherEnemy(engine.roomWidth() / 2 - 500, engine.roomHeight() / 2))
end

---Called once per frame to update the game.
---@param dt number The time between the previous two frames in seconds.
function love.update(dt)
  if input.isActive("toggle fullscreen") then
    love.window.setFullscreen(not love.window.getFullscreen())
  end

  input.update(dt)

  updateFunctions[currentGameState](dt)
end

---Called once per frame to draw the game.
function love.draw()
  drawFunctions[currentGameState]()
end

---Called when the window is resized.
---@param width number
---@param height number
function love.resize(width, height)
  local xZoom = width / gameConfig.engine.viewportWidth
  local yZoom = height / gameConfig.engine.viewportHeight
  DisplayScale = math.min(xZoom, yZoom)
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