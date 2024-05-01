-- Class for loading and rendering image sprites.
local utils = require "lib.utils"

---@alias Image table not actually a table but it keeps my linter happy

---@type table<string, string> File paths for all sprite names.
local SPRITE_PATHS = {
  ["player"] = "assets/player.png"
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
---@field draw fun(self, x: number, y: number)
local Sprite = utils.class(
  function (instance, name)
    -- if the image is loaded, grab a reference to it
    if spriteImages[name] ~= nil then
      instance.image = spriteImages[name]
    else
      -- throw an error if the sprite name doesn't exist
      if SPRITE_PATHS[name] == nil then
        error("The sprite \""..name.."\" has no associated path!")
      else
        local path = SPRITE_PATHS[name]
        if love.filesystem.getInfo(path) then
          instance.image = love.graphics.newImage(path)
        else
          -- throw an error if the image doesn't exist
          error("The image \""..path.."\" does not exist!")
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

function Sprite:draw(x, y)
  -- apparently color affects images for some reason
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image, x + self.xOffset, y + self.yOffset)
end

return Sprite