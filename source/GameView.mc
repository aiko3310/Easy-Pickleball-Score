import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class GameView extends WatchUi.View {
    hidden var _m as GameModel;
    hidden var _header;     // 一行版：賽制 · 單雙打 · 分數 [· Deuce]
    hidden var _hdr1;       // 兩行版第一行：賽制
    hidden var _hdr2;       // 兩行版第二行：單雙打 · 分數 [· Deuce]
    hidden var _hdrMode;    // 有副螢幕時分三行：賽制 / 單雙打 / 分數 [· Deuce]
    hidden var _hdrTarget;
    hidden var _sWinsFmt;
    hidden var _names as Array<String>;
    hidden var _sHint;

    function initialize(model as GameModel) {
        View.initialize();
        _m = model;
        _hdr1 = Settings.formatLabel();
        _hdrMode = Settings.modeLabel();
        _hdrTarget = model.target.toString();
        if (model.winBy2) {
            _hdrTarget += " · " + Settings.str(Rez.Strings.Deuce);
        }
        _hdr2 = _hdrMode + " · " + _hdrTarget;
        _header = _hdr1 + " · " + _hdr2;
        _sWinsFmt = Settings.str(Rez.Strings.WinsFmt);
        _names = [Settings.teamName(0), Settings.teamName(1)];
        _sHint = Settings.str(Rez.Strings.HintOver);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (_m.gameOver) {
            drawGameOver(dc);
        } else {
            drawScore(dc);
        }
    }

    hidden function drawScore(dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var font = Graphics.FONT_XTINY;
        var fh = dc.getFontHeight(font);
        var callFont = Graphics.FONT_SMALL;
        var sub = subscreen();

        // 上方：賽制資訊。各區塊依字高往下排，小螢幕才不會重疊
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var nameY;
        var courtTop;
        var callY;
        if (sub != null) {
            // Instinct 等有副螢幕的機型：賽制分三行放在副螢幕左邊，小球場畫在副螢幕裡
            var lines = [_hdr1, _hdrMode, _hdrTarget];
            var hx = sub.x / 2;
            var y = sub.y + (sub.height - lines.size() * fh) / 2 + fh / 2;
            for (var i = 0; i < lines.size(); i++) {
                dc.drawText(hx, y + i * fh, font, lines[i], center);
            }
            var hdrBottom = y + (lines.size() - 1) * fh + fh / 2;
            var top = (sub.y + sub.height > hdrBottom) ? sub.y + sub.height : hdrBottom;
            nameY = top + fh / 2 + 1;
            callY = h - dc.getFontHeight(callFont) / 2 - h * 0.05;
            courtTop = callY - dc.getFontHeight(callFont) / 2 - 2;
        } else {
            // 圓形螢幕上方較窄，放不下一行就拆成兩行
            var y1 = h * 0.13;
            var lastY = y1;
            if (dc.getTextWidthInPixels(_header, font) <= chordWidth(w, h, y1 - fh / 2) - 8) {
                dc.drawText(cx, y1, font, _header, center);
            } else {
                y1 = h * 0.105;
                lastY = (h * 0.175 > y1 + fh) ? h * 0.175 : y1 + fh;
                dc.drawText(cx, y1, font, _hdr1, center);
                dc.drawText(cx, lastY, font, _hdr2, center);
            }
            nameY = (h * 0.245 > lastY + fh) ? h * 0.245 : lastY + fh;
            courtTop = h * 0.63 - (h * 0.02 > 4 ? h * 0.02 : 4);
            callY = h * 0.84;
        }

        // 中線
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, nameY + fh / 2, cx, courtTop);

        // 大比分：隊名下緣到下方區塊之間，挑放得下的最大數字字型並置中
        var nameBottom = nameY + fh / 2 + 2;
        var bigFont = pickScoreFont(dc, courtTop - nameBottom, w * 0.40);
        var ascent = Graphics.getFontAscent(bigFont);
        var glyphH = ascent * DIGIT_RATIO;
        var baseline = (nameBottom + courtTop) / 2 + glyphH / 2;
        var scoreTop = baseline - ascent;

        var xs = [w * 0.28, w * 0.72];
        for (var t = 0; t < 2; t++) {
            var serving = (t == _m.servingTeam);

            // 隊名；發球方：黃色隊名與分數 + 隊名左邊的球點
            if (serving) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                var nameW = dc.getTextWidthInPixels(_names[t], font);
                var r = (w * 0.02).toNumber();
                dc.fillCircle(xs[t] - nameW / 2 - r * 2, nameY, r);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(xs[t], nameY, font, _names[t], center);
            dc.drawText(xs[t], scoreTop, bigFont, _m.scores[t].toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (sub != null) {
            drawCourt(dc, sub.x + sub.width / 2, sub.y + sub.height / 2,
                (sub.width * 0.78).toNumber(), (sub.height * 0.38).toNumber());
        } else {
            drawCourt(dc, cx, h * 0.70, (w * 0.5).toNumber(), (h * 0.14).toNumber());
        }

        // 下方：叫分
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, callY, callFont, _m.scoreCall(), center);
    }

    // 副螢幕（Instinct 右上角的小圓窗）；沒有則回傳 null
    hidden function subscreen() as Graphics.BoundingBox or Null {
        if (WatchUi has :getSubscreen) {
            return WatchUi.getSubscreen();
        }
        return null;
    }

    // 數字字形高度約為字型 ascent 的比例（實測各機型的數字字型）
    const DIGIT_RATIO = 0.82;

    // 由大到小挑第一個：兩位數的高度與寬度都放得下的數字字型
    hidden function pickScoreFont(dc, maxH, maxW) as Graphics.FontDefinition {
        var fonts = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
                     Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD];
        for (var i = 0; i < fonts.size(); i++) {
            var f = fonts[i];
            if (Graphics.getFontAscent(f) * DIGIT_RATIO <= maxH
                && dc.getTextWidthInPixels("88", f) <= maxW) {
                return f;
            }
        }
        return Graphics.FONT_NUMBER_MILD;
    }

    // 圓形螢幕在高度 y 的可用寬度（方形螢幕直接回傳寬度）
    hidden function chordWidth(w, h, y) as Number {
        if (System.getDeviceSettings().screenShape != System.SCREEN_SHAPE_ROUND) {
            return w;
        }
        var r = w / 2.0;
        var d = y - r;
        if (d * d >= r * r) {
            return 0;
        }
        return (2 * Math.sqrt(r * r - d * d)).toNumber();
    }

    // 小球場（俯視，球網直立在中間；左半 = 左方/我方，右半 = 右方/對手）
    // 面向球網時：左方的右區在下半、右方的右區在上半。
    // 黃點 = 發球員位置
    hidden function drawCourt(dc, cx, cy, cw as Number, ch as Number) as Void {
        var half = cw / 2;
        var x0 = cx - half;
        var x1 = cx + half;
        var y0 = cy - ch / 2;
        var y1 = cy + ch / 2;
        var k = (half * 0.32).toNumber();   // 廚房區（非截擊區）深度

        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x0, y0, cw + 1, ch + 1);
        dc.drawLine(cx - k, y0, cx - k, y1);        // 左邊廚房線
        dc.drawLine(cx + k, y0, cx + k, y1);        // 右邊廚房線
        dc.drawLine(x0, cy, cx - k, cy);            // 左邊中線
        dc.drawLine(cx + k, cy, x1, cy);            // 右邊中線
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(cx, y0 - 3, cx, y1 + 3);        // 球網
        dc.setPenWidth(1);

        // 發球員位置：左方的右區在下、右方的右區在上
        var t = _m.servingTeam;
        var lower = (t == 0) == _m.serveFromRight();
        var qy = lower ? cy + ch / 4 : cy - ch / 4;
        var inset = (half - k) / 3;
        var sx = (t == 0) ? x0 + inset : x1 - inset;

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(sx, qy, (ch / 6).toNumber());
    }

    hidden function drawGameOver(dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var name = _names[_m.winner];
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.28, Graphics.FONT_MEDIUM, Lang.format(_sWinsFmt, [name]), center);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.50, Graphics.FONT_NUMBER_MEDIUM,
            _m.scores[0].toString() + " - " + _m.scores[1].toString(), center);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.74, Graphics.FONT_XTINY, _sHint, center);
    }
}
