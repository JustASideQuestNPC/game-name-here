-- Class for loading and rendering image sprites.
local utils = require "lib.utils"

---@alias Image table not actually a table but it keeps my linter happy

---@type table<string, string> File paths for all sprite names.
local SPRITE_PATHS = {
  player = "assets/entities/player/player.png",
  waveLauncherEnemyBody = "assets/entities/waveLauncherEnemy/body.png",
  waveLauncherEnemyProjectile = "assets/entities/waveLauncherEnemy/projectile.png"
}

---@type table<string, Image> All currently loaded images.
local spriteImages = {}

---@class Sprite: Class
---@field image Image
---@field width integer
---@field height integer
---@field xAlign ("left"|"center"|"right")
---@field yAlign ("top"|"center"|"bottom")
---@field xOffset number
---@field yOffset number
---@field new fun(name: string): Sprite
---@field setAlign fun(self, xAlign: string, yAlign: string)
---@field draw fun(self, x: number, y: number, transparency: number?, scale: number?)
local Sprite = utils.class(
  function (instance, name, fromPath, defaultPath)
    -- if the image is loaded, grab a reference to it
    if spriteImages[name] ~= nil then
      instance.image = spriteImages[name]
      -- Console.verboseLog("Image for sprite \""..name.."\" is already loaded, referencing it.")
    else
      -- throw an error if the sprite name doesn't exist
      if SPRITE_PATHS[name] == nil and not fromPath then
        if love.filesystem.getInfo(defaultPath) then
          instance.image = love.graphics.newImage(defaultPath)
          spriteImages[defaultPath] = instance.image
          Console.verboseLog("Loaded image for sprite \""..name.."\" from default path \""..
              defaultPath.."\"")
        else
          error("The sprite \""..name.."\" has no associated path!")
        end
      else
        local path
        if fromPath then
          path = name
        else
          path = SPRITE_PATHS[name]
        end

        if love.filesystem.getInfo(path) then
          instance.image = love.graphics.newImage(path)
          spriteImages[name] = instance.image
          Console.verboseLog("Loaded image for sprite \""..name.."\" from path \""..path.."\"")
        else
          -- throw an error if the image doesn't exist
          error("The image \""..path.."\" does not exist (or could not be opened)!")
        end
      end
    end

    -- sprites default to being center aligned
    instance.width, instance.height = instance.image:getDimensions()
    instance.xAlign = "center" -- horizontal alignment edge
    instance.yAlign = "center" -- vertical alignment edge
    instance.xOffset = -instance.width / 2
    instance.yOffset = -instance.height / 2
  end
)

function Sprite:setAlign(xAlign, yAlign)
  self.xAlign = xAlign
  self.yAlign = yAlign

  if xAlign == "left" then
    self.xOffset = 0
  elseif xAlign == "center" then
    self.xOffset = -self.width / 2
  else
    self.xOffset = -self.width
  end

  if yAlign == "top" then
    self.yOffset = 0
  elseif yAlign == "center" then
    self.yOffset = -self.height / 2
  else
    self.yOffset = -self.height
  end
end

function Sprite:draw(x, y, transparency, scale)
  if transparency == nil then
    transparency = 1
  end
  scale = scale or 1

  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.scale(scale)
  -- apparently color affects images for some reason
  love.graphics.setColor(1, 1, 1, transparency)
  love.graphics.draw(self.image, self.xOffset, self.yOffset)
  love.graphics.pop()
end

return Sprite