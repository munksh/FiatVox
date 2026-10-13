pragma Singleton
import QtQuick 2.0
import Nemo.Configuration 1.0

QtObject {
    id: n

    property ConfigurationValue config: ConfigurationValue {
        key: "/apps/harbour-fiatvox/noteNames"
        defaultValue: "letters"
    }
    readonly property string system: config.value
    function setSystem(s) { config.value = s }

    readonly property string sharpGlyph: "♯"

    readonly property var systems: [
        { value: "letters",  label: "C D E" },
        { value: "solfege",  label: "Do Re Mi" },
        { value: "japanese", label: "ハ ニ ホ" },
        { value: "korean",   label: "다 라 마" }
    ]

    readonly property var bases: ({
        letters:  ["C",  "C",  "D",  "D",  "E",  "F",  "F",  "G",   "G",   "A",  "A",  "B"],
        solfege:  ["Do", "Do", "Re", "Re", "Mi", "Fa", "Fa", "Sol", "Sol", "La", "La", "Si"],
        japanese: ["ハ", "ハ", "ニ", "ニ", "ホ", "ヘ", "ヘ", "ト",  "ト",  "イ", "イ", "ロ"],
        korean:   ["다", "다", "라", "라", "마", "바", "바", "사",  "사",  "가", "가", "나"]
    })
    readonly property var sharps: [false, true, false, true, false, false, true, false, true, false, true, false]

    function table() { return bases[system] || bases.letters }
    function base(i) { return table()[i] }
    function sharp(i) { return sharps[i] }

    function label() {
        for (var i = 0; i < systems.length; i++)
            if (systems[i].value === system)
                return systems[i].label
        return systems[0].label
    }

    function scale() {
        var t = table(), out = []
        for (var i = 0; i < 12; i++)
            out.push(t[i] + (sharps[i] ? sharpGlyph : ""))
        return out.join("  ")
    }
}
