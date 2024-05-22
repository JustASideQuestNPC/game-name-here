local input      = require "lib.input"
local gameConfig = require "_gameConfig"
local json       = require "lib.json"
local utils      = require "lib.utils"
local engine     = require "lib.engine"
local ListMenu   = require "lib.listMenu"

-- The console is stored in a global for easy access, but for some reason the game crashes unless I
-- require the file anyway. This is truly a coconut.jpg moment.
local _ = require "console.console"

local LevelBackground = require "entities.levelBackground"
local Player = require "entities.player"
local Wall = require "entities.wall"
local DebugTarget = require "entities.debugTarget"

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
SetGameState(GameState.GAMEPLAY)

DisplayScale = 1
local function setDisplayScale(width, height)
  local xZoom = width / gameConfig.engine.viewportWidth
  local yZoom = height / gameConfig.engine.viewportHeight
  DisplayScale = math.min(xZoom, yZoom)
end

---@type ListMenu, ListMenu, ListMenu
local mainPauseMenu, settingsMenu, graphicsMenu

---@type table<string, Sprite>
local menuSprites = {
  -- confirm,
  -- back,
  -- revert,
  -- reset
}

-- draws a tooltip that shows the confirm and back buttons
local function drawMenuTooltip()
  local font = Fonts.RED_HAT_DISPLAY_30

  local confirmSprite, backSprite
  if input.currentInputType() == "keyboard" then
    confirmSprite = menuSprites.confirm[1]
    backSprite = menuSprites.back[1]
  else
    confirmSprite = menuSprites.confirm[2]
    backSprite = menuSprites.back[2]
  end

  local confirmWidth = confirmSprite.width * 0.3125 + font:getWidth("Confirm") + 5
  local backWidth = backSprite.width * 0.3125 + font:getWidth("Back") + 5
  local totalWidth = confirmWidth + backWidth + 20
  local confirmX = confirmWidth / 2 - totalWidth / 2
  local backX = totalWidth / 2 - backWidth / 2
  local lineX = totalWidth / 2 - backWidth - 10

  love.graphics.push()
  love.graphics.translate(love.graphics.getPixelWidth() / 2, love.graphics.getPixelHeight() - 50)
  love.graphics.scale(DisplayScale)

  love.graphics.setColor(1, 1, 1)
  utils.drawImageTooltipCentered(confirmSprite, 0.3125, "Confirm", font, 5, confirmX, 0)
  utils.drawImageTooltipCentered(backSprite, 0.3125, "Back", font, 5, backX, 0)

  love.graphics.setLineWidth(3)
  love.graphics.line(lineX, -20, lineX, 20)
  love.graphics.pop()
end

-- draws a tooltip that shows the confirm, back, revert, and reset buttons
local function drawSettingsTooltip()
  local font = Fonts.RED_HAT_DISPLAY_30

  local confirmSprite, backSprite, revertSprite, resetSprite
  if input.currentInputType() == "keyboard" then
    confirmSprite = menuSprites.confirm[1]
    backSprite = menuSprites.back[1]
    revertSprite = menuSprites.revert[1]
    resetSprite = menuSprites.reset[1]
  else
    confirmSprite = menuSprites.confirm[2]
    backSprite = menuSprites.back[2]
    revertSprite = menuSprites.revert[2]
    resetSprite = menuSprites.reset[2]
  end

  local confirmWidth = confirmSprite.width * 0.3125 + font:getWidth("Confirm") + 5
  local backWidth = backSprite.width * 0.3125 + font:getWidth("Back") + 5
  local leftWidth = confirmWidth + backWidth + 20
  local confirmX = confirmWidth / 2 - leftWidth / 2
  local backX = leftWidth / 2 - backWidth / 2

  local revertWidth = revertSprite.width * 0.3125 + font:getWidth("Revert Changes") + 5
  local resetWidth = resetSprite.width * 0.3125 + font:getWidth("Reset to Default") + 5
  local rightWidth = revertWidth + resetWidth + 20
  local revertX = revertWidth / 2 - rightWidth / 2
  local resetX = rightWidth / 2 - resetWidth / 2

  local totalWidth = leftWidth + rightWidth + 20
  local leftX = leftWidth / 2 - totalWidth / 2
  local rightX = totalWidth / 2 - rightWidth / 2

  local leftLineX = leftWidth / 2 - backWidth - 10 + leftX
  local rightLineX = rightWidth / 2 - resetWidth - 10 + rightX
  local centerLineX = totalWidth / 2 - rightWidth - 10

  love.graphics.push()
  love.graphics.translate(love.graphics.getPixelWidth() / 2, love.graphics.getPixelHeight() - 50)
  love.graphics.scale(DisplayScale)

  love.graphics.setColor(1, 1, 1)
  utils.drawImageTooltipCentered(confirmSprite, 0.3125, "Confirm", font, 5, confirmX + leftX, 0)
  utils.drawImageTooltipCentered(backSprite, 0.3125, "Back", font, 5, backX + leftX, 0)
  utils.drawImageTooltipCentered(revertSprite, 0.3125, "Revert Changes", font, 5, revertX + rightX, 0)
  utils.drawImageTooltipCentered(resetSprite, 0.3125, "Reset to Default", font, 5, resetX + rightX + 3, 0)

  love.graphics.setLineWidth(3)
  love.graphics.line(leftLineX, -20, leftLineX, 20)
  love.graphics.line(rightLineX, -20, rightLineX, 20)
  love.graphics.line(centerLineX, -20, centerLineX, 20)
  love.graphics.pop()
