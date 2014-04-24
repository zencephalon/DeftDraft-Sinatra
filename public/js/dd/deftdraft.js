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

var pb_timeout_ref;
var playback = false;
var pb_paused = false;
var pb_dir = 1;

var just_loaded = true;

function getTime() {
    return (new Date).getTime();
}

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

track_changes = function() {
    if (just_loaded) {
        just_loaded = false;
        decode_diffs();
    }
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
                    add_diff(diff);
                } else {
                    change_type = "simple delete";
                    diff = [0, cursor_pos, text.substr(now_cursor_pos, -d_tx), d_t];
                    add_diff(diff);
                }
            } else {
                change_type = "composite";
                diff = [0, cursor_pos, text.substr(cursor_pos, d_cr - d_tx), d_t];
                add_diff(diff);
                if (d_cr > 0) {
                    diff = [1, cursor_pos, now_text.substr(cursor_pos, d_cr), 5];
                    add_diff(diff);
                }
            }

            text = now_text;
            lc_time = change_time;
        }

        cursor_pos = getCaret(deft);
        //$('#diffs').data(diffs);
        //document.getElementById("diffs").value = diffs;
        status();
    }
};

function add_diff(diff) {
    diffs.push(diff);
    diff_str = diff[0] + ',' + diff[1] + ',' + encodeURIComponent(diff[2]) + ',' + diff[3] + ';';
    document.getElementById('diffs').value += diff_str;
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
    return new Buffer(deft.value, getCaret(deft));
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
    add_diff([0, deft.value.length, deft.value, d_t]);

    f();

    add_diff([1, 0, deft.value, 10]);
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
