local HC      = require "hardonCollider"
local Sprite  = require "lib.sprite"
local Vector2 = require "lib.vector2"
local utils   = require "lib.utils"
local config  = require("_gameConfig").entities.chaseEnemy
local temp    = require "lib.gameEntity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

local TURN_SPEED = math.rad(config.turnSpeed)
local MOVE_SPEED = config.moveSpeed

---@class ChaseEnemy: GameEntity
---@field sprite Sprite
---@field hitbox table
---@field position Vector2
---@field velocity Vector2
---@field angle number
local ChaseEnemy = utils.class(
  GameEntity, function(instance, x, y)
  -- add a bit of randomness to prevent issues if two enemies are spawned at exactly the same
    -- position on exactly the same frame (this happens when using console commands)
    x = x + utils.randFloat(-10, 10)
    y = y + utils.randFloat(-10, 10)

    instance.tags = {EntityTag.ENEMY}
    instance.displayLayer = 1

    instance.sprite = Sprite("chaseEnemyBody")
    instance.hitbox = HC.polygon(
         17.12, -20.00,
         21.69, -12.07,
          0.00,  40.00,
        -21.69, -12.07,
        -17.12, -20.00
    )

    instance.position = Vector2(x, y)
    instance.velocity = Vector2(0, MOVE_SPEED)
    instance.angle = 0
  end
)

function ChaseEnemy:draw()
  love.graphics.push()
  love.graphics.translate(self.position:coords())
  love.graphics.rotate(self.angle - math.pi / 2)
  self.sprite:draw(0, 0)
  love.graphics.pop()
end

function ChaseEnemy:update(dt)
  self.position = self.position + self.velocity * dt

  self.hitbox:moveTo(self.position:coords())
  self.hitbox:setRotation(self.angle - math.pi / 2, self.position:coords())

  -- aim at the player
  local targetPos = PlayerEntity.position - self.position
  local cross = targetPos:cross(Vector2.fromPolar(self.angle, 1))
  if cross ~= 0 then
    if cross < 0 then
      self.angle = self.angle + TURN_SPEED * dt
    else
      self.angle = self.angle - TURN_SPEED * dt
    end

    local newCross = targetPos:cross(Vector2.fromPolar(self.angle, 1))
    if (cross < 0 and newCross > 0) or (cross > 0 and newCross < 0) then
      self.angle = targetPos:angle()
    end
  end

  self.velocity:setAngle(self.angle)
end

return ChaseEnemy