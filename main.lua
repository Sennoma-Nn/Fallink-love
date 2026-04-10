local currentState = nil
local nextState = nil
local transitionTimer = 0
local transitionPhase = "none" -- "none" / "fade_in" / "fade_out"
local titlePage, homePage, settingsPage, gamePage

local function switchState(newState)
    if transitionPhase ~= "none" then
        return
    end
    nextState = newState
    transitionPhase = "fade_in"
    transitionTimer = 0
end

function love.load()
    titlePage = require("src.pages.title")
    homePage = require("src.pages.home")
    settingsPage = require("src.pages.settings")
    gamePage = require("src.game")
    titlePage.load(switchState)
    homePage.load(switchState)
    settingsPage.load(switchState)
    gamePage.load(switchState)
    currentState = "title"
end

function love.update(dt)
    if transitionPhase ~= "none" then
        transitionTimer = transitionTimer + dt
        if transitionPhase == "fade_in" and transitionTimer >= 0.5 then
            currentState = nextState
            transitionPhase = "fade_out"
            transitionTimer = 0
        elseif transitionPhase == "fade_out" and transitionTimer >= 0.5 then
            transitionPhase = "none"
            transitionTimer = 0
            nextState = nil
        end
    end

    if currentState == "title" then
        titlePage.update(dt)
    elseif currentState == "home" then
        homePage.update(dt)
    elseif currentState == "settings" then
        settingsPage.update(dt)
    elseif currentState == "game" then
        gamePage.update(dt)
    end
end

function love.draw()
    if currentState == "title" then
        titlePage.draw()
    elseif currentState == "home" then
        homePage.draw()
    elseif currentState == "settings" then
        settingsPage.draw()
    elseif currentState == "game" then
        gamePage.draw()
    end

    if transitionPhase ~= "none" then
        local alpha = 0
        if transitionPhase == "fade_in" then
            alpha = transitionTimer / 0.5
        elseif transitionPhase == "fade_out" then
            alpha = 1 - (transitionTimer / 0.5)
        end

        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setColor(1, 1, 1, 1)
    end
end

function love.keypressed(key)
    if transitionPhase ~= "none" then
        return
    end

    if currentState == "title" then
        titlePage.keypressed(key)
    elseif currentState == "home" then
        homePage.keypressed(key)
    elseif currentState == "settings" then
        settingsPage.keypressed(key)
    elseif currentState == "game" then
        gamePage.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if transitionPhase ~= "none" then
        return
    end

    if currentState == "title" then
        titlePage.mousepressed(x, y, button)
    elseif currentState == "home" then
        homePage.mousepressed(x, y, button)
    elseif currentState == "settings" then
        settingsPage.mousepressed(x, y, button)
    elseif currentState == "game" then
        gamePage.mousepressed(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if transitionPhase ~= "none" then
        return
    end

    if currentState == "title" then
    elseif currentState == "home" then
        homePage.mousemoved(x, y, dx, dy)
    elseif currentState == "settings" then
        settingsPage.mousemoved(x, y, dx, dy)
    elseif currentState == "game" then
        gamePage.mousemoved(x, y, dx, dy)
    end
end

function love.mousereleased(x, y, button)
    if transitionPhase ~= "none" then
        return
    end

    if currentState == "title" then
    elseif currentState == "home" then
        homePage.mousereleased(x, y, button)
    elseif currentState == "settings" then
        settingsPage.mousereleased(x, y, button)
    elseif currentState == "game" then
        gamePage.mousereleased(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if transitionPhase ~= "none" then
        return
    end

    if currentState == "title" then
    elseif currentState == "home" then
        homePage.wheelmoved(x, y)
    elseif currentState == "settings" then
        settingsPage.wheelmoved(x, y)
    elseif currentState == "game" then
        gamePage.wheelmoved(x, y)
    end
end

return {
    switchState = switchState
}
