local utils = require "lib.utils"
local input = require "lib.input"
local temp  = require "lib.gameEntity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

---@class TutorialOverlay: GameEntity
---@field movementKeyIcons Sprite[]
---@field dashIcons [Sprite, Sprite]
---@field meleeIcons [Sprite, Sprite]
---@field aimIcon Sprite
---@field fireIcons [Sprite, Sprite]
---@field dpadIcon Sprite
---@field movementAxisIcon Sprite
---@field aimAxisIcon Sprite
---@field drawControlOverlay fun(self)
local TutorialOverlay = utils.class(
  GameEntity, function(instance)
    instance.movementKeyIcons = {
      input.getActionIcons("move up")[1],
      input.getActionIcons("move left")[1],
      input.getActionIcons("move down")[1],
      input.getActionIcons("move right")[1]
    }

    instance.dashIcons = input.getActionIcons("dash")
    instance.meleeIcons = input.getActionIcons("melee")
    instance.aimIcon = input.getActionIcons("aim")[1]
    instance.fireIcons = input.getActionIcons("auto fire")
    instance.dpadIcon = input.getGamepadIcon("dpad all")
    if input.swapThumbsticks() then
      instance.movementAxisIcon = input.getGamepadIcon("right stick")
      instance.aimAxisIcon = input.getGamepadIcon("left stick")
    else
      instance.movementAxisIcon = input.getGamepadIcon("left stick")
      instance.aimAxisIcon = input.getGamepadIcon("right stick")
    end

    instance.tags = {
      EntityTag.USES_SCREEN_SPACE_COORDS,
      EntityTag.HUD
    }
    instance.displayLayer = 5
  end
)

function TutorialOverlay:drawControlOverlay()
  local startX, startY = 24, 24

  local font = Fonts.RED_HAT_DISPLAY_30
  love.graphics.setFont(font)
  if input.currentInputType() == "keyboard" then
    love.graphics.setColor(love.math.colorFromBytes(50, 49, 59, 196))
    love.graphics.rectangle("fill", 0, 0, 460, 230)
    love.graphics.setColor(1, 1, 1)

    -- movement keys
    local x, y = startX, startY
    for _, icon in ipairs(self.movementKeyIcons) do
      icon:draw(x, y, 1, 0.3125)
      x = x + (icon.width * 0.3125) - 2
    end
    love.graphics.print("to move", x, y, 0, 1, 1, 12, 20)

    -- dash
    x = startX; y = y + 45
    love.graphics.print("Tap", x, y, 0, 1, 1, 12, 20)
    x = x + font:getWidth("Tap ") + 7

    local icon = self.dashIcons[1]
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to dash", x, y, 0, 1, 1, 12, 20)

    -- melee
    x = startX; y = y + 45
    love.graphics.print("Tap", x, y, 0, 1, 1, 12, 20)
    x = x + font:getWidth("Tap ") + 7

    icon = self.meleeIcons[1]
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to melee", x, y, 0, 1, 1, 12, 20)

    -- aim/fire
    x = startX; y = y + 45
    love.graphics.print("Hold", x, y, 0, 1, 1, 12, 20)
    x = x + font:getWidth("Hold ") + 7

    icon = self.aimIcon
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to aim and release to fire", x, y, 0, 1, 1, 12, 20)

    -- rapid fire
    x = startX; y = y + 45
    love.graphics.print("Hold", x, y, 0, 1, 1, 12, 20)
    x = x + font:getWidth("Hold ") + 7

    icon = self.fireIcons[1]
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("while aiming to rapid fire", x, y, 0, 1, 1, 12, 20)
  else
    love.graphics.setColor(love.math.colorFromBytes(50, 49, 59, 196))
    love.graphics.rectangle("fill", 0, 0, 460, 230)
    love.graphics.setColor(1, 1, 1)

    -- movement
    local x, y = startX, startY
    local icon = self.movementAxisIcon
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to move", x, y, 0, 1, 1, 10, 20)

    -- aiming
    x = startX; y = y + 45
    icon = self.aimAxisIcon
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to aim", x, y, 0, 1, 1, 12, 20)

    -- dash
    x = startX; y = y + 45
    love.graphics.print("Tap", x, y, 0, 1, 1, 12, 20)
    x = x + font:getWidth("Tap ") + 7

    icon = self.dashIcons[2]
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to dash", x, y, 0, 1, 1, 12, 20)

    -- melee
    x = startX; y = y + 45
    love.graphics.print("Tap", x, y, 0, 1, 1, 12, 20)
    x = x + font:getWidth("Tap ") + 7

    icon = self.meleeIcons[2]
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to melee", x, y, 0, 1, 1, 12, 20)

    -- rapid fire
    x = startX; y = y + 45
    love.graphics.print("Hold", x, y, 0, 1, 1, 12, 20)
    x = x + font:getWidth("Hold ") + 7

    icon = self.fireIcons[2]
    icon:draw(x, y, 1, 0.3125)
    x = x + (icon.width * 0.3125) - 2
    love.graphics.print("to fire", x, y, 0, 1, 1, 12, 20)
  end
end

function TutorialOverlay:draw()
  self:drawControlOverlay()
end

return TutorialOverlay