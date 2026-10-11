#!/bin/sh
set -eu
# Rebuild the offline editor using BodyFactory's installed Three.js dependency.
bodyfactory_path=${1:?Usage: scripts/build_body_pose_editor.sh /path/to/BodyFactory}
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bodyfactory_path=$(CDPATH= cd -- "$bodyfactory_path" && pwd)
pose_build_dir=$(mktemp -d /tmp/aicomposer-pose.XXXXXX)
trap 'rm -rf "$pose_build_dir"' EXIT
cp "$project_root"/Compositor/Resources/BodyPoseEditor.bundle/source/*.js "$pose_build_dir/"
cp "$project_root/scripts/test_body_pose_editor.mjs" "$pose_build_dir/test.mjs"
printf '%s\n' '{"type":"module"}' > "$pose_build_dir/package.json"
ln -s "$bodyfactory_path/node_modules" "$pose_build_dir/node_modules"
cd "$pose_build_dir"
node test.mjs
npx --yes esbuild@0.28.2 editor.js --bundle --minify --format=iife \
  --outfile="$project_root/Compositor/Resources/BodyPoseEditor.bundle/editor.js"
