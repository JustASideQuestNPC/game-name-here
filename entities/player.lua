-- Player character.

local config  = require "_config"
local utils   = require "lib.utils"
local input   = require "lib.input-manager"
local Vector2 = require "lib.vector2"
local engine  = require "lib.engine"
local temp    = require "lib.game-entity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

local INVERT_THUMBSTICKS = config.input.invertThumbsticks
local RUN_SPEED = config.entities.player.runSpeed

---@class Player: GameEntity
---@field position Vector2
---@field velocity Vector2
---@field new fun(x: number, y: number): Player
---@field update fun(self, dt: number)
---@field draw fun(self)
local Player = utils.class(
  GameEntity, function (instance, x, y)
    instance.tags = {EntityTag.PLAYER}
    instance.displayLayer = -1
    instance.position = Vector2(x, y)
    instance.velocity = Vector2(0, 0)
  end
)

function Player:draw()
  love.graphics.push()
  -- makes (0, 0) our current position
  love.graphics.translate(self.position.x, self.position.y)

  -- placeholder sprite
  love.graphics.setColor(love.math.colorFromBytes(50, 49, 59))
  love.graphics.circle("fill", 0, 0, 35)

  love.graphics.pop()
end

function Player:update(dt)
  -- move at the beginning of the update to prevent some issues with collisions
  self.position = self.position + self.velocity * dt
  engine.setCameraTarget(self.position)

  -- find what direction (if any) we're moving and looking
  local moveDir
  if input.currentInputType() == "gamepad" then
    if INVERT_THUMBSTICKS then
      moveDir = input.getStickVector("right")
    else
      moveDir = input.getStickVector("left")
    end
  else
    moveDir = input.getDpadVector("move up", "move down", "move left", "move right")
  end

  if moveDir:magSq() > 0 then
    self.velocity = moveDir
    self.velocity:setMag(RUN_SPEED)
  else
    self.velocity = Vector2()
  end
end

return Player