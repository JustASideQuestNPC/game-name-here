-- Base class for all game entities to inherit from
local utils = require "lib.utils"

---@enum EntityTag
local EntityTag = {
  USES_RAW_DELTA_TIME = 0,
  USES_SCREEN_SPACE_COORDS = 1,

  LEVEL_BACKGROUND = 2,
  PLAYER = 3,
  WALL = 4,
  PLAYER_BULLET = 5,
  HUD = 6,
  ENEMY = 7,
  COLLIDES_WITH_ENEMIES = 8,
  ENEMY_PROJECTILE = 9,
  AIM_ASSIST_TARGET = 10
}

---@class GameEntity: Class
---@field tags EntityTag[]
---@field displayLayer integer
---@field deleted boolean
---@field markForDelete boolean
---@field hitbox table|nil
---@field position Vector2
---@field new fun(): GameEntity
---@field update fun(self, dt: number)
---@field draw fun(self)
---@field drawHitbox fun(self)
---@field setup fun(self)
---@field delete fun(self)
---@field hasTag fun(self, tag: EntityTag): boolean
---@field takeDamage fun(self, dmg: number)
local GameEntity = utils.class()

---Called once per frame in update(), and is passed the current delta time. This base class method
---does nothing and must be overriden.
---@param dt number
function GameEntity:update(dt) end

---Called once per frame in draw(). This base class method does nothing and must be overriden.
function GameEntity:draw() end

function GameEntity:drawHitbox()
  if self.hitbox ~= nil then
    love.graphics.setColor(love.math.colorFromBytes(94, 253, 247))
    love.graphics.setLineWidth(2)
    self.hitbox:draw("line")
  end
end

---Called once when the entity is added to the game engine. This base class method does nothing and
---must be overriden.
function GameEntity:setup() end

---Called once when the entity is removed from the game engine at the end of an update cycle. This
---base class method does nothing and must be overriden.
function GameEntity:delete() end

---Returns whether the entity has the specified tag.
---@param tag EntityTag
---@return boolean
function GameEntity:hasTag(tag)
  return utils.arrayFind(self.tags, tag) ~= 0
end

---Called once when damage is dealt to the entity, and is passed the amount of damage dealt. This
---base class method does nothing and must be overriden.
---@param dmg number
function GameEntity:takeDamage(dmg) end

return {
  GameEntity = GameEntity,
  EntityTag = EntityTag
}