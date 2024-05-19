local utils = require "lib.utils"
local input = require "lib.input"

local function drawTextCentered(text, font, x, y)
  local width = font:getWidth(text)
  local height = font:getAscent() + font:getDescent()

  love.graphics.print(text, x - width / 2, y - height / 2)
end

---@class ListMenu: Class
---@field x number
---@field y number
---@field title string
---@field titleFont table
---@field titleColor table
---@field options table[]
---@field optionsFont table
---@field optionsColor table
---@field optionsHoverColor table
---@field optionLineHeight number
---@field optionListHeight number
---@field optionListOffset number
---@field titleOffset number
---@field hoveredOption table
---@field gamepadSelectedOption number
---@field update fun(self)
---@field draw fun(self)
local ListMenu = utils.class(
  function (instance, args)
    instance.x = args.pos[1]
    instance.y = args.pos[2]
    instance.scale = args.scale

    instance.title = args.title
    instance.titleFont = args.titleFont
    instance.titleColor = args.titleColor
    instance.options = args.options
    instance.optionsFont = args.optionsFont
    instance.optionsColor = args.optionsColor
    instance.optionsHoverColor = args.optionsHoverColor

    instance.optionLineHeight = (instance.optionsFont:getAscent() +
        instance.optionsFont:getDescent()) * args.optionsLineSpacing
    instance.optionListHeight = instance.optionLineHeight * #instance.options

    if instance.title ~= nil and instance.title ~= "" then
      local titleHeight = (instance.titleFont:getAscent() + instance.titleFont:getDescent())
      local totalHeight = instance.optionListHeight + titleHeight + args.titleOffset
      instance.titleOffset = -totalHeight / 2
      instance.optionListOffset = totalHeight / 2 - instance.optionListHeight / 2
    else
      instance.titleOffset = 0
      instance.optionListOffset = 0
    end

    -- generate option data
    for i, option in ipairs(instance.options) do
      local yPos = -instance.optionListHeight / 2 + (i - 1) * instance.optionLineHeight
      local w = instance.optionsFont:getWidth(option.text) * 1.1
      option.bbox = {
        x = -w / 2,
        y = yPos + instance.optionListOffset - instance.optionLineHeight / 4,
        w = w,
        h = instance.optionLineHeight
      }

      if option.type == "toggle" then
        option.switchOffset = option.bbox.w / 2.3
        option.bbox.w = option.bbox.w + 90
        option.bbox.x = -option.bbox.w / 2 + 5
      end

      option.hovered = false

      if option.description == nil then option.description = "" end
    end

    instance.hoveredOption = nil
    instance.gamepadSelectedOption = 1
  end
)

function ListMenu:update()
  if input.currentInputType() == "keyboard" then
    self.hoveredOption = nil
    for i, option in ipairs(self.options) do
      option.hovered = input.mouseOver(
        (self.x + option.bbox.x) * DisplayScale,
        (self.y + option.bbox.y) * DisplayScale,
        (option.bbox.w) * DisplayScale,
        (option.bbox.h) * DisplayScale
      )

      if option.hovered then
        self.hoveredOption = option
        self.gamepadSelectedOption = i
      end
    end
  else
    local menuDir = input.getDpadVector("menu up", "menu down", "menu left", "menu right", true)
    if menuDir.y < 0 then
      self.gamepadSelectedOption = self.gamepadSelectedOption - 1
      if self.gamepadSelectedOption == 0 then
        self.gamepadSelectedOption = #self.options
      end
    elseif menuDir.y > 0 then
      self.gamepadSelectedOption = self.gamepadSelectedOption + 1
      if self.gamepadSelectedOption > #self.options then
        self.gamepadSelectedOption = 1
      end
    end

    self.hoveredOption = self.options[self.gamepadSelectedOption]
  end

  if input.isActive("menu confirm") and self.hoveredOption ~= nil then
    if self.hoveredOption.type == "toggle" then
      self.hoveredOption.value = not self.hoveredOption.value
    end
  end
end

function ListMenu:draw()
  love.graphics.push()
  love.graphics.scale(DisplayScale)
  love.graphics.translate(self.x, self.y)

  if self.title ~= nil and self.title ~= "" then
    love.graphics.push()
    love.graphics.translate(0, self.titleOffset)

    love.graphics.setColor(self.titleColor)
    love.graphics.setFont(self.titleFont)
    drawTextCentered(self.title, self.titleFont, 0, 0)
    love.graphics.pop()
  end

  love.graphics.translate(0, self.optionListOffset)
  love.graphics.setFont(self.optionsFont)

  for i, option in ipairs(self.options) do
    local yPos = -self.optionListHeight / 2 + (i - 1) * self.optionLineHeight
    if (input.currentInputType() == "keyboard" and option.hovered) or
       (input.currentInputType() == "gamepad" and i == self.gamepadSelectedOption) then
      love.graphics.setColor(self.optionsHoverColor)
    else
      love.graphics.setColor(self.optionsColor)
    end

    if option.type == "text" then
      drawTextCentered(option.text, self.optionsFont, 0, yPos)
    elseif option.type == "toggle" then
      drawTextCentered(option.text, self.optionsFont, -52, yPos)

      local yOffset = self.optionLineHeight / 4
      local xOffset = option.switchOffset
      local size = self.optionLineHeight / 3

      love.graphics.setColor(option.outlineColor)
      love.graphics.circle("fill", xOffset, yPos + yOffset, size)
      love.graphics.circle("fill", xOffset + size * 1.5, yPos + yOffset, size)
      love.graphics.rectangle("fill", xOffset, yPos - yOffset / 3, size * 1.5, size * 2)

      if option.value then
        love.graphics.setColor(option.trueColor)
      else
        love.graphics.setColor(option.falseColor)
      end

      love.graphics.circle("fill", xOffset, yPos + yOffset, size * 0.75)
      love.graphics.circle("fill", xOffset + size * 1.5, yPos + yOffset, size * 0.75)
      love.graphics.rectangle("fill", xOffset, yPos, size * 1.5, size * 1.5)

      love.graphics.setColor(self.optionsHoverColor)
      if option.value then
        love.graphics.circle("fill", xOffset + size * 1.5, yPos + yOffset, size * 0.75)
      else
        love.graphics.circle("fill", xOffset, yPos + yOffset, size * 0.75)
      end
    end
  end

  love.graphics.pop()

  if DEBUG_CONFIG.SHOW_HITBOXES then
    love.graphics.setColor(love.math.colorFromBytes(94, 253, 247))
    for _, option in ipairs(self.options) do
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line",
        (self.x + option.bbox.x) * DisplayScale,
        (self.y + option.bbox.y) * DisplayScale,
        (option.bbox.w) * DisplayScale,
        (option.bbox.h) * DisplayScale
      )
    end
  end
end

return ListMenu