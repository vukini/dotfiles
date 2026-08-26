#!/bin/bash
# Import wallpapers from the KDE wallpaper packages in /usr/share/wallpapers.
#
# Layout of a package:
#   <Name>/contents/screenshot.png        <- 31-62KB thumbnail, NOT a wallpaper
#   <Name>/contents/images/<WxH>.<ext>    <- the real thing
#   <Name>/contents/images_dark/<WxH>.<ext>
#
# So the filter is by path, not extension alone: matching '*.png' anywhere would
# drag in the thumbnails, and matching '*.jpg' anywhere already did (there are
# 15 screenshot.jpg in the tree).
#
# Names are <Package>[-dark]-<WxH>.<ext> rather than the bare <WxH>.<ext> the
# source uses. Every package names its files by resolution, so basenames collide
# constantly -- and a package's images/ and images_dark/ copies collide with
# each other exactly, which would make the dark variants indistinguishable.
#
# Re-running is idempotent: an existing destination is left alone. The previous
# version added a numeric prefix instead, so each run re-copied the whole set
# (which is where names like 10_2560x1600.jpg came from).

SRC_DIR="${SRC_DIR:-/usr/share/wallpapers}"
DEST_DIR="${DEST_DIR:-$HOME/wallpapers}"
mkdir -p "$DEST_DIR" || exit 1

copied=0 skipped=0

while IFS= read -r f; do
    # .../<Package>/contents/images[_dark]/<WxH>.<ext>
    variant=$(basename "$(dirname "$f")")        # images | images_dark
    pkg=$(basename "$(dirname "$(dirname "$(dirname "$f")")")")
    base=$(basename "$f")

    case "$variant" in
        images_dark) name="${pkg}-dark-${base}" ;;
        *)           name="${pkg}-${base}"      ;;
    esac

    dest="$DEST_DIR/$name"
    if [ -e "$dest" ]; then
        skipped=$((skipped + 1))
        continue
    fi
    cp -- "$f" "$dest" && { echo "$dest"; copied=$((copied + 1)); }
done < <(find "$SRC_DIR" -type f -ipath '*/contents/images*/*' \
              \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
                 -o -iname '*.webp' \) | sort)

echo "copied $copied, already present $skipped"
