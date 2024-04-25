local e = require "lib.game-entity"
local GameEntity, EntityTag = e.GameEntity, e.EntityTag

---@class LevelBackground: GameEntity
---@field new fun():LevelBackground
---@field draw fun(self)
local LevelBackground = {}
setmetatable(LevelBackground, {
  __index = GameEntity
})

function LevelBackground.new()
  local instance = {
    tags = {EntityTag.BACKGROUD_GRID},
    displayLayer = -1
  }
  setmetatable(instance, {
    __index = LevelBackground
  })
  return instance
end

function LevelBackground:draw()
  local blue = true -- which color to draw
  for x = 0, 1500, 300 do
    for y = 0, 900, 300 do
      if blue then
        love.graphics.setColor(love.math.colorFromBytes(133, 218, 235))
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