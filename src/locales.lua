local Locales = {}

Locales.languages = {
    en = "English",
    zh_cn = "简体中文",
    zh_tw = "繁體中文",
    jp = "日本語",
}

Locales.current = "en"

Locales.texts = {
    title = {
        en = {
            prompt = "Press [SPACE] to continue",
        },
        zh_cn = {
            prompt = "按下「空格」继续",
        },
        zh_tw = {
            prompt = "按下「空白」繼續",
        },
        jp = {
            prompt = "「スペース」キーを押して続行",
        }
    },
    tips = {
        en = {
            settings = "Game settings",
            map = "Return to game levels",
            language = "Language"
        },
        zh_cn = {
            settings = "游戏设置",
            map = "返回游戏关卡",
            language = "语言"
        },
        zh_tw = {
            settings = "遊戲設定",
            map = "返回遊戲關卡",
            language = "語言"
        },
        jp = {
            settings = "ゲーム設定",
            map = "ゲームレベルに戻る",
            language = "言語"
        },
    },
}

Locales.fonts = {
    en = "src/font/Montserrat-Regular.otf",
    zh_cn = "src/font/SarasaGothicSC-Regular.ttf",
    zh_tw = "src/font/SarasaGothicTC-Regular.ttf",
    jp = "src/font/SarasaGothicJ-Regular.ttf"
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

function Locales.setLanguage(langCode)
    Locales.current = langCode
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

local languageChangeCallbacks = {}

function Locales.addLanguageChangeCallback(callback)
    table.insert(languageChangeCallbacks, callback)
end

function Locales.removeLanguageChangeCallback(callback)
    for i, cb in ipairs(languageChangeCallbacks) do
        if cb == callback then
            table.remove(languageChangeCallbacks, i)
            return true
        end
    end
    return false
end

function Locales.notifyLanguageChange()
    for _, callback in ipairs(languageChangeCallbacks) do
        callback(Locales.current)
    end
end

local originalSetLanguage = Locales.setLanguage
function Locales.setLanguage(langCode)
    print("Locales.setLanguage " .. langCode)
    originalSetLanguage(langCode)
    Locales.notifyLanguageChange()
end

return Locales
