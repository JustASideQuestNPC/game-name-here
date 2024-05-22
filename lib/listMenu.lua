local utils = require "lib.utils"
local input = require "lib.input"

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
---@field descriptionFont table
---@field descriptionColor table
---@field optionLineHeight number
---@field optionListHeight number
---@field optionListOffset number
---@field titleOffset number
---@field selectorButtonScale number
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
    instance.descriptionFont = args.descriptionFont
    instance.descriptionColor = args.descriptionColor

    instance.optionLineHeight = (instance.optionsFont:getAscent() +
        instance.optionsFont:getDescent()) * args.optionsLineSpacing
    instance.optionListHeight = instance.optionLineHeight * #instance.options

    instance.selectorButtonScale = instance.optionLineHeight / 72

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
      option.hovered = false

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
      elseif option.type == "selector" then
        option.selectedValue = option.values[option.selectedIndex]
        option.hoveredButton = "left"

        -- add the selector width to the line
        local valueWidth = -1
        for _, value in ipairs(option.values) do
          local vw = instance.optionsFont:getWidth(value[2])
          if vw > valueWidth then
            valueWidth = vw
          end
        end
        local buttonOffset = (valueWidth * 1.1) / 2 + 12 * instance.selectorButtonScale
        local selectorWidth = valueWidth * 1.1 + (80 * instance.selectorButtonScale)

        local textWidth = instance.optionsFont:getWidth(option.text)
        local totalWidth = selectorWidth + textWidth + 75 * instance.selectorButtonScale

        option.textX = textWidth / 2 - totalWidth / 2
        option.valueX = totalWidth / 2 - selectorWidth / 2

        option.leftButtonX = option.valueX - buttonOffset
        option.rightButtonX = option.valueX + buttonOffset

        option.leftButtonBox = {
          x = option.leftButtonX - 20 * instance.selectorButtonScale,
          y = yPos - 6 * instance.selectorButtonScale,
          w = 40 * instance.selectorButtonScale,
          h = 50 * instance.selectorButtonScale
        }
        option.rightButtonBox = {
          x = option.rightButtonX - 20 * instance.selectorButtonScale,
          y = yPos - 6 * instance.selectorButtonScale,
          w = 40 * instance.selectorButtonScale,
          h = 50 * instance.selectorButtonScale
        }

        option.bbox.w = totalWidth
        option.bbox.x = -option.bbox.w / 2
      elseif option.type == "image" then
        option.bbox.w = option.bbox.w + option.spacing + option.image.width * option.imageScale
        option.bbox.x = -option.bbox.w / 2
        option.bbox.y = option.bbox.y
      end

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
      if option.type == "selector" then
        local leftHovered = input.mouseOver(
          (self.x + option.leftButtonBox.x) * DisplayScale,
          (self.y + option.leftButtonBox.y) * DisplayScale,
          (option.leftButtonBox.w) * DisplayScale,
          (option.leftButtonBox.h) * DisplayScale
        )
        local rightHovered = input.mouseOver(
          (self.x + option.rightButtonBox.x) * DisplayScale,
          (self.y + option.rightButtonBox.y) * DisplayScale,
          (option.rightButtonBox.w) * DisplayScale,
          (option.rightButtonBox.h) * DisplayScale
        )

        option.hovered = leftHovered or rightHovered
        if option.hovered then
          self.hoveredOption = option
          self.gamepadSelectedOption = i
          if leftHovered then
            option.hoveredButton = "left"
          else
            option.hoveredButton = "right"
          end
        end
      else
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

  -- check for menu inputs
  if self.hoveredOption == nil then return end -- reduces nesting
  if self.hoveredOption.type == "toggle" then
    if input.isActive("menu confirm") then
      self.hoveredOption.value = not self.hoveredOption.value
    end
  elseif self.hoveredOption.type == "selector" then
    local side = "none"
    if input.currentInputType() == "keyboard" and input.isActive("menu confirm") then
      side = self.hoveredOption.hoveredButton
    elseif input.isActive("menu left") then
      side = "left"
    elseif input.isActive("menu right") then
      side = "right"
    end

    if side == "left" then
      self.hoveredOption.selectedIndex = self.hoveredOption.selectedIndex - 1
      if self.hoveredOption.selectedIndex == 0 then
        self.hoveredOption.selectedIndex = #self.hoveredOption.values
      end
      self.hoveredOption.selectedValue = self.hoveredOption.values[self.hoveredOption.selectedIndex]
    elseif side == "right" then
      self.hoveredOption.selectedIndex = self.hoveredOption.selectedIndex + 1
      if self.hoveredOption.selectedIndex > #self.hoveredOption.values then
        self.hoveredOption.selectedIndex = 1
      end
      self.hoveredOption.selectedValue = self.hoveredOption.values[self.hoveredOption.selectedIndex]
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
    utils.drawTextCentered(self.title, self.titleFont, 0, 0)
    love.graphics.pop()
  end

  love.graphics.translate(0, self.optionListOffset)

  local describedOption = nil
  for i, option in ipairs(self.options) do
    local yPos = -self.optionListHeight / 2 + (i - 1) * self.optionLineHeight
    local hovered = (input.currentInputType() == "keyboard" and option.hovered) or
        (input.currentInputType() == "gamepad" and i == self.gamepadSelectedOption)

    if option.type ~= "selector" then
      if hovered then
        love.graphics.setColor(self.optionsHoverColor)
      else
        love.graphics.setColor(self.optionsColor)
      end
    end

    if option.type == "text" then
      utils.drawTextCentered(option.text, self.optionsFont, 0, yPos)
    elseif option.type == "toggle" then
      utils.drawTextCentered(option.text, self.optionsFont, -52, yPos)

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
    elseif option.type == "selector" then
      if input.mouseOver(
        (self.x + option.bbox.x) * DisplayScale,
        (self.y + option.bbox.y) * DisplayScale,
        (option.bbox.w) * DisplayScale,
        (option.bbox.h) * DisplayScale
      ) then
        describedOption = option
      end

      local colorAll = false
      local colorLeft = false
      local colorRight = false
      if hovered then
        if input.currentInputType() == "gamepad" then
          colorAll = true
        else
          if option.hoveredButton == "left" then
            colorLeft = true
          else
            colorRight = true
          end
        end
      end

      love.graphics.setColor(self.optionsColor)
      utils.drawTextCentered(option.text, self.optionsFont, option.textX, yPos)
      utils.drawTextCentered(option.selectedValue[2], self.optionsFont, option.valueX, yPos)

      -- draw selector buttons
      if colorLeft or colorAll then
        love.graphics.setColor(self.optionsHoverColor)
      else
        love.graphics.setColor(self.optionsColor)
      end
      love.graphics.push()
      love.graphics.translate(option.leftButtonX + 12 * self.selectorButtonScale,
          yPos + self.optionLineHeight / 4)
      love.graphics.scale(self.selectorButtonScale * 0.9)
      love.graphics.rotate(-math.pi / 4)

      love.graphics.rectangle("fill", -20, -20, 30, 7)
      love.graphics.rectangle("fill", -20, -20, 7, 30)
      love.graphics.pop()

      if colorRight or colorAll then
        love.graphics.setColor(self.optionsHoverColor)
      else
        love.graphics.setColor(self.optionsColor)
      end
      love.graphics.push()
      love.graphics.translate(option.rightButtonX - 12 * self.selectorButtonScale,
          yPos + self.optionLineHeight / 4)
      love.graphics.scale(self.selectorButtonScale * 0.9)
      love.graphics.rotate(math.pi - math.pi / 4)

      love.graphics.rectangle("fill", -20, -20, 30, 7)
      love.graphics.rectangle("fill", -20, -20, 7, 30)
      love.graphics.pop()
    elseif option.type == "image" then
      utils.drawImageTooltipCentered(option.image, option.imageScale, option.text, self.optionsFont,
          option.spacing, 0, yPos + self.optionLineHeight / 4, true)
    end
  end

  love.graphics.pop()

  describedOption = self.hoveredOption or describedOption
  if describedOption ~= nil and describedOption.description ~= "" then
    love.graphics.push()
    love.graphics.translate(love.graphics.getPixelWidth() / 2, love.graphics.getPixelHeight() - 125)
    love.graphics.scale(DisplayScale)

    love.graphics.setColor(self.descriptionColor)
    utils.drawTextCentered(describedOption.description, self.descriptionFont, 0, 0)

    love.graphics.pop()
  end

  if DEBUG_CONFIG.SHOW_HITBOXES then
    love.graphics.setColor(love.math.colorFromBytes(94, 253, 247))
    for _, option in ipairs(self.options) do
      love.graphics.setLineWidth(2)
      if option.type == "selector" then
        love.graphics.rectangle("line",
          (self.x + option.leftButtonBox.x) * DisplayScale,
          (self.y + option.leftButtonBox.y) * DisplayScale,
          (option.leftButtonBox.w) * DisplayScale,
          (option.leftButtonBox.h) * DisplayScale
        )
        love.graphics.rectangle("line",
          (self.x + option.rightButtonBox.x) * DisplayScale,
          (self.y + option.rightButtonBox.y) * DisplayScale,
          (option.rightButtonBox.w) * DisplayScale,
          (option.rightButtonBox.h) * DisplayScale
        )
      end
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