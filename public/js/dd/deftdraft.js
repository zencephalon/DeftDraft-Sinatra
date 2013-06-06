// saved buffer
var sbuffer = new Buffer('', 0);
var buffers = [sbuffer];
var deft = document.getElementById("deft");
var current = 0;
var commits = 0;

var text = "";
var cursor_pos = 0;
var change_type = "";
var changes = 0;
var d_tx = 0;
var d_cr = 0;

var lc_time = -1;
var diffs = [];
var b_diffs = [];

var special_cmd = false;

var pb_pointer = 0;

var playback_timeout_ref;
var playback = false;
var pb_paused = false;

function getTime() {
    return (new Date).getTime();
}

function start_pb() {
    playback = true;
    pb_paused = false;
    
    playback_buffer = new Buffer('', 0);
    playback_buffer.set();
    pb_pointer = 0;
    if (diffs.length > 0) {
        r_playback();
    }
}

function pause_pb() {
    pb_paused = true;
    window.clearTimeout(playback_timeout_ref);
}

function step_pb() {
    if (pb_pointer >= diffs.length) {
        return;
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

    pb_pointer++;
    status();
}

function r_playback() {
    step_pb();

    playback_timeout_ref = window.setTimeout(r_playback, diff[3]);
}

function unwind() {
    if (b_diffs.length > 0) {
        diffs.push(b_diffs.shift());
        unwind();
    } 
}

track_changes = function() {
    if (! playback) {
        if (lc_time < 0) { lc_time = getTime(); }

        now_text = deft.value;
        now_cursor_pos = getCaret(deft);

        d_tx = now_text.length - text.length;
        d_cr = now_cursor_pos - cursor_pos;

        if (now_text == text || special_cmd) {
            change_type = "no change";
            special_cmd = false;
        } else {
            change_time = getTime(); 
            d_t = change_time - lc_time;
            changes++;

            if (d_tx == d_cr) {
                if (now_text.length > text.length) {
                    change_type = "simple insert";
                    diff = [1, cursor_pos, now_text.substr(cursor_pos, d_cr), d_t];
                    diffs.push(diff);
                } else {
                    change_type = "simple delete";
                    diff = [0, cursor_pos, text.substr(now_cursor_pos, -d_tx), d_t];
                    diffs.push(diff);
                }
            } else {
                change_type = "composite";
                diff = [0, cursor_pos, text.substr(cursor_pos, d_cr - d_tx), d_t];
                diffs.push(diff);
                if (d_cr > 0) {
                    diff = [1, cursor_pos, now_text.substr(cursor_pos, d_cr), 10];
                    diffs.push(diff);
                }
            }

            text = now_text;
            lc_time = change_time;
        }

        cursor_pos = getCaret(deft);
        status();
    }
};


deft.onmouseup = track_changes;
deft.onmousemove = track_changes;
deft.onkeyup = track_changes;

//deft.oninput = track_changes;

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

function commit() {
    sbuffer = getBuffer();
    buffers = [sbuffer];
    current = 0;
    commits++;
}

function save() {
    buffer = getBuffer();
    buffers[current] = buffer;
}

function do_cmd(f) {
    save();

    special_cmd = true;
    change_time = getTime(); 
    d_t = change_time - lc_time;
    diffs.push([0, deft.value.length, deft.value, d_t]);

    f();

    diffs.push([1, 0, deft.value, d_t]);
    lc_time = change_time;
}

function scratch() {
    do_cmd(function() {
        current = buffers.length;
        buffers.push(sbuffer);
        sbuffer.set();
    });
}

function right() {
    do_cmd(function() {
        current = (current + 1) % buffers.length;
        buffers[current].set();
    });
}

function left() {
    do_cmd(function() {
        current = current == 0 ? (buffers.length - 1) : current - 1;
        buffers[current].set();
    });
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
