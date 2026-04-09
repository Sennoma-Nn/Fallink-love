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
            map = "Return to game levels"
        },
        zh_cn = {
            settings = "游戏设置",
            map = "返回游戏关卡"
        },
        zh_tw = {
            settings = "遊戲設定",
            map = "返回遊戲關卡"
        },
        jp = {
            settings = "ゲーム設定",
            map = "ゲームレベルに戻る"
        },
    },
}

Locales.fonts = {
    en = "src/font/SarasaGothicSC-Regular.ttf",
    zh_cn = "src/font/SarasaGothicSC-Regular.ttf",
    zh_tw = "src/font/SarasaGothicTC-Regular.ttf",
    jp = "src/font/SarasaGothicJ-Regular.ttf"
}

function Locales.get(category, key)
    local lang = Locales.current
    if Locales.texts[category] and Locales.texts[category][lang] then
        return Locales.texts[category][lang][key] or key
    end
    return key
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

return Locales
