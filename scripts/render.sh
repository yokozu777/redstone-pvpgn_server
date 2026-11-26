#!/bin/sh
# Fill templates from the environment. Values are inserted literally, so "&" stays "&".
set -eu

OUT_ETC="${OUT_ETC:-/out/etc}"
OUT_CONF="${OUT_CONF:-/out/conf}"
TEMPLATES="${TEMPLATES:-/templates}"

test -d "$OUT_ETC"
test -d "$OUT_CONF"
test -d "$TEMPLATES"

hex_from() {
  dec=$(printenv "$1")
  case "$dec" in
    ''|*[!0-9]*)
      echo "not a decimal: $1=$dec" >&2
      exit 1
      ;;
  esac
  export "$2=$(printf '%08x' "$dec")"
}

hex_from D2GS_AUTOUPDATE D2GS_AUTOUPDATE_HEX
hex_from D2GS_AUTOUPDATEVER D2GS_AUTOUPDATEVER_HEX
hex_from D2GS_AUTOUPDATETIMEOUT D2GS_AUTOUPDATETIMEOUT_HEX
hex_from D2CS_PORT D2CS_PORT_HEX
hex_from D2DBS_PORT D2DBS_PORT_HEX
hex_from D2GS_MAXGAMES D2GS_MAXGAMES_HEX
hex_from D2GS_MAXGAMELIFE D2GS_MAXGAMELIFE_HEX
hex_from D2GS_ADMINPORT D2GS_ADMINPORT_HEX
hex_from D2GS_ADMINTIMEOUT D2GS_ADMINTIMEOUT_HEX
hex_from D2GS_ENABLENTMODE D2GS_ENABLENTMODE_HEX
hex_from D2GS_ENABLEPRECACHEMODE D2GS_ENABLEPRECACHEMODE_HEX
hex_from D2GS_IDLESLEEP D2GS_IDLESLEEP_HEX
hex_from D2GS_BUSYSLEEP D2GS_BUSYSLEEP_HEX
hex_from D2GS_CHARPENDINGTIMEOUT D2GS_CHARPENDINGTIMEOUT_HEX
hex_from D2GS_DEBUGNETPACKET D2GS_DEBUGNETPACKET_HEX
hex_from D2GS_DEBUGEVENTCALLBACK D2GS_DEBUGEVENTCALLBACK_HEX
hex_from D2GS_ENABLEGSLOG D2GS_ENABLEGSLOG_HEX
hex_from D2GS_ENABLEGELOG D2GS_ENABLEGELOG_HEX
hex_from D2GS_ENABLEGEMSG D2GS_ENABLEGEMSG_HEX
hex_from D2GS_ENABLEGEPATCH D2GS_ENABLEGEPATCH_HEX
hex_from D2GS_INTERVALRECONNECTD2CS D2GS_INTERVALRECONNECTD2CS_HEX
hex_from D2GS_MULTICPUMASK D2GS_MULTICPUMASK_HEX
hex_from D2GS_MAXPREFERUSERS D2GS_MAXPREFERUSERS_HEX
hex_from D2GS_MAXPACKETPERSECOND D2GS_MAXPACKETPERSECOND_HEX

render_file() {
  src=$1
  dst=$2
  tmp=$(mktemp)
  cp "$src" "$tmp"
  names=$(grep -oE '\$\{[A-Za-z0-9_]+\}' "$src" | sed 's/^\${//;s/}$//' | awk '{ print length($0) " " $0 }' | sort -rn | cut -d' ' -f2- | awk '!seen[$0]++')
  for name in $names; do
    if ! printenv "$name" >/dev/null 2>&1; then
      echo "missing $name" >&2
      exit 1
    fi
    printf '%s' "$(printenv "$name")" > /tmp/render.val
    awk -v key="\${$name}" '
      BEGIN {
        val = ""
        while ((getline line < "/tmp/render.val") > 0) {
          if (val == "")
            val = line
          else
            val = val "\n" line
        }
        close("/tmp/render.val")
      }
      {
        s = $0
        out = ""
        klen = length(key)
        while ((p = index(s, key)) > 0) {
          out = out substr(s, 1, p - 1) val
          s = substr(s, p + klen)
        }
        print out s
      }
    ' "$tmp" > "$tmp.next"
    mv "$tmp.next" "$tmp"
  done
  if grep -F '${' "$tmp" >/dev/null; then
    echo "unresolved placeholder in $dst" >&2
    grep -F '${' "$tmp" >&2
    exit 1
  fi
  cat "$tmp" > "${dst}.tmp"
  mv "${dst}.tmp" "$dst"
  rm -f "$tmp"
}

render_file "$TEMPLATES/bnetd.conf" "$OUT_ETC/bnetd.conf"
render_file "$TEMPLATES/d2cs.conf" "$OUT_ETC/d2cs.conf"
render_file "$TEMPLATES/d2dbs.conf" "$OUT_ETC/d2dbs.conf"
render_file "$TEMPLATES/address_translation.conf" "$OUT_ETC/address_translation.conf"
render_file "$TEMPLATES/realm.conf" "$OUT_ETC/realm.conf"
render_file "$TEMPLATES/d2gs.reg" "$OUT_CONF/d2gs.reg"
/bin/sh /news.sh
