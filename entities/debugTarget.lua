local utils   = require "lib.utils"
local engine  = require "lib.engine"
local temp    = require "lib.gameEntity"
local Vector2 = require "lib.vector2"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

---@class DebugTarget: GameEntity
local DebugTarget = utils.class(
  GameEntity, function(instance, x, y)
    instance.tags = {EntityTag.AIM_ASSIST_TARGET}
    instance.displayLayer = 1

    instance.position = Vector2(x, y)
  end
)

function DebugTarget:draw()
  local pink = true
  local r = 40
  while r > 0 do
    if pink then
      love.graphics.setColor(love.math.colorFromBytes(202, 96, 174))
    else
      love.graphics.setColor(1, 1, 1)
    end

    love.graphics.circle("fill", self.position.x, self.position.y, r)
    r = r - 10
    pink = not pink
  end
end

return DebugTarget