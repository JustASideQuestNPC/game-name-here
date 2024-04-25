-- Base class for all game entities to inherit from
local utils = require "lib.utils"

---@enum EntityTag
local EntityTag = {
  USES_RAW_DELTA_TIME = 0, -- Entity always recieves the raw delta time regardless of multiplier.
  USES_SCREEN_SPACE_COORDS = 1, -- Entity ignores camera position when being drawn.

  BACKGROUND_GRID = 2 -- Level/room background.
}

---@class GameEntity
---@field tags EntityTag[]
---@field displayLayer integer
---@field deleted boolean
---@field markForDelete boolean
---@field update fun(self, dt: number)
---@field draw fun(self)
---@field setup fun(self)
---@field delete fun(self)
---@field hasTag fun(self, tag: EntityTag): boolean
local GameEntity = {}

---Called once per frame in update(), and is passed the current delta time. This base class method
---does nothing and must be overriden.
---@param dt number
function GameEntity:update(dt) end

---Called once per frame in draw(). This base class method does nothing and must be overriden.
function GameEntity:draw() end

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

---Generates a new class that extends GameEntity.
---@param tags? EntityTag[]
---@param displayLayer? integer
---@return table
local function EntityClass(tags, displayLayer)
  local class = {
    tags = tags or {},
    displayLayer = displayLayer or 0
  }
  setmetatable(class, {
    __index = GameEntity
  })
  return class
end

return {
  GameEntity = GameEntity,
  EntityTag = EntityTag,
  EntityClass = EntityClass
}