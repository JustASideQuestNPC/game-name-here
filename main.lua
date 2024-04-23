local input = require("input-manager")
local settings = require("_settings")

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