end

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

    drawMenuTooltip()
  end,
  [GameState.SETTINGS_MENU] = function()
    if prevMenu == GameState.PAUSE_MENU then
      love.graphics.clear(love.math.colorFromBytes(50, 49, 59))
      engine.draw()

      love.graphics.setColor(love.math.colorFromBytes(50, 49, 59, 196))
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    settingsMenu:draw()

    drawMenuTooltip()
  end,
  [GameState.GRAPHICS_MENU] = function()
    if prevMenu == GameState.PAUSE_MENU then
      love.graphics.clear(love.math.colorFromBytes(50, 49, 59))
      engine.draw()

      love.graphics.setColor(love.math.colorFromBytes(50, 49, 59, 196))
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    graphicsMenu:draw()

    drawSettingsTooltip()
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
    if input.isActive("menu reset") then
      for _, option in ipairs(graphicsMenu.options) do
        if option.text == "Fullscreen" then
          option.value = gameConfig.defaultUserSettings.graphics.fullscreen
        elseif option.text == "MSAA" then
          local default = gameConfig.defaultUserSettings.graphics.msaa
          if default == 0 then
            option.selectedIndex = 1
          else
            option.selectedIndex = math.ceil(math.log(default, 2)) + 2
          end
          option.selectedValue = option.values[option.selectedIndex]
        elseif option.text == "VSync" then
          option.value = (gameConfig.defaultUserSettings.graphics.vsync == 1)
        end
      end
    elseif input.isActive("menu revert") then
      for _, option in ipairs(graphicsMenu.options) do
        if option.text == "Fullscreen" then
          option.value = UserSettings.graphics.fullscreen
        elseif option.text == "MSAA" then
          local default = UserSettings.graphics.msaa
          if default == 0 then
            option.selectedIndex = 1
          else
            option.selectedIndex = math.ceil(math.log(default, 2)) + 2
          end
          option.selectedValue = option.values[option.selectedIndex]
        elseif option.text == "VSync" then
          option.value = (UserSettings.graphics.vsync == 1)
        end
      end
    elseif input.isActive("menu back") then
      local newSettings = {
        width = UserSettings.graphics.width,
        height = UserSettings.graphics.height
      }
      for _, option in ipairs(graphicsMenu.options) do
        if option.text == "Fullscreen" then
          newSettings.fullscreen = option.value
        elseif option.text == "MSAA" then
          newSettings.msaaSamples = option.selectedValue[1]
        elseif option.text == "VSync" then
          if option.value then newSettings.vsync = 1 else newSettings.vsync = 0 end
        end
      end
      if newSettings.fullscreen ~= UserSettings.graphics.fullscreen or
         newSettings.msaa ~= UserSettings.graphics.msaa or
         newSettings.vsync ~= UserSettings.graphics.vsync then
        UserSettings.graphics = newSettings
        love.filesystem.write("userSettings.json", json.encode(UserSettings))
        love.window.setMode(
          UserSettings.graphics.width,
          UserSettings.graphics.height,
          { -- flags
            fullscreen = UserSettings.graphics.fullscreen,
            vsync = UserSettings.graphics.vsync,
            msaa = UserSettings.graphics.msaa,
            resizable = true
          }
        )
        setDisplayScale(love.graphics.getDimensions())
      end
      SetGameState(GameState.SETTINGS_MENU)
    end
  end
}

