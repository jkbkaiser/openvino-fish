set INIT_DIR (pwd)

function abs_path
    set script_path (eval echo "$argv[1]")
    set directory (dirname "$script_path")
    builtin cd "$directory" || exit
    pwd -P
end

set SCRIPT_DIR (abs_path (status -f)) >/dev/null 2>&1
set -x INSTALLDIR "$SCRIPT_DIR"
set -x INTEL_OPENVINO_DIR "$INSTALLDIR"

# parse command line options
while test (count $argv) -gt 0
    set key $argv[1]
    switch $key
        case '-pyver'
            set python_version $argv[2]
            echo python_version = "$python_version"
            set -e argv[2]
            set -e argv[1]
            continue
        case '*'
            # unknown option
            set -e argv[1]
    end
end

if test -e "$INSTALLDIR/runtime"
    set -x InferenceEngine_DIR "$INSTALLDIR/runtime/cmake"
    set -x ngraph_DIR "$INSTALLDIR/runtime/cmake"
    set -x OpenVINO_DIR "$INSTALLDIR/runtime/cmake"

    set system_type (/bin/ls "$INSTALLDIR/runtime/lib/")
    set OV_PLUGINS_PATH "$INSTALLDIR/runtime/lib/$system_type"

    if string match -q 'darwin*' "$OSTYPE"
        if test -n "$DYLD_LIBRARY_PATH"
            set -x DYLD_LIBRARY_PATH "{$OV_PLUGINS_PATH}/Release:{$OV_PLUGINS_PATH}/Debug:$DYLD_LIBRARY_PATH"
        else
            set -x DYLD_LIBRARY_PATH "{$OV_PLUGINS_PATH}/Release:{$OV_PLUGINS_PATH}/Debug"
        end
        if test -n "$LD_LIBRARY_PATH"
            set -x LD_LIBRARY_PATH "{$OV_PLUGINS_PATH}/Release:{$OV_PLUGINS_PATH}/Debug:$LD_LIBRARY_PATH"
        else
            set -x LD_LIBRARY_PATH "{$OV_PLUGINS_PATH}/Release:{$OV_PLUGINS_PATH}/Debug"
        end
        if test -n "$PKG_CONFIG_PATH"
            set -x PKG_CONFIG_PATH "{$OV_PLUGINS_PATH}/Release/pkgconfig:$PKG_CONFIG_PATH"
        else
            set -x PKG_CONFIG_PATH "{$OV_PLUGINS_PATH}/Release/pkgconfig"
        end
    else
        if test -n "$LD_LIBRARY_PATH"
            set -x LD_LIBRARY_PATH "{$OV_PLUGINS_PATH}:$LD_LIBRARY_PATH"
        else
            set -x LD_LIBRARY_PATH "$OV_PLUGINS_PATH"
        end
        if test -n "$PKG_CONFIG_PATH"
            set -x PKG_CONFIG_PATH "{$OV_PLUGINS_PATH}/pkgconfig:$PKG_CONFIG_PATH"
        else
            set -x PKG_CONFIG_PATH "$OV_PLUGINS_PATH/pkgconfig"
        end
    end

    if test -e "$INSTALLDIR/runtime/3rdparty/tbb"
        set tbb_lib_path "$INSTALLDIR/runtime/3rdparty/tbb/lib"
        if test -d "$tbb_lib_path/$system_type"
            set lib_path (find "$tbb_lib_path/$system_type" -name "libtbb*" | sort -r | head -n1)
            if test -n "$lib_path"
                set tbb_lib_path (dirname "$lib_path")
            end
        end

        if /bin/ls "$tbb_lib_path/libtbb*" >/dev/null 2>&1
            if string match -q 'darwin*' "$OSTYPE"
                if test -n "$DYLD_LIBRARY_PATH"
                    set -x DYLD_LIBRARY_PATH "$tbb_lib_path:$DYLD_LIBRARY_PATH"
                else
                    set -x DYLD_LIBRARY_PATH "$tbb_lib_path"
                end
            end
            if test -n "$LD_LIBRARY_PATH"
                set -x LD_LIBRARY_PATH "$tbb_lib_path:$LD_LIBRARY_PATH"
            else
                set -x LD_LIBRARY_PATH "$tbb_lib_path"
            end
        else
            echo "[setupvars.sh] WARNING: Directory with TBB libraries is not detected. Please, add TBB libraries to LD_LIBRARY_PATH / DYLD_LIBRARY_PATH manually"
        end
        set -e tbb_lib_path

        if test -e "$INSTALLDIR/runtime/3rdparty/tbb/lib/cmake/TBB"
            set -x TBB_DIR "$INSTALLDIR/runtime/3rdparty/tbb/lib/cmake/TBB"
        else if test -e "$INSTALLDIR/runtime/3rdparty/tbb/lib/cmake/tbb"
            set -x TBB_DIR "$INSTALLDIR/runtime/3rdparty/tbb/lib/cmake/tbb"
        else if test -e "$INSTALLDIR/runtime/3rdparty/tbb/lib64/cmake/TBB"
            set -x TBB_DIR "$INSTALLDIR/runtime/3rdparty/tbb/lib64/cmake/TBB"
        else if test -e "$INSTALLDIR/runtime/3rdparty/tbb/cmake"
            set -x TBB_DIR "$INSTALLDIR/runtime/3rdparty/tbb/cmake"
        else
            echo "[setupvars.sh] WARNING: TBB_DIR directory is not defined automatically by setupvars.sh. Please, set it manually to point to TBBConfig.cmake"
        end
    end

    set -e system_type
end

cd $INIT_DIR
