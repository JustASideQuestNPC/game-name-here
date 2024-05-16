local utils = require "lib.utils"

local function drawTextCentered(text, font, x, y)
  local width = font:getWidth(text)
  local height = font:getAscent() + font:getDescent()

  love.graphics.print(text, x - width / 2, y - height / 2)
end

---@class ListMenu: Class
---@field title string
---@field titleFont table
---@field titleColor table
---@field options table[]
---@field optionsFont table
---@field optionsColor table
---@field optionLineHeight number
---@field optionListHeight number
---@field optionListOffset number
---@field titleOffset number
---@field update fun(self)
---@field draw fun(self, x: number, y: number, scale: number)
local ListMenu = utils.class(
  function (instance, args)
    instance.title = args.title
    instance.titleFont = args.titleFont
    instance.titleColor = args.titleColor
    instance.options = args.options
    instance.optionsFont = args.optionsFont
    instance.optionsColor = args.optionsColor

    instance.optionLineHeight = (instance.optionsFont:getAscent() +
        instance.optionsFont:getDescent()) * args.optionsLineSpacing
    instance.optionListHeight = instance.optionLineHeight * #instance.options

    if instance.title ~= "" then
      local titleHeight = (instance.titleFont:getAscent() + instance.titleFont:getDescent())
      local totalHeight = instance.optionListHeight + titleHeight + args.titleOffset
      instance.titleOffset = -totalHeight / 2
      instance.optionListOffset = totalHeight / 2 - instance.optionListHeight / 2
    else
      instance.titleOffset = 0
      instance.optionListOffset = 0
    end
  end
)

function ListMenu:update()

end

function ListMenu:draw(x, y, scale)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.scale(scale)

  if self.title ~= "" then
    love.graphics.push()
    love.graphics.translate(0, self.titleOffset)

    love.graphics.setColor(self.titleColor)
    love.graphics.setFont(self.titleFont)
    drawTextCentered(self.title, self.titleFont, 0, 0)
    love.graphics.pop()
  end

  love.graphics.translate(0, self.optionListOffset)
  love.graphics.setColor(self.optionsColor)
  love.graphics.setFont(self.optionsFont)

  for i, option in ipairs(self.options) do
    local yPos = -self.optionListHeight / 2 + (i - 1) * self.optionLineHeight
    drawTextCentered(option.text, self.optionsFont, 0, yPos)
  end

  love.graphics.pop()
end

return ListMenu