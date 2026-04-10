local config = require("src.game_config")
local locales = require("src.locales")
local uiButton = require("src.ui")
local utils = require("src.utils")
local switchStateCallback = nil

local TOP_BAR_HEIGHT = 92

local mapButton = {
    id = "map",
    size = 60,
    icon = "map",
    color = config.colors.button,
    tip = function() return locales.get("tips", "map") end,
    targetState = "home"
}

local hoveredButton = nil

local languageSelector = {
    x = 16,
    y = TOP_BAR_HEIGHT + 16,
    width = nil,
    height = 60,
    leftArrow = {
        x = 0,
        y = 0,
        width = 40,
        height = 40
    },
    rightArrow = {
        x = 0,
        y = 0,
        width = 40,
        height = 40
    },
    currentLanguage = locales.getCurrentLanguage(),
    tip = function() return locales.get("tips", "language_tip") end
}

local languageFont = nil
local arrowFont = nil
local languageChangeCallback = nil

local function reloadFonts()
    uiButton.clearCache()
    languageFont = uiButton.getFont("small")
    arrowFont = love.graphics.newFont("src/font/SymbolsNerdFontMono-Regular.ttf", 20)
end


function load(switchState)
    switchStateCallback = switchState
    uiButton.preloadIcon(mapButton)
    reloadFonts()

    locales.addLanguageChangeCallback("settings_page", function()
        reloadFonts()
        languageSelector.currentLanguage = locales.getCurrentLanguage()
    end)
end

function update(dt)
end

function draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    love.graphics.clear(table.unpack(config.colors.background))
    love.graphics.setColor(table.unpack(config.colors.top_bar))
    love.graphics.rectangle("fill", 0, 0, screenWidth, TOP_BAR_HEIGHT)

    drawMapButton(screenWidth, screenHeight)
    drawLanguageSelector(screenWidth, screenHeight)

    if hoveredButton then
        local mouseX, mouseY = love.mouse.getPosition()
        uiButton.drawTooltip(hoveredButton, mouseX, mouseY)
    end
end

function drawMapButton(screenWidth, screenHeight)
    local buttonX, buttonY = uiButton.calcRightPosition(mapButton, screenWidth, TOP_BAR_HEIGHT)
    uiButton.draw(mapButton, buttonX, buttonY)
end

function keypressed(key)
    if key == "escape" then
        love.mouse.setCursor()
        if switchStateCallback then
            switchStateCallback("home")
        end
    end
end

function mousepressed(x, y, button)
    if button == 1 then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local buttonX, buttonY = uiButton.calcRightPosition(mapButton, screenWidth, TOP_BAR_HEIGHT)

        if uiButton.handleWithTargetState(mapButton, x, y, buttonX, buttonY, switchStateCallback) then
            hoveredButton = nil
            return
        end

        if languageSelector.width then
            if utils.isPointInRect(x, y, languageSelector.leftArrow) then
                local prevLang = locales.getPrevLanguage()
                locales.setLanguage(prevLang)
                languageSelector.currentLanguage = prevLang
                reloadFonts()
                return
            end

            if utils.isPointInRect(x, y, languageSelector.rightArrow) then
                local nextLang = locales.getNextLanguage()
                locales.setLanguage(nextLang)
                languageSelector.currentLanguage = nextLang
                reloadFonts()
                return
            end
        end
    end
end

function mousemoved(x, y, dx, dy)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local buttonX, buttonY = uiButton.calcRightPosition(mapButton, screenWidth, TOP_BAR_HEIGHT)

    if uiButton.isHovered(mapButton, x, y, buttonX, buttonY) then
        hoveredButton = mapButton
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    elseif languageSelector.width then
        local selectorRect = {
            x = languageSelector.x,
            y = languageSelector.y,
            width = languageSelector.width,
            height = languageSelector.height
        }

        if utils.isPointInRect(x, y, selectorRect) then
            hoveredButton = languageSelector
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        elseif utils.isPointInRect(x, y, languageSelector.leftArrow) or
            utils.isPointInRect(x, y, languageSelector.rightArrow) then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            hoveredButton = nil
        else
            hoveredButton = nil
            love.mouse.setCursor()
        end
    else
        hoveredButton = nil
        love.mouse.setCursor()
    end
end

function mousereleased(x, y, button)
end

function wheelmoved(x, y)
end

function drawLanguageSelector(screenWidth, screenHeight)
    languageSelector.width = screenWidth - 32

    local selector = languageSelector
    local x = selector.x
    local y = selector.y
    local width = selector.width
    local height = selector.height

    love.graphics.setColor(table.unpack(config.colors.panel_bg))
    love.graphics.rectangle("fill", x, y, width, height, 8)
    love.graphics.setColor(table.unpack(config.colors.panel_border))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 8)

    local padding = 16
    local arrowWidth = 40
    local arrowHeight = 40
    local languageText = locales.get("tips", "language")
    local languageTextWidth = languageFont:getWidth(languageText)

    love.graphics.setColor(table.unpack(config.colors.text))
    love.graphics.setFont(languageFont)
    love.graphics.print(languageText, x + padding, y + (height - languageFont:getHeight()) / 2)

    local currentLangName = locales.getLanguageName(selector.currentLanguage)
    local langTextWidth = languageFont:getWidth(currentLangName)
    local totalWidth = arrowWidth + 10 + langTextWidth + 10 + arrowWidth
    local rightAreaX = x + width - padding - totalWidth
    local languageTextX = rightAreaX + arrowWidth + 10

    selector.leftArrow.x = rightAreaX
    selector.leftArrow.y = y + (height - arrowHeight) / 2
    selector.rightArrow.x = languageTextX + langTextWidth + 10
    selector.rightArrow.y = y + (height - arrowHeight) / 2

    love.graphics.print(currentLangName, languageTextX, y + (height - languageFont:getHeight()) / 2)
    love.graphics.setFont(arrowFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("", selector.leftArrow.x + (arrowWidth - arrowFont:getWidth("")) / 2,
        selector.leftArrow.y + (arrowHeight - arrowFont:getHeight()) / 2)
    love.graphics.print("", selector.rightArrow.x + (arrowWidth - arrowFont:getWidth("")) / 2,
        selector.rightArrow.y + (arrowHeight - arrowFont:getHeight()) / 2)
end

return {
    load = load,
    update = update,
    draw = draw,
    keypressed = keypressed,
    mousepressed = mousepressed,
    mousemoved = mousemoved,
    mousereleased = mousereleased,
    wheelmoved = wheelmoved
}