love.keyboard.setKeyRepeat(true)

-- Called once on program start.
function love.load()
  love.filesystem.setIdentity(gameConfig.saveDirectory)

  -- if the user settings file doesn't exist (probably because this is the first time the game has
  -- has been run), create it using the default settings
  Console.verboseLog("Looking for settings file...")
  if love.filesystem.getInfo("userSettings.json") == nil or
     DEBUG_CONFIG.FORCE_RESET_USER_SETTINGS then
    UserSettings = gameConfig.defaultUserSettings
    love.filesystem.write("userSettings.json", json.encode(UserSettings))
    Console.warn("userSettings.json was not found or could not be opened. A new settings file "..
                 "has been created in the save directory.")
  else
    UserSettings = json.decode(love.filesystem.read("userSettings.json"))

    -- verify that the settings data is still valid
    local saveRequired
    UserSettings, saveRequired = utils.verifyTable(UserSettings, gameConfig.defaultUserSettings)
    if saveRequired then
      Console.warn("userSettings.json is (at least) partially invalid. Missing and/or invalid "..
                   "data has been regenerated with default settings.")
      love.filesystem.write("userSettings.json", json.encode(UserSettings))
    end
  end

  -- start love2d
  Console.verboseLog("Starting love2d...")
  love.window.setMode(
    UserSettings.graphics.width,
    UserSettings.graphics.height,
    { -- flags
      fullscreen = UserSettings.graphics.fullscreen,
      vsync = UserSettings.graphics.vsync,
      msaa = UserSettings.graphics.msaa,
      resizable = true
    }
  )
  love.window.setTitle("[GAME NAME HERE]")

  Fonts.RED_HAT_DISPLAY_30 = love.graphics.newFont("assets/fonts/RedHatDisplay-Regular.ttf", 30)
  Fonts.RED_HAT_DISPLAY_56 = love.graphics.newFont("assets/fonts/RedHatDisplay-Regular.ttf", 56)
  Fonts.RED_HAT_DISPLAY_BLACK_84 = love.graphics.newFont("assets/fonts/RedHatDisplay-Black.ttf", 84)

  setDisplayScale(UserSettings.graphics.width, UserSettings.graphics.height)

  -- set up input
  input.initGamepad()

  -- load user keybinds
  Console.verboseLog("Loading keybinds...")
  local actions = {}
  for _, action in ipairs(gameConfig.input.actions) do
    if action.name == "aim release" then
      action.keys = UserSettings.input.keyboardBinds["aim"]
      action.gamepadButtons = {}
    else
      if UserSettings.input.keyboardBinds[action.name] ~= nil then
        action.keys = UserSettings.input.keyboardBinds[action.name]
      else
        action.keys = {}
      end

      if UserSettings.input.gamepadBinds[action.name] ~= nil then
        action.gamepadButtons = UserSettings.input.gamepadBinds[action.name]
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
  input.setSwapThumbsticks(UserSettings.input.swapThumbsticks)
  input.setGamepadRumbleEnabled(UserSettings.input.enableGamepadRumble)

  -- initialize gui menus
  Console.verboseLog("Initializing menus...")
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
  if UserSettings.graphics.msaa == 0 then
    msaaIndex = 1
  else
    msaaIndex = math.ceil(math.log(UserSettings.graphics.msaa, 2)) + 2
  end
  graphicsMenu = ListMenu({
    pos = {gameConfig.engine.viewportWidth / 2, gameConfig.engine.viewportHeight / 2},
    optionsFont = Fonts.RED_HAT_DISPLAY_56,
    optionsColor = {1, 1, 1},
    optionsHoverColor = {love.math.colorFromBytes(95, 201, 231)},
    optionsLineSpacing = 1.8,
    descriptionFont = Fonts.RED_HAT_DISPLAY_30,
    descriptionColor = {1, 1, 1},
    options = {
      {
        type = "toggle",
        text = "Fullscreen",
        trueColor = {love.math.colorFromBytes(95, 110, 231)},
        falseColor = {1, 1, 1},
        outlineColor = {love.math.colorFromBytes(50, 49, 59)},
        value = UserSettings.graphics.fullscreen
      },
      {
        type = "selector",
        text = "MSAA",
        description = "How many samples to use for antialiasing. Higher values look better but "..
                      "require more performance.",
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
        type = "toggle",
        text = "VSync",
        description = "Locks the game's frame rate to your display's refresh rate. If your frame "..
                      "rate is stable, keep this enabled.",
        trueColor = {love.math.colorFromBytes(95, 110, 231)},
        falseColor = {1, 1, 1},
        outlineColor = {love.math.colorFromBytes(50, 49, 59)},
        value = (UserSettings.graphics.vsync == 1)
      }
    },
  })

  -- load sprites for menu tooltips
  menuSprites.confirm = input.getActionIcons("menu confirm")
  menuSprites.back = input.getActionIcons("menu back")
  menuSprites.revert = input.getActionIcons("menu revert")
  menuSprites.reset = input.getActionIcons("menu reset")

  -- start the game engine
  Console.verboseLog("Starting engine...")
  engine.addEntity(LevelBackground())
  engine.addEntity(Wall(0, -100, gameConfig.gameplay.roomWidth, 100))
  engine.addEntity(Wall(0, gameConfig.gameplay.roomHeight, gameConfig.gameplay.roomWidth, 100))
  engine.addEntity(Wall(-100, -100, 100, gameConfig.gameplay.roomHeight + 200))
  engine.addEntity(Wall(gameConfig.gameplay.roomWidth, -100, 100, gameConfig.gameplay.roomHeight + 200))

  local centerX, centerY = engine.roomCenter()
  -- global reference to the player
