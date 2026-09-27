import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// 操作：
//   UP    = 左方贏球     DOWN = 右方贏球
//   觸控：點螢幕左半 / 右半
//   BACK  = 復原上一分（0-0 時回到設定）；沒有 BACK 鍵的機型往右滑
//   START = 選單（復原 / 重新開始 / 回設定 / 離開）
class GameDelegate extends WatchUi.BehaviorDelegate {
    hidden var _m;
    hidden var _v;

    function initialize(model, view) {
        BehaviorDelegate.initialize();
        _m = model;
        _v = view;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_UP) {
            point(0);
        } else if (k == WatchUi.KEY_DOWN) {
            point(1);
        } else if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_MENU) {
            openMenu();
        } else if (k == WatchUi.KEY_ESC) {
            back();
        } else {
            return false;
        }
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var xy = evt.getCoordinates();
        var w = System.getDeviceSettings().screenWidth;
        point(xy[0] < w / 2 ? 0 : 1);
        return true;
    }

    // 吃掉滑動手勢避免誤觸；沒有 BACK 實體鍵的機型（如 vívoactive 3）往右滑 = 復原
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        if (evt.getDirection() == WatchUi.SWIPE_RIGHT && !hasBackButton()) {
            back();
        }
        return true;
    }

    hidden function hasBackButton() as Boolean {
        var ds = System.getDeviceSettings();
        if (ds has :inputButtons) {
            return (ds.inputButtons & System.BUTTON_INPUT_ESC) != 0;
        }
        return true;
    }

    function onMenu() as Boolean {
        openMenu();
        return true;
    }

    function onBack() as Boolean {
        back();
        return true;
    }

    hidden function point(team) as Void {
        if (_m.gameOver) {
            return;
        }
        _m.rallyWon(team);
        Recorder.sync(_m.gameOver);
        vibe(_m.gameOver ? 400 : 60);
        WatchUi.requestUpdate();
    }

    hidden function back() as Void {
        if (_m.undo()) {
            Recorder.sync(_m.gameOver);
            vibe(30);
            WatchUi.requestUpdate();
        } else {
            // 還沒開始計分 → 回到設定
            Recorder.requestLeave(_m, :setup);
        }
    }

    hidden function openMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => Settings.str(Rez.Strings.GameMenu) });
        menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Undo), null, :undo, null));
        menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Restart), null, :restart, null));
        menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.BackToSetup), null, :setup, null));
        menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Exit), null, :exit, null));
        WatchUi.pushView(menu, new GameMenuDelegate(_m), WatchUi.SLIDE_UP);
    }

    hidden function vibe(ms) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(80, ms)]);
        }
    }
}

class GameMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _m;

    function initialize(model) {
        Menu2InputDelegate.initialize();
        _m = model;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (id == :undo) {
            _m.undo();
            Recorder.sync(_m.gameOver);
            WatchUi.requestUpdate();
        } else {
            // :restart / :setup / :exit
            Recorder.requestLeave(_m, id as Symbol);
        }
    }
}
