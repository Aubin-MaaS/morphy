#!/bin/bash
# ZikZak Morphy 2.2.0
# -------------------------
# restore_dev_mode.sh
#
# This script converts all package dependencies to path dependencies
# for local development, making it easier to develop and test changes
# across multiple packages simultaneously.
#

echo "🔥 ZikZak Morphy - Restoring Development Mode 🔥"
echo "Converting all dependencies to path dependencies..."

# Root directory of the project
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Root directory: $ROOT_DIR"

# Function to update pubspec.yaml for development mode
update_for_dev_mode() {
  local package_dir=$1
  local pubspec_file="$package_dir/pubspec.yaml"

  if [ ! -f "$pubspec_file" ]; then
    echo "⚠️ Pubspec file not found at $pubspec_file"
    return
  fi

  echo "Processing $pubspec_file"

  # Replace zikzak_morphy_annotation versioned dependency with path
  sed -i.tmp -E 's|zikzak_morphy_annotation: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_morphy_annotation:\n    path: ../zikzak_morphy_annotation|g' "$pubspec_file"

  # Replace zikzak_morphy versioned dependency with path (for example package)
  sed -i.tmp -E 's|zikzak_morphy: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_morphy:\n    path: ../zikzak_morphy|g' "$pubspec_file"

  # Clean up temporary files
  rm -f "${pubspec_file}.tmp"

  echo "✅ Updated $pubspec_file to use path dependencies"
}

# Process main package
if [ -d "$ROOT_DIR/zikzak_morphy" ]; then
  update_for_dev_mode "$ROOT_DIR/zikzak_morphy"
else
  echo "⚠️ Directory not found: $ROOT_DIR/zikzak_morphy"
fi

# Process example package
if [ -d "$ROOT_DIR/example" ]; then
  update_for_dev_mode "$ROOT_DIR/example"
else
  echo "⚠️ Directory not found: $ROOT_DIR/example"
fi

# Run flutter pub get on all packages
echo "Running 'flutter pub get' on all packages..."
for package in zikzak_morphy zikzak_morphy_annotation example; do
  if [ -d "$ROOT_DIR/$package" ]; then
    echo "Getting dependencies for $package..."
    (cd "$ROOT_DIR/$package" && flutter pub get)
  fi
done

# Verify dev setup is correct
echo ""
echo "🔬 VERIFYING DEVELOPMENT SETUP 🔬"
verify_issues=0

# Check zikzak_morphy has path dependency
if [ -f "$ROOT_DIR/zikzak_morphy/pubspec.yaml" ]; then
  versioned_deps=$(grep "zikzak_morphy_annotation: \^[0-9]" "$ROOT_DIR/zikzak_morphy/pubspec.yaml" 2>/dev/null | wc -l)
  path_deps=$(grep "path:.*\.\./zikzak_morphy_annotation" "$ROOT_DIR/zikzak_morphy/pubspec.yaml" 2>/dev/null | wc -l)

  if [ "$versioned_deps" -gt 0 ]; then
    echo "⚠️ WARNING: zikzak_morphy still has versioned dependencies!"
    verify_issues=$((verify_issues + 1))
  fi

  if [ "$path_deps" -lt 1 ]; then
    echo "⚠️ WARNING: zikzak_morphy is missing path dependency!"
    verify_issues=$((verify_issues + 1))
  else
    echo "✅ zikzak_morphy: Found path dependency"
  fi
fi

# Check example has path dependencies
if [ -f "$ROOT_DIR/example/pubspec.yaml" ]; then
  morphy_versioned=$(grep "zikzak_morphy: \^[0-9]" "$ROOT_DIR/example/pubspec.yaml" 2>/dev/null | wc -l)
  annotation_versioned=$(grep "zikzak_morphy_annotation: \^[0-9]" "$ROOT_DIR/example/pubspec.yaml" 2>/dev/null | wc -l)
  morphy_path=$(grep "path:.*\.\./zikzak_morphy" "$ROOT_DIR/example/pubspec.yaml" 2>/dev/null | wc -l)
  annotation_path=$(grep "path:.*\.\./zikzak_morphy_annotation" "$ROOT_DIR/example/pubspec.yaml" 2>/dev/null | wc -l)

  if [ "$morphy_versioned" -gt 0 ] || [ "$annotation_versioned" -gt 0 ]; then
    echo "⚠️ WARNING: example still has versioned dependencies!"
    verify_issues=$((verify_issues + 1))
  fi

  if [ "$morphy_path" -lt 1 ] || [ "$annotation_path" -lt 1 ]; then
    echo "⚠️ WARNING: example is missing path dependencies!"
    verify_issues=$((verify_issues + 1))
  else
    echo "✅ example: Found path dependencies"
  fi
fi

if [ $verify_issues -eq 0 ]; then
  echo "✅ VERIFICATION COMPLETE: Development setup is PERFECT!"
else
  echo "⚠️ VERIFICATION FOUND $verify_issues ISSUES: You may need to manually fix some dependencies."
fi

echo ""
echo "🔥🔥🔥 DEVELOPMENT MODE SETUP COMPLETE! 🔥🔥🔥"
echo "All packages now use path dependencies for MAXIMUM DEVELOPMENT POWER!"
echo "You can now make changes across packages and test them together like a CODING BEAST!"
echo ""
