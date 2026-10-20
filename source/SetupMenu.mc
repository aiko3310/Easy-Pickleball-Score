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
            // 打開分數子選單（預設分數 + 自訂）
            var sub = buildPointsMenu();
            WatchUi.pushView(sub, new PointsMenuDelegate(item), WatchUi.SLIDE_LEFT);
            return;
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

// 分數子選單：常用分數 + 自訂
function buildPointsMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({ :title => Settings.str(Rez.Strings.Points) });
    var focus = -1;
    for (var i = 0; i < Settings.TARGETS.size(); i++) {
        var t = Settings.TARGETS[i];
        menu.addItem(new WatchUi.MenuItem(t.toString(), null, t, null));
        if (t == Settings.target) { focus = i; }
    }
    // 自訂：目前分數不在常用清單時，顯示在副標籤
    var customSub = focus < 0 ? Settings.target.toString() : null;
    menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Custom), customSub, :custom, null));
    menu.setFocus(focus < 0 ? Settings.TARGETS.size() : focus);
    return menu;
}

class PointsMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _parentItem as WatchUi.MenuItem;

    function initialize(parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :custom) {
            var view = new PointsPickerView();
            WatchUi.pushView(view, new PointsPickerDelegate(view, _parentItem), WatchUi.SLIDE_LEFT);
            return;
        }
        Settings.target = id as Number;
        _parentItem.setSubLabel(Settings.target.toString());
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// 自訂分數畫面：上下鍵（或滑動）調整，START（或點一下）確認
// 不用系統 Picker：它的背景色依機型主題而異，文字顏色無法對應
class PointsPickerView extends WatchUi.View {
    var value as Number;
    hidden var _title as String;

    function initialize() {
        View.initialize();
        value = Settings.target;
        _title = Settings.str(Rez.Strings.Points);
    }

    function step(delta as Number) as Void {
        var span = Settings.TARGET_MAX - Settings.TARGET_MIN + 1;
        value = Settings.TARGET_MIN + ((value - Settings.TARGET_MIN + delta) % span + span) % span;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.20, Graphics.FONT_SMALL, _title, center);
        dc.drawText(cx, h * 0.52, Graphics.FONT_NUMBER_HOT, value.toString(), center);
        // 上下箭頭提示
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var a = w * 0.05;
        var yUp = h * 0.33;
        var yDn = h * 0.71;
        dc.fillPolygon([[cx - a, yUp + a / 2], [cx + a, yUp + a / 2], [cx, yUp - a / 2]]);
        dc.fillPolygon([[cx - a, yDn - a / 2], [cx + a, yDn - a / 2], [cx, yDn + a / 2]]);
    }
}

class PointsPickerDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as PointsPickerView;
    hidden var _parentItem as WatchUi.MenuItem;

    function initialize(view as PointsPickerView, parentItem as WatchUi.MenuItem) {
        BehaviorDelegate.initialize();
        _view = view;
        _parentItem = parentItem;
    }

    function onPreviousPage() as Boolean {
        _view.step(1);
        return true;
    }

    function onNextPage() as Boolean {
        _view.step(-1);
        return true;
    }

    function onSelect() as Boolean {
        Settings.target = _view.value;
        _parentItem.setSubLabel(Settings.target.toString());
        // 關閉自訂畫面與分數子選單，回到設定選單
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
