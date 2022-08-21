#!/bin/sh
set -e
set -u

my_targets="$(zig targets | jq -r '.libc[]' | sort -u)"

for my_target in $my_targets; do
    cat << EOF >> "${HOME}/.local/bin/zig-cc-${my_target}"
#!/bin/sh
set -e
set -u

"\${HOME}/.local/opt/zig/zig" cc -target ${my_target} \$@
EOF

    chmod a+x "${HOME}/.local/bin/zig-cc-${my_target}"
done

for my_target in $my_targets; do
    cat << EOF >> "${HOME}/.local/bin/zig-cpp-${my_target}"
#!/bin/sh
set -e
set -u

"\${HOME}/.local/opt/zig/zig" c++ -target ${my_target} \$@
EOF

    chmod a+x "${HOME}/.local/bin/zig-cpp-${my_target}"
done
