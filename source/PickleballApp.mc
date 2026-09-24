import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class PickleballApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) as Void {
        Settings.load();
    }

    function onStop(state) as Void {
        // 被系統關閉等無法詢問的情況：保留紀錄
        Recorder.save();
        Settings.save();
    }

    function getInitialView() {
        return [new LauncherView()];
    }
}

// 設定值（會記住上次的選擇）
module Settings {
    var rally = false;
    var doubles = true;
    var target = 11;
    var firstLeft = true;
    var deuce = false;      // true = 需領先 2 分才獲勝（預設關閉）
    var player = true;      // true = 選手（我方/對手），false = 記錄員（左方/右方）

    const TARGETS = [11, 13, 15, 17, 19, 21];

    function load() as Void {
        var v = Application.Storage.getValue("rally");
        if (v != null) { rally = v; }
        v = Application.Storage.getValue("doubles");
        if (v != null) { doubles = v; }
        v = Application.Storage.getValue("target");
        if (v != null) { target = v; }
        v = Application.Storage.getValue("firstLeft");
        if (v != null) { firstLeft = v; }
        v = Application.Storage.getValue("deuce");
        if (v != null) { deuce = v; }
        v = Application.Storage.getValue("player");
        if (v != null) { player = v; }
    }

    function save() as Void {
        Application.Storage.setValue("rally", rally);
        Application.Storage.setValue("doubles", doubles);
        Application.Storage.setValue("target", target);
        Application.Storage.setValue("firstLeft", firstLeft);
        Application.Storage.setValue("deuce", deuce);
        Application.Storage.setValue("player", player);
    }

    function nextTarget() as Void {
        var idx = TARGETS.indexOf(target);
        target = TARGETS[(idx + 1) % TARGETS.size()];
    }

    function str(id) as String {
        return WatchUi.loadResource(id) as String;
    }

    function formatLabel() as String {
        return str(rally ? Rez.Strings.Rally : Rez.Strings.SideOut);
    }

    function modeLabel() as String {
        return str(doubles ? Rez.Strings.Doubles : Rez.Strings.Singles);
    }

    function deuceLabel() as String {
        return str(deuce ? Rez.Strings.WinBy2 : Rez.Strings.NoDeuce);
    }

    function roleLabel() as String {
        return str(player ? Rez.Strings.Player : Rez.Strings.Scorer);
    }

    // team: 0 = 左邊（選手模式為我方），1 = 右邊（選手模式為對手）
    function teamName(team as Number) as String {
        if (player) {
            return str(team == 0 ? Rez.Strings.MyTeam : Rez.Strings.Opponent);
        }
        return str(team == 0 ? Rez.Strings.LeftTeam : Rez.Strings.RightTeam);
    }

    function firstLabel() as String {
        return teamName(firstLeft ? 0 : 1);
    }
}
