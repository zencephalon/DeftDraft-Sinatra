// saved buffer
var lc_time = -1;
var diffs = [];
var b_diffs = [];

var pb_pointer = 0;

var pb_timeout_ref;
var playback = false;
var pb_paused = false;
var pb_dir = 1;

var just_loaded = true;

function start_pb() {
    playback = true;
    pb_paused = false;
    
    playback_buffer = new Buffer('', 0);
    playback_buffer.set();
    pb_pointer = 0;

    r_playback();
}

function pause_pb() {
    pb_paused = true;
    window.clearTimeout(pb_timeout_ref);
}                     

function resume_pb() {
    pb_paused = false;

    r_playback();
}

function step_pb() {
    if (pb_pointer >= diffs.length || pb_pointer < 0) {
        return false;
    }

    diff = diffs[pb_pointer];

    if (diff[0] == 1) {
        pb_text = deft.value;
        start = pb_text.slice(0, diff[1]);
        end = pb_text.slice(diff[1]);
        deft.value = start + diff[2] + end;
    }

    if (diff[0] == 0) {
        pb_text = deft.value;
        start = pb_text.slice(0, diff[1] - diff[2].length);
        end = pb_text.slice(diff[1]);
        deft.value = start + end;
    }

    pb_pointer += pb_dir;
    status();
    return true;
}

function r_playback() {
    if (step_pb()) {
        pb_timeout_ref = window.setTimeout(r_playback, diffs[pb_pointer - 1][3]);
    }
}

function decode_diffs() {
    diff_str = document.getElementById('diffs').value;
    diffs_ar = diff_str.split(';');
    for (i = 0; i < diffs_ar.length; i++) {
        diff_ar = diffs_ar[i].split(',');
        diff = [];
        diff[0] = parseInt(diff_ar[0]);
        diff[1] = parseInt(diff_ar[1]);
        diff[2] = decodeURIComponent(diff_ar[2]);
        diff[3] = parseInt(diff_ar[3]);
        diffs.push(diff);
    }
}

function Buffer(text, cursor) {
    this.text = text; this.cursor = cursor;
}

Buffer.prototype.set = function() {
    deft.value = this.text;
    setCaret(deft, this.cursor);
}

Buffer.prototype.toString = function() {
    return this.cursor + ":" + this.text;
}

function getBuffer() {
    return new Buffer(deft.value.replace(/ +/g, ' '), getCaret(deft));
}

function status() {
    if (playback) {
        playback_status();
    } else {
        status1();
    }
}

function status1() {
    var html = "Draft: <b>" + (current + 1) + "</b>" + "/" + buffers.length;
    html += " - Commit: <b>" + commits + "</b>";
    document.getElementById("buffers").innerHTML = html;
}

function status2() {
    html = "cursorpos: " + cursor_pos + " change: " + change_type + " d_tx: " + d_tx + " d_cr: " + d_cr;
    document.getElementById("buffers").innerHTML = html;
}

function playback_status() {
    html = "playback: " + pb_pointer + "/" + diffs.length + (pb_paused ? " paused" : "")
    document.getElementById("buffers").innerHTML = html;
}

function bind(sc, f) {
    Mousetrap.bind(sc, function(e) {
        if (e.preventDefault) { e.preventDefault(); } else { e.returnValue = false; }
        f();
        status();
    });
}

Mousetrap.stopCallback = function(e, element, combo) {
    if ((' ' + element.className + ' ').indexOf(' mousetrap ') > -1) {
        return false;
    }
    return true;
}

//bind('ctrl+h', function() { left(); });
bind('ctrl+l', function() { right(); });
bind('ctrl+h', function() { left(); });
//bind('ctrl+l', function() { right(); });

//bind('alt+left', function() { left(); });
//bind('alt+right', function() { right(); });
//bind('alt+up', function() { commit(); });
//bind('alt+down', function() { scratch(); });

bind('ctrl+s', function() { commit(); });
bind('ctrl+space', function() { scratch(); });
