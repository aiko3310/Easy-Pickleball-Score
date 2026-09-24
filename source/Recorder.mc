import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// 選手模式：從開始比賽錄製活動到比完賽
//   比賽結束 → 暫停計時；復原繼續打 → 接著計時
//   離開（重新開始 / 回到設定 / 離開）→ 已比完就自動儲存，沒比完就詢問儲存或捨棄
module Recorder {
    // FIT 的 Racket / Pickleball；SDK 常數要 API 4.1.6 才有，這裡直接用數值
    const SPORT_RACKET = 64;
    const SUB_SPORT_PICKLEBALL = 84;

    var _session as ActivityRecording.Session or Null = null;

    function start() as Void {
        if (_session != null || !(Toybox has :ActivityRecording)) {
            return;
        }
        _session = ActivityRecording.createSession({
            :name => Settings.str(Rez.Strings.Setup),
            :sport => SPORT_RACKET as Activity.Sport,
            :subSport => SUB_SPORT_PICKLEBALL as Activity.SubSport
        });
        _session.start();
    }

    function active() as Boolean {
        return _session != null;
    }

    // 比賽結束就暫停，復原後恢復
    function sync(gameOver as Boolean) as Void {
        var s = _session;
        if (s == null) {
            return;
        }
        if (gameOver && s.isRecording()) {
            s.stop();
        } else if (!gameOver && !s.isRecording()) {
            s.start();
        }
    }

    function save() as Void {
        var s = _session;
        if (s != null) {
            if (s.isRecording()) {
                s.stop();
            }
            s.save();
            _session = null;
        }
    }

    function discard() as Void {
        var s = _session;
        if (s != null) {
            if (s.isRecording()) {
                s.stop();
            }
            s.discard();
            _session = null;
        }
    }

    // 離開比賽畫面前的共同流程；action: :restart / :setup / :exit
    function requestLeave(model as GameModel, action as Symbol) as Void {
        if (_session == null) {
            doLeave(model, action);
        } else if (model.gameOver) {
            save();
            doLeave(model, action);
        } else if (!model.canUndo()) {
            // 一分都還沒打，視為取消
            discard();
            doLeave(model, action);
        } else {
            var menu = new WatchUi.Menu2({ :title => Settings.str(Rez.Strings.SaveActivity) });
            menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Save), null, :save, null));
            menu.addItem(new WatchUi.MenuItem(Settings.str(Rez.Strings.Discard), null, :discard, null));
            WatchUi.pushView(menu, new SaveMenuDelegate(model, action), WatchUi.SLIDE_UP);
        }
    }

    function doLeave(model as GameModel, action as Symbol) as Void {
        if (action == :exit) {
            System.exit();
        } else if (action == :setup) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else {
            model.reset();
            if (Settings.player) {
                start();
            }
            WatchUi.requestUpdate();
        }
    }
}

// 沒比完就離開時：儲存 / 捨棄；按 BACK 取消並回到比賽
class SaveMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _m as GameModel;
    hidden var _action as Symbol;

    function initialize(model as GameModel, action as Symbol) {
        Menu2InputDelegate.initialize();
        _m = model;
        _action = action;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :save) {
            Recorder.save();
        } else {
            Recorder.discard();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        Recorder.doLeave(_m, _action);
    }
}
