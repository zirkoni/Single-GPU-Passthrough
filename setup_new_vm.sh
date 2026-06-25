#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage"
    echo "Create: $0 <guest_name>"
    echo "Remove: $0 <guest_name> -d"
    echo "List:   $0 -l"
    exit 1
fi

GUEST_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"
SRC_QEMU="$SCRIPT_DIR/qemu"
SRC_START="$SCRIPT_DIR/start.sh"
SRC_STOP="$SCRIPT_DIR/stop.sh"

TARGET_QEMU="/etc/libvirt/hooks/qemu"
GUEST_HOOK_BASE_DIR="/etc/libvirt/hooks/qemu.d"
GUEST_HOOK_DIR="$GUEST_HOOK_BASE_DIR/$GUEST_NAME"
TARGET_START="$GUEST_HOOK_DIR/prepare/begin/start.sh"
TARGET_STOP="$GUEST_HOOK_DIR/release/end/stop.sh"
GUEST_XML="/etc/libvirt/qemu/$GUEST_NAME.xml"

if [ "$1" = "-l" ]; then
    ls -la $GUEST_HOOK_BASE_DIR
    exit 0
fi

if [ "$2" = "-d" ]; then
    sudo rm -rf $GUEST_HOOK_DIR
    exit 0
fi

if [ ! -f "$GUEST_XML" ]; then
    echo "Error: File $GUEST_XML does not exist."
    echo "Make sure the guest name is ${GUEST_NAME} and you have started the guest installation already."
    echo "You should also have added the vBIOS path in the file."
    exit 1
fi

create_link() {
    local src="$1"
    local dst="$2"

    if sudo test -L "$dst"; then
        echo "Link already exists: $dst"
    elif sudo test -e "$dst"; then
        echo "File exists and is not a link: $dst"
    else
        sudo mkdir -p "$(dirname "$dst")"
        sudo ln -s "$src" "$dst"
        echo "Created link: $dst -> $src"
    fi
}

create_link "$SRC_QEMU" "$TARGET_QEMU"
create_link "$SRC_START" "$TARGET_START"
create_link "$SRC_STOP" "$TARGET_STOP"
