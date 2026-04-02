local Locales = {}

Locales.languages = {
    en = "English",
    zh = "中文"
}

Locales.current = "en"

Locales.texts = {
    title = {
        en = {
            prompt = "Press SPACE to continue",
        },
        zh = {
            prompt = "按下空格继续",
        }
    },
    common = {
        en = {
        },
        zh = {
        }
    }
}

function Locales.get(category, key)
    local lang = Locales.current
    if Locales.texts[category] and Locales.texts[category][lang] then
        return Locales.texts[category][lang][key] or key
    end
    return key
end

function Locales.getCurrentLanguage()
    return Locales.current
end

function Locales.getSupportedLanguages()
    return Locales.languages
end

return Locales