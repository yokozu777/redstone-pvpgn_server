#!/bin/sh
# Copy stock PvPGN files that are not already on the host, then render configs.
set -eu

DEFAULTS="${DEFAULTS:-/opt/pvpgn-defaults}"
OUT_ETC="${OUT_ETC:-/out/etc}"
OUT_VAR="${OUT_VAR:-/out/var}"

copy_missing() {
  src=$1
  dest=$2
  if [ ! -d "$src" ]; then
    echo "seed: no defaults at $src" >&2
    exit 1
  fi
  mkdir -p "$dest"
  find "$src" -type d | while read -r dir; do
    rel=${dir#"$src"/}
    if [ "$rel" = "$dir" ]; then
      mkdir -p "$dest"
    else
      mkdir -p "$dest/$rel"
    fi
  done
  find "$src" \( -type f -o -type l \) | while read -r file; do
    rel=${file#"$src"/}
    if [ ! -e "$dest/$rel" ] && [ ! -L "$dest/$rel" ]; then
      mkdir -p "$(dirname "$dest/$rel")"
      cp -a "$file" "$dest/$rel"
    fi
  done
}

copy_missing "$DEFAULTS/etc" "$OUT_ETC"
copy_missing "$DEFAULTS/var" "$OUT_VAR"

if [ ! -e "$OUT_ETC/topics.conf" ]; then
  cat >"$OUT_ETC/topics.conf" <<'EOF'
{
	"topics": {
		"Chat": "This is the public chat channel. Feel free to chat...",
		"Moderated Support": "Support is provided in this channel..."
	}
}
EOF
fi

if [ ! -e "$OUT_ETC/d2server.ini" ]; then
  printf '%s\n' '# Opened by d2cs. Game rules stay in the D2GS registry.' >"$OUT_ETC/d2server.ini"
fi

exec /bin/sh /render.sh
