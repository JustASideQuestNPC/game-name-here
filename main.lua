local input    = require("input-manager")
local settings = require("_settings")
local Vector2  = require("vector2")
local utils    = require("utils")

-- called once on program start
function love.load()
  -- convert some graphics settings from human-readable formats into the love2d format
  if settings.graphics.vsync == "adaptive" then
    settings.graphics.vsync = -1 -- adaptive vsync where supported
  elseif settings.graphics.vsync == false then
    settings.graphics.vsync = 0 -- vsync disabled
  else
    settings.graphics.vsync = 1 -- vsync enabled
  end

  -- start love2d 
  love.window.setMode(
    settings.graphics.width,
    settings.graphics.height,
    { -- flags
      fullscreen = settings.graphics.fullscreen,
      vsync = settings.graphics.vsync,
      msaa = settings.graphics.msaaSamples
    }
  )

  -- set up input
  input.initGamepad()
  input.addActionList(settings.keybinds)
end

-- called once per frame to update the game
function love.update(dt)
  input.update(dt)
end

-- called once per frame to draw the game
function love.draw()
  love.graphics.clear()

  if input.isActive("continuous action") then
    love.graphics.setColor(1, 0, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.circle("fill", 100, 100, 50)

  if input.isActive("press action") then
    love.graphics.setColor(1, 0, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.circle("fill", 250, 100, 50)

  if input.isActive("release action") then
    love.graphics.setColor(1, 0, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.circle("fill", 400, 100, 50)

  if input.isActive("multiple keys") then
    love.graphics.setColor(1, 0, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.circle("fill", 550, 100, 50)

  if input.isActive("chord action") then
    love.graphics.setColor(1, 0, 0)
  else
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.circle("fill", 700, 100, 50)

  if input.gamepadConnected then
    local leftStick = input.getStickVector("left")
    local rightStick = input.getStickVector("right")
    local leftTrigger = input.getAxisValue("left trigger")
    local rightTrigger = input.getAxisValue("right trigger")

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format(
      "Left Stick: %s"..
    "\nRight Stick: %s"..
    "\nLeft Trigger: %.2f"..
    "\nRight Trigger: %.2f",
      leftStick, rightStick, leftTrigger, rightTrigger
      ), 80, 210
    )
    
    -- convert axis values to display positions
    leftStick = leftStick * 50
    leftStick = leftStick + Vector2.new(300, 250)
    rightStick = rightStick * 50
    rightStick = rightStick + Vector2.new(450, 250)
    leftTrigger = utils.map(leftTrigger, 0, 1, 290, 200)
    rightTrigger = utils.map(rightTrigger, 0, 1, 290, 200)

    love.graphics.circle("line", 300, 250, 50)
    love.graphics.circle("line", 450, 250, 50)
    
    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.rectangle("fill", 555, 200, 10, 100)
    love.graphics.rectangle("fill", 645, 200, 10, 100)

    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", leftStick.x, leftStick.y, 10)
    love.graphics.circle("fill", rightStick.x, rightStick.y, 10)

    love.graphics.rectangle("fill", 530, leftTrigger, 60, 10)
    love.graphics.rectangle("fill", 620, rightTrigger, 60, 10)
  end
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