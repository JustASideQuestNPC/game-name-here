-- enemy that charges up a wave of energy before launching it at the player

local HC      = require "hardonCollider"
local Sprite  = require "lib.sprite"
local Vector2 = require "lib.vector2"
local engine  = require "lib.engine"
local utils   = require "lib.utils"
local config  = require("_gameConfig").entities.waveLauncherEnemy
local temp    = require "lib.gameEntity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

local TURN_SPEED = math.rad(config.turnSpeed)
local MOVE_SPEED = config.moveSpeed
local ACCELERATION = config.acceleration
local MIN_DISTANCE = config.minDistance
local MAX_DISTANCE = config.maxDistance

local WAVE_CHARGE_TIME = config.waveChargeTime
local WAVE_COOLDOWN = config.waveCooldown
local LEAD_TARGETS = config.leadTargets

local PROJECTILE_MAX_VELOCITY = config.projectileMaxVelocity
local PROJECTILE_ACCELERATION = config.projectileAcceleration

local a = PROJECTILE_MAX_VELOCITY / PROJECTILE_ACCELERATION
local b = PROJECTILE_ACCELERATION / 2
local c = (PROJECTILE_MAX_VELOCITY / 2) * a
local function leadTime(distance)
  -- this equation took me three hours lmao
  if distance <= 0 then
    return 0
  elseif distance < c then
    return math.sqrt(distance / b)
  else
    return (distance - c) / PROJECTILE_MAX_VELOCITY + a
  end
end

---@class WaveLauncherProjectile: GameEntity
---@field sprite Sprite
---@field position Vector2
---@field velocity Vector2
---@field acceleration Vector2
---@field angle number
---@field trailPoints table[]
local WaveLauncherProjectile = utils.class(
  GameEntity, function(instance, position, angle)
    instance.tags = {EntityTag.ENEMY_PROJECTILE}
    instance.displayLayer = 0

    instance.sprite = Sprite("waveLauncherEnemyProjectile")

    instance.position = position:copy()
    instance.velocity = Vector2()
    instance.acceleration = Vector2.fromPolar(angle, PROJECTILE_ACCELERATION)
    instance.angle = angle

    instance.trailPoints = {}
  end
)

function WaveLauncherProjectile:draw()
  love.graphics.push()
  love.graphics.translate(self.position:coords())
  love.graphics.rotate(self.angle + math.pi / 2)
  self.sprite:draw(0, 0)
  love.graphics.pop()

  for _, pt in ipairs(self.trailPoints) do
    love.graphics.push()
    love.graphics.translate(pt.position:coords())
    love.graphics.rotate(self.angle + math.pi / 2)
    self.sprite:draw(0, 0, pt.time / 0.5)
    love.graphics.pop()
  end
end

function WaveLauncherProjectile:update(dt)
  -- update trail positions
  self.trailPoints[#self.trailPoints+1] = {time=0.25, position=self.position:copy()}
  local filteredPoints = {}
  for _, pt in pairs(self.trailPoints) do
    pt.time = pt.time - dt
    if pt.time > 0 then
      filteredPoints[#filteredPoints+1] = pt
    end
  end
  self.trailPoints = filteredPoints

  self.position = self.position + self.velocity * dt

  if self.velocity:magSq() < PROJECTILE_MAX_VELOCITY ^ 2 then
    self.velocity = self.velocity + self.acceleration * dt
    self.velocity:limit(PROJECTILE_MAX_VELOCITY)
  end

  if self.position.x < -50 or self.position.x > engine.roomWidth() + 50 or
     self.position.y < -50 or self.position.y > engine.roomHeight() + 50 then
    self.markForDelete = true
  end
end

---@class WaveLauncherEnemy: GameEntity
---@field sprite Sprite
---@field waveSprite Sprite
---@field hitbox table
---@field position Vector2
---@field velocity Vector2
---@field angle number
---@field waveState "idle"|"charging"|"cooldown"
---@field waveTimer number
local WaveLauncherEnemy = utils.class(
  GameEntity, function(instance, x, y)
    instance.tags = {EntityTag.ENEMY}
    instance.displayLayer = 1

    instance.sprite = Sprite("waveLauncherEnemyBody")
    instance.waveSprite = Sprite("waveLauncherEnemyProjectile")
    instance.hitbox = HC.polygon(
        0.00,  49.80,
       45.00,  23.82,
       45.00, -28.15,
       33.75, -21.65,
        0.00, -41.14,
      -33.75, -21.65,
      -45.00, -28.15,
      -45.00,  23.82
    )

    instance.position = Vector2(x, y)
    instance.velocity = Vector2()
    instance.angle = 0

    instance.waveState = "cooldown"
    instance.waveTimer = WAVE_COOLDOWN
  end
)

function WaveLauncherEnemy:draw()
  love.graphics.push()
  love.graphics.translate(self.position:coords())
  love.graphics.rotate(self.angle + math.pi / 2)
  self.sprite:draw(0, 0)

  if self.waveState == "charging" then
    self.waveSprite:draw(0, 0, 1 - (self.waveTimer / WAVE_CHARGE_TIME))
  end

  love.graphics.pop()
end

function WaveLauncherEnemy:update(dt)
  self.position = self.position + self.velocity * dt

  local hitboxOffset = Vector2.fromPolar(self.angle, -6)
  local hitboxCenter = self.position + hitboxOffset
  self.hitbox:moveTo(hitboxCenter:coords())
  self.hitbox:setRotation(self.angle + math.pi / 2, hitboxCenter:coords())

  local walls = engine.getTagged(EntityTag.COLLIDES_WITH_ENEMIES)
  for _, wall in ipairs(walls) do
    local collides, dx, dy = self.hitbox:collidesWith(wall.hitbox)
    if collides then
      self.position = self.position + Vector2(dx, dy)
      self.hitbox:moveTo((self.position + hitboxOffset):coords())
    end
  end

  local playerRelativePosition = PlayerEntity.position - self.position

  local targetPos
  if LEAD_TARGETS and self.waveState ~= "cooldown" then
    local t = leadTime(playerRelativePosition:mag())
    targetPos = (PlayerEntity.position + PlayerEntity.velocity * t) - self.position
  else
    targetPos = playerRelativePosition
  end

  -- turn to aim at the target
  local cross = targetPos:cross(Vector2.fromPolar(self.angle, 1))
  local atTargetAngle = true
  if cross ~= 0 then
    atTargetAngle = false
    if cross < 0 then
      self.angle = self.angle + TURN_SPEED * dt
    else
      self.angle = self.angle - TURN_SPEED * dt
    end

    local newCross = targetPos:cross(Vector2.fromPolar(self.angle, 1))
    if (cross < 0 and newCross > 0) or (cross > 0 and newCross < 0) then
      self.angle = targetPos:angle()
      atTargetAngle = true
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

  -- update wave 
  if self.waveState == "cooldown" then
    self.waveTimer = self.waveTimer - dt
    if self.waveTimer <= 0 then
      self.waveState = "idle"
    end
  elseif self.waveState == "idle" then
    if atTargetAngle then
      self.waveState = "charging"
      self.waveTimer = WAVE_CHARGE_TIME
    end
  else -- self.waveState == "charging"
    self.waveTimer = self.waveTimer - dt
    if self.waveTimer <= 0 then
      engine.addEntity(WaveLauncherProjectile(self.position, self.angle))
      self.waveState = "cooldown"
      self.waveTimer = WAVE_COOLDOWN
    end
  end
end

return WaveLauncherEnemy