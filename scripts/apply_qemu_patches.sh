#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: apply_qemu_patches.sh --src-dir DIR --primary-patch FILE [--with-qemu-exp] [--with-vss-fix]

Applies the qemu-3dfx patch stack to an extracted QEMU source tree.
Run this script from the repository root.
EOF
}

src_dir=""
primary_patch=""
with_qemu_exp=0
with_vss_fix=0
repo_root="$(pwd)"

patch_input() {
    local patch_path="$1"

    if [[ "$patch_path" = /* ]]; then
        printf '%s' "$patch_path"
    else
        printf '%s' "../$patch_path"
    fi
}

vss_fix_already_upstream() {
    grep -q "CONFIG_CONVERT_STRING_TO_BSTR" qga/vss-win32/install.cpp && \
    grep -q "int qemu_ftruncate64(int fd, int64_t length)" util/oslib-win32.c && \
    ! grep -q "int qemu_ftruncate64(int fd, int64_t length)" block/file-win32.c
}

vss_fix_report_markers() {
    local bfile_marker="absent"
    if grep -q "int qemu_ftruncate64(int fd, int64_t length)" block/file-win32.c; then
        bfile_marker="present"
    fi

    echo "VSS upstream markers detected:" \
         "install.cpp:CONFIG_CONVERT_STRING_TO_BSTR="$(grep -n "CONFIG_CONVERT_STRING_TO_BSTR" qga/vss-win32/install.cpp | head -1) \
         "util/oslib-win32.c:qemu_ftruncate64="$(grep -n "int qemu_ftruncate64(int fd, int64_t length)" util/oslib-win32.c | head -1) \
         "block/file-win32.c:qemu_ftruncate64=${bfile_marker}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --src-dir)
            src_dir="$2"
            shift 2
            ;;
        --primary-patch)
            primary_patch="$2"
            shift 2
            ;;
        --with-qemu-exp)
            with_qemu_exp=1
            shift
            ;;
        --with-vss-fix)
            with_vss_fix=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$src_dir" || -z "$primary_patch" ]]; then
    usage >&2
    exit 1
fi

if [[ ! -d "$src_dir" ]]; then
    echo "Source directory not found: $src_dir" >&2
    exit 1
fi

if [[ ! -f "$primary_patch" ]]; then
    echo "Primary patch not found: $primary_patch" >&2
    exit 1
fi

echo "Adding qemu-3dfx source overlays"
rsync -rv "$repo_root/qemu-0/hw/3dfx" "$repo_root/qemu-1/hw/mesa" "$src_dir/hw/"

pushd "$src_dir" >/dev/null

echo "Applying primary patch: $primary_patch"
if ! patch -p0 -i "$(patch_input "$primary_patch")"; then
    # QEMU master refactored WHPX memory mapping out of target/i386/whpx/whpx-all.c.
    # Allow this known reject and apply a compatibility helper in accel/whpx/whpx-common.c.
    if [[ -f "target/i386/whpx/whpx-all.c.rej" && -f "accel/whpx/whpx-common.c" ]]; then
        echo "Primary patch had legacy WHPX hunk rejects on refactored tree; applying compatibility patch"

        if ! grep -q "whpx_update_guest_pa_range" include/system/whpx.h; then
            sed -i '/# ifdef CONFIG_WHPX/i\void whpx_update_guest_pa_range(uint64_t start_pa, uint64_t size, void *host_va, int readonly, int add);' include/system/whpx.h
        fi

        git apply "$repo_root/qemu-exp/whpx-master-compat.patch"
        rm -f target/i386/whpx/whpx-all.c.rej
    else
        echo "Primary patch failed" >&2
        exit 1
    fi
fi

if [[ $with_qemu_exp -eq 1 ]]; then
    echo "Applying qemu-exp patches"
    if [[ $with_vss_fix -eq 1 ]]; then
        if vss_fix_already_upstream; then
            vss_fix_report_markers
            echo "Skipping legacy VSS patch (equivalent behavior already in tree)"
        elif ! patch --batch -p0 -i "$repo_root/qemu-exp/qemu-windows-vss-mingw-fix.patch"; then
            echo "VSS fix patch did not apply cleanly; checking for upstream-equivalent changes"

            rm -f qga/vss-win32/install.cpp.rej block/file-win32.c.rej util/oslib-win32.c.rej

            if vss_fix_already_upstream; then
                vss_fix_report_markers
                echo "Continuing: legacy VSS patch content is already upstream-equivalent"
            else
                echo "VSS fix patch failed and equivalent upstream changes were not detected" >&2
                exit 1
            fi
        fi
    fi
    # clipboard patch may need offsets due to primary patch modifying same files
    if ! git apply "$repo_root/qemu-exp/qemu-sdl-clipboard.patch" 2>/dev/null; then
        echo "Clipboard patch failed with git apply, trying with patch utility"
        patch -p1 -i "$repo_root/qemu-exp/qemu-sdl-clipboard.patch" || true
    fi
    git apply "$repo_root/qemu-exp/whpx-unrecoverable-reset.patch"
    git apply "$repo_root/qemu-exp/qemu-sdl-gles-angle.patch"

fi

echo "Applying virgil3d patches"
patch -p0 -i "$repo_root/virgil3d/0001-Virgil3D-with-SDL2-OpenGL.patch"
patch -p0 -i "$repo_root/virgil3d/0002-Virgil3D-macOS-GLSL-version.patch"

echo "Signing commit id to source tree"
bash "$repo_root/scripts/sign_commit"

popd >/dev/null
