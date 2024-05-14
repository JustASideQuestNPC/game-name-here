-- enemy that charges up a wave of energy before launching it at the player

local HC      = require "hardonCollider"
local Sprite  = require "lib.sprite"
local Vector2 = require "lib.vector2"
local utils   = require "lib.utils"
local temp    = require "lib.gameEntity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

---@class WaveLauncherEnemy: GameEntity
---@field sprite Sprite
---@field waveSprite Sprite
---@field hitbox table
---@field position Vector2
---@field angle number
local WaveLauncherEnemy = utils.class(
  GameEntity, function (instance, x, y)
    instance.tags = {EntityTag.ENEMY}
    instance.displayLayer = 1

    instance.sprite = Sprite("waveLauncherEnemyBody")
    instance.waveSprite = Sprite("waveLauncherEnemyProjectile")
    instance.hitbox = HC.polygon(
      0, 34.5,
      30, 17.18,
      30, -17.461,
      22.5, -13.131,
      0, -26.121,
      -22.5, -13.131,
      -30, -17.461,
      -30, 17.18
    )

    instance.position = Vector2(x, y)
    instance.angle = 0
  end
)

function WaveLauncherEnemy:draw()
  love.graphics.push()
  love.graphics.translate(self.position:coords())
  love.graphics.rotate(self.angle + math.pi / 2)
  self.sprite:draw(0, 0)
  -- self.waveSprite:draw(0, 0)

  love.graphics.pop()

  -- if DEBUG_CONFIG.SHOW_HITBOXES then
  --   love.graphics.setColor(love.math.colorFromBytes(94, 253, 247))
  --   love.graphics.setLineWidth(2)
  --   self.hitbox:draw("line")
  -- end
end

function WaveLauncherEnemy:update()
  local delta = PlayerEntity.position - self.position
  self.angle = delta:angle()

  local hitboxCenter = Vector2.fromPolar(self.angle, -4) + self.position
  self.hitbox:moveTo(hitboxCenter:coords())
  self.hitbox:setRotation(self.angle + math.pi / 2, hitboxCenter:coords())
  -- print(self.hitbox:center())
end

return WaveLauncherEnemy