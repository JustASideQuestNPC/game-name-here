-- Simple level/room background.
local utils  = require "lib.utils"
local temp   = require "lib.gameEntity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

---@class LevelBackground: GameEntity
local LevelBackground = utils.class(
  GameEntity, function (instance)
    instance.tags = {EntityTag.LEVEL_BACKGROUND}
    instance.displayLayer = -1
  end
)

function LevelBackground:draw()
  local blue = true -- which color to draw
  for x = 0, Engine.roomWidth(), 300 do
    for y = 0, Engine.roomHeight(), 300 do
      if blue then
        love.graphics.setColor(love.math.colorFromBytes(243, 167, 135))
      else
        love.graphics.setColor(1, 1, 1)
      end
      love.graphics.rectangle("fill", x, y, 300, 300)
      blue = not blue
    end
    blue = not blue
  end
end

return LevelBackground