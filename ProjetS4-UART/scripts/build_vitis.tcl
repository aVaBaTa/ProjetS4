# Script xsct pour reconstruire la plateforme Vitis et l'application

set script_dir [file dirname [info script]]
set project_dir [file normalize "$script_dir/.."]

# Workspace temporaire (non versionne)
set workspace "$project_dir/workspace"
file mkdir $workspace
setws $workspace

# Creer la plateforme depuis le XSA
platform create \
    -name platform_main \
    -hw "$project_dir/platform_main/hw/uart_wrapper.xsa" \
    -proc ps7_cortexa9_0 \
    -os standalone \
    -out "$project_dir/platform_main"

platform generate
puts "Plateforme generee."

# Creer l'application hello_world
app create \
    -name hello_world \
    -platform platform_main \
    -domain standalone_ps7_cortexa9_0 \
    -template {Hello World} \
    -lang C \
    -out "$project_dir/hello_world"

# Copier les sources personnalisees
file copy -force "$project_dir/hello_world/src/helloworld.c"  "$workspace/hello_world/src/helloworld.c"
file copy -force "$project_dir/hello_world/src/platform.c"    "$workspace/hello_world/src/platform.c"
file copy -force "$project_dir/hello_world/src/platform.h"    "$workspace/hello_world/src/platform.h"

# Build
app build -name hello_world
puts "Application hello_world construite."
