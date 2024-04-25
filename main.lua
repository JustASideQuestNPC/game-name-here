local input  = require "lib.input-manager"
local config = require "_config"

-- called once on program start
function love.load()

  -- convert some graphics configs from human-readable formats into the love2d format
  if config.graphics.vsync == "adaptive" then
    config.graphics.vsync = -1 -- adaptive vsync where supported
  elseif config.graphics.vsync == false then
    config.graphics.vsync = 0 -- vsync disabled
  else
    config.graphics.vsync = 1 -- vsync enabled
  end

  -- start love2d 
  love.window.setMode(
    config.graphics.width,
    config.graphics.height,
    { -- flags
      fullscreen = config.graphics.fullscreen,
      vsync = config.graphics.vsync,
      msaa = config.graphics.msaaSamples
    }
  )

  -- set up input
  input.initGamepad()
  input.addActionList(config.input.keybinds)
end

---Called once per frame to update the game.
---@param dt number The time between the previous two frames in seconds.
function love.update(dt)
  input.update(dt)
end

---Called once per frame to draw the game
function love.draw()
  love.graphics.clear()
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