---@diagnostic disable-next-line: assign-type-mismatch
  PlayerEntity = engine.addEntity(Player(centerX, centerY)) ---@type Player

  engine.addEntity(DebugTarget(centerX - 300, centerY))
  engine.addEntity(DebugTarget(centerX + 300, centerY))
  engine.addEntity(DebugTarget(centerX, centerY - 300))
  engine.addEntity(DebugTarget(centerX, centerY + 300))
end

---Called once per frame to update the game.
---@param dt number The time between the previous two frames in seconds.
function love.update(dt)
  if input.isActive("toggle fullscreen") then
    love.window.setFullscreen(not love.window.getFullscreen())
  end

  input.update(dt)

  if not Console.isEnabled() then
    updateFunctions[currentGameState](dt)
  end
end

---Called once per frame to draw the game.
function love.draw()
  drawFunctions[currentGameState]()
  Console.draw()
end

---Called when the window is resized.
---@param width number
---@param height number
function love.resize(width, height)
  setDisplayScale(width, height)
end

---Called when a key is pressed.
---@param key string
function love.keypressed(key, scancode, isrepeat)
  Console.keypressed(key, scancode, isrepeat)
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

---Called when a character is typed. Accounts for modifier keys.
---@param text string
function love.textinput(text)
  Console.textinput(text)
end

love.errorhandler = require "lib.errorHandler"

Console.COMMAND_HELP.saveDir = "Opens your save directory."
Console.COMMANDS.saveDir = function(_)
  local path = love.filesystem.getSaveDirectory()
  Console.log("Opening save directory at "..path)
  love.system.openURL(path)
end

Console.COMMAND_HELP.showHitboxes = "Toggles whether to draw hitboxes."
Console.COMMANDS.showHitboxes = function(_)
  DEBUG_CONFIG.SHOW_HITBOXES = not DEBUG_CONFIG.SHOW_HITBOXES
end

Console.COMMAND_HELP.logToFile = "Writes existing console output to a file."
Console.COMMANDS.logToFile = function(args)
  if args[1] == nil then
    Console.error("Invalid argument: logFile requires a filename.")
  else
    Console.logToFile(args[1])
  end
end

Console.COMMAND_HELP.hcf = "Crashes the game, in case you wanted to do that for some reason."
Console.COMMANDS.hcf = function(_)
  local foo = {} + 1
end