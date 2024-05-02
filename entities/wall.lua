-- Basic wall.

local HC    = require "hardon-collider"
local utils = require "lib.utils"
local temp  = require "lib.game-entity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

---@class Wall: GameEntity
---@field x number
---@field y number
---@field width number
---@field height number
---@field hitbox table
local Wall = utils.class(
  GameEntity, function (instance, x, y, w, h)
    instance.tags = {EntityTag.WALL}
    instance.displayLayer = 2

    instance.x = x
    instance.y = y
    instance.width = w
    instance.height = h

    instance.hitbox = HC.rectangle(x, y, w, h)
  end
)

function Wall:draw()
  love.graphics.setColor(love.math.colorFromBytes(50, 49, 59))
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return Wall