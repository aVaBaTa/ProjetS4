import vitis
import shutil
import os

client = vitis.create_client()

script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.normpath(os.path.join(script_dir, ".."))
workspace = os.path.join(project_dir, "workspace")
xsa = os.path.join(project_dir, "platform_main", "hw", "uart_wrapper.xsa")

client.set_workspace(workspace)

# Plateforme
platform = client.create_platform_component(
    name="platform_main",
    hw_design=xsa,
    os="standalone",
    cpu="ps7_cortexa9_0"
)
status = platform.build()
print(f"Plateforme generee. Status: {status}")

xpfm = os.path.join(workspace, "platform_main", "export", "platform_main", "platform_main.xpfm")
if not os.path.exists(xpfm):
    raise Exception(f"Platform export not found: {xpfm}")

# Application
app = client.create_app_component(
    name="hello_world",
    platform=xpfm,
    domain="standalone_domain",
    template="empty_application"
)

# Copier les sources AVANT le build
src = os.path.join(project_dir, "hello_world", "src")
dst = os.path.join(workspace, "hello_world", "src")
for f in ["helloworld.c", "platform.c", "platform.h", "lscript.ld"]:
    src_file = os.path.join(src, f)
    if os.path.exists(src_file):
        shutil.copy2(src_file, os.path.join(dst, f))

app.build()
print("Application hello_world construite.")

client.close()