pragma Singleton

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

// Fiat colours — the family standard. Two palettes behind one set of names,
// switched by a single boolean that is remembered between runs.
//
//   ambient = true   the user's ambience via Theme.*. No background is
//                    painted anywhere; the wallpaper is the background.
//   ambient = false  Fiat colours. The app paints its own light background
//                    and uses the family palette.
//
// Semantic colours ignore both. They mean something, so they only shift
// between a dark and a light variant to keep contrast.

QtObject {
    id: t

    // ---- the switch, remembered between runs ----
    property ConfigurationValue ambientConfig: ConfigurationValue {
        key: "/apps/harbour-fiatvox/ambient"
        defaultValue: true
    }
    readonly property bool ambient: ambientConfig.value
    function setAmbient(on) { ambientConfig.value = on }

    // Is the effective scheme dark?
    //
    // Belt and braces, because this one has been wrong twice in this app and
    // a wrong answer here paints a white card under a dark ambience -- with
    // white text on it. The scheme enum is the intended signal; the measured
    // lightness of the text is the same fact read off the data. Either alone
    // has failed; both cannot, because no coherent ambience pairs dark text
    // with a dark background. Fiat colours are a light scheme, so false there.
    readonly property bool dark: ambient
        ? (Theme.colorScheme === Theme.LightOnDark
           || (Theme.primaryColor.r + Theme.primaryColor.g + Theme.primaryColor.b) / 3.0 > 0.5)
        : false

    readonly property string serif: "Georgia"

    // ---- the notch ----
    //
    // Silica's own PageHeader clears the cutout. Ours do not, because they are
    // ours -- and on the Jolla Phone (2026) that puts the top of a capital
    // letter, and the left end of a long right-aligned title, straight into the
    // hole. So every header in this app starts this far down.
    //
    // Read from the platform when the platform will say. The property is not
    // guaranteed to exist, and asking a QObject for a property it does not have
    // returns undefined rather than throwing, so the probe is safe -- but it
    // does mean the fallback has to be a real number, not a hope.
    function cutoutHeight() {
        if (typeof Screen === "undefined" || Screen === null) return -1
        var c = Screen.topCutout
        if (c === undefined || c === null) return -1
        if (typeof c === "number") return c
        if (c.height !== undefined) return c.height
        return -1
    }

    // Tune this one number if the clearance is wrong on a device that does not
    // report its cutout. It is the only place the value lives.
    readonly property real headerTopInsetFallback: Theme.paddingLarge * 1.5

    readonly property real headerTopInset: {
        var c = cutoutHeight()
        return c >= 0 ? c + Theme.paddingMedium : headerTopInsetFallback
    }

    // Where the system's own indicators sit -- the little lights along the top
    // of the screen. Anything of ours that belongs on that line is centred on
    // it rather than given a top margin, so it reads as part of the same row
    // instead of nearly part of it.
    readonly property real statusRowCenter: Theme.itemSizeLarge / 2

    // ---- text and accent ----
    readonly property color primaryText:   ambient ? Theme.primaryColor   : "#1A1A1A"
    readonly property color secondaryText: ambient ? Theme.secondaryColor : Qt.rgba(0.10, 0.10, 0.10, 0.55)

    // Fiat Vox's accent: ink blue. It does not collide with this app's
    // semantic colours, which are green, amber and red -- see below.
    readonly property color accent: ambient ? Theme.highlightColor : "#4A5FBF"

    // ---- the shared paper ----
    readonly property color backgroundHigh: "#F2EFE8"
    readonly property color backgroundLow:  "#D8D2C6"

    readonly property color card: ambient
        ? (dark ? Qt.rgba(0.08, 0.08, 0.08, 1.0) : Qt.rgba(0.96, 0.96, 0.96, 1.0))
        : "#F5F5F5"
    readonly property color surface: card
    readonly property color cardBorder:   Theme.rgba(primaryText, 0.45)
    readonly property color innerBorder:  Theme.rgba(primaryText, 0.22)
    readonly property color recessFill:   Theme.rgba(primaryText, 0.05)
    readonly property color recessBorder: Theme.rgba(primaryText, 0.16)
    readonly property real cardRadius: Theme.paddingLarge * 2
    readonly property int cardBorderWidth: 2

    // ---- pills ----
    readonly property color pillFill:         Theme.rgba(primaryText, 0.15)
    readonly property color pillBorder:       Theme.rgba(primaryText, 0.55)
    readonly property color pillFillActive:   Theme.rgba(accent, 0.15)
    readonly property color pillBorderActive: Theme.rgba(accent, 0.45)

    // ---- meaning, never decoration ----
    //
    // Fiat Vox has three verdict colours, because a tuner has three things to
    // say: true, close, wrong. They are the reason the accent is blue -- an
    // amber accent would have sat on top of "close", and the family rule is
    // that an accent must not collide with a semantic colour.
    readonly property color inTune: dark ? "#7FA65C" : "#41682A"
    readonly property color nearly: dark ? "#C87941" : "#8F4E1B"
    readonly property color wrong:  dark ? "#A0403A" : "#8A2B25"

    // Unfilled dots, ring tracks, anything absent.
    readonly property color dotIdle: Theme.rgba(primaryText, 0.22)

    // Readable mark drawn on top of an accent fill.
    //
    // What matters is how light the accent actually is, and an ambience can
    // pair a light scheme with a dark highlight or the other way round. So
    // measure it. A function, not a chain of readonly bindings -- the chained
    // version came out undefined on the device, and an undefined colour does
    // not shout, it silently renders black.
    function markOn(c) {
        if (c === undefined || c === null) return "#F5F5F5"
        return (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) > 0.55 ? "#1A1A1A" : "#F5F5F5"
    }

    readonly property color onAccent: markOn(accent)

    // ---- the maker's mark ----
    //
    // Taupe, and a FIXED value: this one deliberately does not follow the
    // ambience, for the same reason the launcher icon does not. It is
    // Munkstolen's colour, not the app's, and a signature that changed colour
    // with the wallpaper would not be a signature.
    readonly property color makerMark: "#7E7566"

    // The wash under a pressed row or menu item. Silica would use the
    // ambience highlight here, which bleeds through Fiat colours.
    readonly property color highlightWash: Theme.rgba(accent, 0.15)

    // ---- Silica's own chrome ----
    //
    // Menus, pull-down drawers, ComboBox values, TextField labels and
    // underlines, sliders, selection: none of these takes a colour from us.
    // They read Theme.* directly, which is the ambience, which is why they
    // stay ambience-coloured under Fiat colours no matter how many `color:`
    // lines are added to individual items.
    //
    // Silica's answer is `palette` -- colour roles that hang off an item and
    // are INHERITED by its children. Set it once on the ApplicationWindow and
    // every Silica control below it follows.
    //
    // Written defensively on purpose. `palette` and its roles are not
    // guaranteed to exist on every Silica version, and a missing property
    // assigned in a QML binding is a load-time error -- the whole page dies.
    // Assigned from JavaScript instead, a missing property is a no-op.
    function applyPalette(item) {
        if (item === null || item === undefined) return
        var p = item.palette
        if (p === undefined || p === null) return
        try { p.colorScheme = ambient ? Theme.colorScheme : Theme.DarkOnLight } catch (e) { }
        try { p.primaryColor = primaryText } catch (e) { }
        try { p.secondaryColor = secondaryText } catch (e) { }
        try { p.highlightColor = accent } catch (e) { }
        try { p.secondaryHighlightColor = Theme.rgba(accent, 0.6) } catch (e) { }
        try { p.highlightBackgroundColor = Theme.rgba(accent, 0.3) } catch (e) { }
        try { p.errorColor = wrong } catch (e) { }
        try { p.highlightDimmerColor = ambient ? Theme.highlightDimmerColor : backgroundLow } catch (e) { }
        try { p.overlayBackgroundColor = ambient ? Theme.overlayBackgroundColor : backgroundHigh } catch (e) { }
    }
}
