@echo off
setlocal

set XILINX_VERSION=2024.1
set VIVADO=C:\Xilinx\Vivado\%XILINX_VERSION%\bin\vivado.bat
set XSCT=C:\Xilinx\Vitis\%XILINX_VERSION%\bin\xsct.bat

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

echo ============================================
echo  1. Reconstruction du projet Vivado
echo ============================================
call "%VIVADO%" -mode batch -source "%SCRIPT_DIR%create_project.tcl"
if errorlevel 1 (
    echo ERREUR: Vivado a echoue
    exit /b 1
)

echo ============================================
echo  2. Build Vitis (plateforme + application)
echo ============================================
call "%XSCT%" "%SCRIPT_DIR%build_vitis.tcl"
if errorlevel 1 (
    echo ERREUR: Vitis a echoue
    exit /b 1
)

echo ============================================
echo  Build termine avec succes!
echo ============================================
endlocal
