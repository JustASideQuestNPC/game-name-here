-- enemy that charges up a wave of energy before launching it at the player

local HC      = require "hardonCollider"
local Sprite  = require "lib.sprite"
local Vector2 = require "lib.vector2"
local utils   = require "lib.utils"
local config  = require("_gameConfig").entities.waveLauncherEnemy
local temp    = require "lib.gameEntity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

local TURN_SPEED = math.rad(config.turnSpeed)
local MOVE_SPEED = config.moveSpeed
local ACCELERATION = config.acceleration
local MIN_DISTANCE = config.minDistance
local MAX_DISTANCE = config.maxDistance

---@class WaveLauncherEnemy: GameEntity
---@field sprite Sprite
---@field waveSprite Sprite
---@field hitbox table
---@field position Vector2
---@field velocity Vector2
---@field angle number
local WaveLauncherEnemy = utils.class(
  GameEntity, function (instance, x, y)
    instance.tags = {EntityTag.ENEMY}
    instance.displayLayer = 1

    instance.sprite = Sprite("waveLauncherEnemyBody")
    instance.waveSprite = Sprite("waveLauncherEnemyProjectile")
    instance.hitbox = HC.polygon(
        0.00,  34.50,
       30.00,  17.18,
       30.00, -17.46,
       22.50, -13.13,
        0.00, -26.12,
      -22.50, -13.13,
      -30.00, -17.46,
      -30.00,  17.18
    )

    instance.position = Vector2(x, y)
    instance.velocity = Vector2()
    instance.angle = 0
  end
)

function WaveLauncherEnemy:draw()
  love.graphics.push()
  love.graphics.translate(self.position:coords())
  love.graphics.rotate(self.angle + math.pi / 2)
  self.sprite:draw(0, 0)
  love.graphics.pop()
end

function WaveLauncherEnemy:update(dt)
  self.position = self.position + self.velocity * dt

  local hitboxOffset = Vector2.fromPolar(self.angle, -4)
  local hitboxCenter = self.position + hitboxOffset
  self.hitbox:moveTo(hitboxCenter:coords())
  self.hitbox:setRotation(self.angle + math.pi / 2, hitboxCenter:coords())

  local walls = Engine.getTagged(EntityTag.COLLIDES_WITH_ENEMIES)
  for _, wall in ipairs(walls) do
    local collides, dx, dy = self.hitbox:collidesWith(wall.hitbox)
    if collides then
      self.position = self.position + Vector2(dx, dy)
      self.hitbox:moveTo((self.position + hitboxOffset):coords())
    end
  end

  local playerRelativePosition = PlayerEntity.position - self.position

  -- turn to aim at the player
  local cross = playerRelativePosition:cross(Vector2.fromPolar(self.angle, 1))
  if cross ~= 0 then
    if cross < 0 then
      self.angle = self.angle + TURN_SPEED * dt
    else
      self.angle = self.angle - TURN_SPEED * dt
    end

    local newCross = playerRelativePosition:cross(Vector2.fromPolar(self.angle, 1))
    if (cross < 0 and newCross > 0) or (cross > 0 and newCross < 0) then
      self.angle = playerRelativePosition:angle()
    end
  end

  -- attempt to stay at mid-range from the player
  local distance = playerRelativePosition:mag()
  local acceleration = Vector2()
  if distance < MIN_DISTANCE then
    acceleration = playerRelativePosition:setMag(-ACCELERATION * dt)
  elseif distance > MAX_DISTANCE then
    acceleration = playerRelativePosition:setMag(ACCELERATION * dt)
  end

  if acceleration:magSq() > 0 then
    self.velocity = self.velocity + acceleration
    self.velocity:limit(MOVE_SPEED)
  else
    self.velocity:setMag(math.max(self.velocity:mag() - ACCELERATION * dt, 0))
  end
end

return WaveLauncherEnemy