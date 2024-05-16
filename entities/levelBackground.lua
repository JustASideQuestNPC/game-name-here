-- Simple level/room background.
local utils  = require "lib.utils"
local engine = require "lib.engine"
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
  for x = 0, engine.roomWidth() - 300, 300 do
    for y = 0, engine.roomHeight() - 300, 300 do
      if blue then
        love.graphics.setColor(love.math.colorFromBytes(243, 167, 135))
      else
        love.graphics.setColor(1, 1, 1)
      end
      love.graphics.rectangle("fill", x, y, 300, 300)
      blue = not blue
    end
    if math.floor(((engine.roomWidth() - 300) / 300) % 2) == 0 then
      blue = not blue
    end
  end
end

return LevelBackground