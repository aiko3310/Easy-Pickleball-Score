import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Graphics;

// 空白底層畫面：每次顯示時自動打開設定選單
class LauncherView extends WatchUi.View {
    hidden var _timer;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:openSetup), 50, false);
    }

    function openSetup() as Void {
        var menu = buildSetupMenu();
        WatchUi.pushView(menu, new SetupMenuDelegate(menu), WatchUi.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
    }
}

function buildSetupMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({ :title => Settings.str(Rez.Strings.Setup) });
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Start), null, :start, null));
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.FirstServe), Settings.firstLabel(), :first, null));
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Role), Settings.roleLabel(), :role, null));
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Format), Settings.formatLabel(), :format, null));
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Points), Settings.target.toString(), :points, null));
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Deuce), Settings.deuceLabel(), :deuce, null));
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Mode), Settings.modeLabel(), :mode, null));
    return menu;
}

class SetupMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :start) {
            Settings.save();
            var model = new GameModel(Settings.rally, Settings.doubles, Settings.target, Settings.deuce, Settings.firstLeft ? 0 : 1);
            var view = new GameView(model);
            WatchUi.switchToView(view, new GameDelegate(model, view), WatchUi.SLIDE_LEFT);
            if (Settings.player) {
                Recorder.start();
            }
            return;
        }
        // 每按一次就切換到下一個選項
        if (id == :role) {
            Settings.player = !Settings.player;
            item.setSubLabel(Settings.roleLabel());
            // 先發球的顯示名稱會跟著身分改變
            var idx = _menu.findItemById(:first);
            if (idx >= 0) {
                _menu.getItem(idx).setSubLabel(Settings.firstLabel());
            }
        } else if (id == :format) {
            Settings.rally = !Settings.rally;
            item.setSubLabel(Settings.formatLabel());
        } else if (id == :points) {
            Settings.nextTarget();
            item.setSubLabel(Settings.target.toString());
        } else if (id == :deuce) {
            Settings.deuce = !Settings.deuce;
            item.setSubLabel(Settings.deuceLabel());
        } else if (id == :mode) {
            Settings.doubles = !Settings.doubles;
            item.setSubLabel(Settings.modeLabel());
        } else if (id == :first) {
            Settings.firstLeft = !Settings.firstLeft;
            item.setSubLabel(Settings.firstLabel());
        }
        WatchUi.requestUpdate();
    }

    function onBack() as Void {
        Settings.save();
        System.exit();
    }
}
