#!/bin/bash
#
# VimF12: 2tmux
# @c: 0f"l"tyt":let @r="bats -f '".escape(@t, '\[]().')."' transmission-add.bats"|w

# load code as function
source ../transmission-add

mkconf() {
    local conf=./transmission_test.conf
    cat << END > $conf
TRANSMISSION_ADDR=10.0.0.22
TRANSMISSION_PORT=9999
END
    echo $conf
}

@test "loadconf" {
  # ensure default value from the code
  [[ "$TRANSMISSION_PORT" == "9091" ]]

  # create a fake config
  conf=$(mkconf)
  [[ ! -z "$conf" ]]

  # doesn't modify env if run with "run"
  loadconf $conf
  [[ "$TRANSMISSION_PORT" == "9999" ]]
}

@test "mktmpdir" {
    run mktmpdir "./tmp"
    [[ -d "./tmp" ]]
    rmdir ./tmp
}

@test "readarg" {
    f=this_file_exists
    touch $f
    readarg $f
    [[ "$TORRENT_FILE" == "$f" ]]
}

@test "transmission_add" {
    # this is the config, not the test config in ./test/
    loadconf ../transmission.conf || true
    [[ ! -z "$TRANSMISSION_ADDR" ]]
    [[ ! -z "$TRANSMISSION_PORT" ]]

    # download an example torrent file
    torrent_example_url="https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/debian-10.3.0-amd64-netinst.iso.torrent"
    local_torrent=${torrent_example_url##*/}
    wget -O $local_torrent "$torrent_example_url"
    [[ -e $local_torrent ]]
    TMPDIR=.
    run transmission_add $local_torrent
    [[ "$status" -eq 0 ]]
}

# mock notifier
notify-send() {
    echo "$@"
}

@test "notify" {
    run notify 0 my_message
    regexp="Transmission add my_message --icon=dialog-information"
    echo "$output"
    [[ "$output" =~ $regexp ]]

    run notify 1 my_error_message
    regexp="Transmission add my_error_message --icon=dialog-error"
    [[ "$output" =~ $regexp ]]
}
