local Locales = {}

Locales.languages = {
    en = "English",
    zh_cn = "简体中文",
    zh_tw = "繁體中文",
    jp = "日本語",
}

Locales.current = "en"
Locales.texts = require("src.texts")

Locales.fonts = {
    en = "src/font/Montserrat-Regular.otf",
    zh_cn = "src/font/SarasaGothicSC-SemiBold.ttf",
    zh_tw = "src/font/SarasaGothicTC-SemiBold.ttf",
    jp = "src/font/SarasaGothicJ-SemiBold.ttf"
}

function Locales.get(category, key)
    local lang = Locales.current
    return Locales.texts[category][lang][key]
end

function Locales.getFontPath()
    return Locales.fonts[Locales.current]
end

function Locales.getCurrentLanguage()
    return Locales.current
end

function Locales.getSupportedLanguages()
    return Locales.languages
end

local languageChangeCallbacks = {}

function Locales.setLanguage(langCode)
    Locales.current = langCode
    for _, callback in pairs(languageChangeCallbacks) do
        callback(langCode)
    end
end

function Locales.getLanguageName(langCode)
    return Locales.languages[langCode]
end

function Locales.getLanguageCodes()
    local codes = {}
    for code, _ in pairs(Locales.languages) do
        table.insert(codes, code)
    end
    return codes
end

function Locales.getNextLanguage()
    local codes = Locales.getLanguageCodes()
    local currentIndex = 1
    for i, code in ipairs(codes) do
        if code == Locales.current then
            currentIndex = i
            break
        end
    end
    local nextIndex = (currentIndex % #codes) + 1
    return codes[nextIndex]
end

function Locales.getPrevLanguage()
    local codes = Locales.getLanguageCodes()
    local currentIndex = 1
    for i, code in ipairs(codes) do
        if code == Locales.current then
            currentIndex = i
            break
        end
    end
    local prevIndex = ((currentIndex - 2) % #codes) + 1
    return codes[prevIndex]
end

function Locales.addLanguageChangeCallback(id, callback)
    languageChangeCallbacks[id] = callback
end

function Locales.removeLanguageChangeCallback(id)
    if languageChangeCallbacks[id] then
        languageChangeCallbacks[id] = nil
        return true
    end
    return false
end

function Locales.notifyLanguageChange()
    for _, callback in pairs(languageChangeCallbacks) do
        callback(Locales.current)
    end
end

return Locales
