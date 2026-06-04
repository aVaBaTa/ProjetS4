set script_dir [file dirname [info script]]
set project_dir [file normalize "$script_dir/.."]

setws $project_dir/workspace
file mkdir $project_dir/workspace

platform create \
    -name platform_main \
    -hw "$project_dir/platform_main/hw/uart_wrapper.xsa" \
    -proc ps7_cortexa9_0 \
    -os standalone \
    -out "$project_dir/workspace"

platform generate
puts "Plateforme generee."

app create \
    -name hello_world \
    -platform platform_main \
    -domain standalone_ps7_cortexa9_0 \
    -template {Hello World} \
    -lang C

file copy -force "$project_dir/hello_world/src/helloworld.c" "$project_dir/workspace/hello_world/src/helloworld.c"
file copy -force "$project_dir/hello_world/src/platform.c"   "$project_dir/workspace/hello_world/src/platform.c"
file copy -force "$project_dir/hello_world/src/platform.h"   "$project_dir/workspace/hello_world/src/platform.h"

app build -name hello_world
puts "Application hello_world construite."