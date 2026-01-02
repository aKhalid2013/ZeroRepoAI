#!/usr/bin/env bash
set -euo pipefail

title="${1:-}"
if [ -z "$title" ]; then
  echo "Usage: $0 <title>"
  exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
adr_dir="$root/docs/ADR"
template="$adr_dir/0000-adr-template.md"

if [ ! -f "$template" ]; then
  echo "Template not found: $template"
  exit 1
fi

max=0
for file in "$adr_dir"/*.md; do
  [ -e "$file" ] || continue
  base="$(basename "$file")"
  if [[ "$base" =~ ^([0-9]{4}) ]]; then
    num="${BASH_REMATCH[1]}"
    num=$((10#$num))
    if [ "$num" -gt "$max" ]; then
      max="$num"
    fi
  fi
done

next=$((max + 1))
id="$(printf "%04d" "$next")"
slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g')"
if [ -z "$slug" ]; then
  echo "Title must include alphanumeric characters for slug generation."
  exit 1
fi

filename="$id-$slug.md"
dest="$adr_dir/$filename"

if [ -e "$dest" ]; then
  echo "File exists: $dest"
  exit 1
fi

escape_sed() {
  printf "%s" "$1" | sed -e 's/[\/&|]/\\&/g'
}

id_escaped="$(escape_sed "$id")"
title_escaped="$(escape_sed "$title")"

sed -e "s|ADR 0000|ADR $id_escaped|g" -e "s|<title>|$title_escaped|g" "$template" > "$dest"
echo "Created $dest"
