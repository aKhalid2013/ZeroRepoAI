#!/usr/bin/env bash
set -euo pipefail

title="${1:-}"
if [ -z "$title" ]; then
  echo "Usage: $0 <title>"
  exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
features_dir="$root/docs/FEATURES"
template="$features_dir/_TEMPLATE.md"

if [ ! -f "$template" ]; then
  echo "Template not found: $template"
  exit 1
fi

max=0
for file in "$features_dir"/F-*.md; do
  [ -e "$file" ] || continue
  base="$(basename "$file")"
  if [[ "$base" =~ ^F-([0-9]{3}) ]]; then
    num="${BASH_REMATCH[1]}"
    num=$((10#$num))
    if [ "$num" -gt "$max" ]; then
      max="$num"
    fi
  fi
done

next=$((max + 1))
id="$(printf "F-%03d" "$next")"
slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g')"
if [ -z "$slug" ]; then
  echo "Title must include alphanumeric characters for slug generation."
  exit 1
fi

filename="$id-$slug.md"
dest="$features_dir/$filename"

if [ -e "$dest" ]; then
  echo "File exists: $dest"
  exit 1
fi

escape_sed() {
  printf "%s" "$1" | sed -e 's/[\/&|]/\\&/g'
}

id_escaped="$(escape_sed "$id")"
title_escaped="$(escape_sed "$title")"

sed -e "s|F-xxx|$id_escaped|g" -e "s|<title>|$title_escaped|g" "$template" > "$dest"
echo "Created $dest"
