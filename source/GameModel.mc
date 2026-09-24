import Toybox.Lang;

// 比賽狀態與計分規則
// team: 0 = 左方, 1 = 右方
class GameModel {
    var rally;          // true = 落地得分 (rally scoring), false = 發球得分 (side-out)
    var doubles;        // true = 雙打
    var target;         // 幾分獲勝
    var winBy2;         // true = Deuce：需領先 2 分才獲勝
    var firstServer;    // 開局發球方 0/1

    var scores as Array<Number> = [0, 0];  // [左, 右]
    var servingTeam as Number = 0;         // 目前發球方 0/1
    var serverNum as Number = 1;           // 雙打發球得分制：1 或 2 號發球員
    var gameOver;
    var winner;

    hidden var _history as Array<Array<Number> > = [];

    function initialize(isRally, isDoubles, winTarget, deuce, first) {
        rally = isRally;
        doubles = isDoubles;
        target = winTarget;
        winBy2 = deuce;
        firstServer = first;
        reset();
    }

    function reset() as Void {
        scores = [0, 0];
        servingTeam = firstServer;
        // 雙打發球得分制：開局只有一位發球員 → 叫分 0-0-2
        serverNum = (doubles && !rally) ? 2 : 1;
        gameOver = false;
        winner = -1;
        _history = [];
    }

    // 某方贏得這一球（按下左 / 右）
    function rallyWon(team as Number) as Void {
        if (gameOver) {
            return;
        }
        _history.add([scores[0], scores[1], servingTeam, serverNum]);

        if (rally) {
            // 落地得分：贏球方得分，並取得（或保有）發球權
            scores[team] = scores[team] + 1;
            servingTeam = team;
        } else if (team == servingTeam) {
            // 發球得分：只有發球方贏球才得分
            scores[team] = scores[team] + 1;
        } else if (doubles && serverNum == 1) {
            // 雙打 1 號發球員失分 → 換隊友（2 號）發球
            serverNum = 2;
        } else {
            // 換發 (side out)
            servingTeam = team;
            serverNum = 1;
        }

        var other = 1 - team;
        if (scores[team] >= target && (!winBy2 || scores[team] - scores[other] >= 2)) {
            gameOver = true;
            winner = team;
        }
    }

    function canUndo() as Boolean {
        return _history.size() > 0;
    }

    function undo() as Boolean {
        var n = _history.size();
        if (n == 0) {
            return false;
        }
        var s = _history[n - 1];
        _history = _history.slice(0, n - 1);
        scores = [s[0], s[1]];
        servingTeam = s[2];
        serverNum = s[3];
        gameOver = false;
        winner = -1;
        return true;
    }

    // 發球方分數為偶數 → 從右區發球
    function serveFromRight() as Boolean {
        return scores[servingTeam] % 2 == 0;
    }

    function showServerNum() as Boolean {
        return doubles && !rally;
    }

    // 叫分：發球方分數-接發方分數(-發球員號碼)
    function scoreCall() as String {
        var s = scores[servingTeam].toString() + "-" + scores[1 - servingTeam].toString();
        if (showServerNum()) {
            s += "-" + serverNum.toString();
        }
        return s;
    }
}
