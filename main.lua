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

-- called once per frame to update the game
function love.update(dt)
  input.update(dt)
end

-- called once per frame to draw the game
function love.draw()
  love.graphics.clear()
end

-- called when a key is pressed
function love.keypressed(key)
  input.keyPressed(key)
end

-- called when a key is released
function love.keyreleased(key)
  input.keyReleased(key)
end

-- called when the mouse is pressed
function love.mousepressed(x, y, button, istouch)
  input.mousePressed(button)
end

-- called when the mouse is released
function love.mousereleased(x, y, button, istouch)
  input.mouseReleased(button)
end

-- called when a gamepad button is pressed
function love.gamepadpressed(joystick, button)
  input.gamepadPressed(button)
end

-- called when a gamepad button is released
function love.gamepadreleased(joystick, button)
  input.gamepadReleased(button)
end

-- called when a gamepad axis is moved
function love.gamepadaxis(joystick, axis, value)
  input.gamepadAxis(axis, value)
end