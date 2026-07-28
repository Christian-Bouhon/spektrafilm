#!/bin/bash
set -e

echo "=== 1. Nettoyage des anciens builds ==="
rm -rf AppDir Spektrafilm-x86_64.AppImage

echo "=== 2. Préparation du venv Python dans AppDir ==="
mkdir -p AppDir/usr
python3 -m venv --copies AppDir/usr

# Copie de la bibliothèque système (libpython)
LIBPYTHON_PATH=$(python3 -c "import sysconfig, os; print(os.path.join(sysconfig.get_config_var('LIBDIR'), sysconfig.get_config_var('LDLIBRARY')))")
if [ ! -f "$LIBPYTHON_PATH" ]; then
    LIBPYTHON_PATH=$(ldd "$(which python3)" | grep libpython | awk '{print $3}')
fi

mkdir -p AppDir/usr/lib
cp -L "$LIBPYTHON_PATH"* AppDir/usr/lib/ 2>/dev/null || true

# Copie intégrale de la bibliothèque standard système dans le venv
PY_SYS_VER=$(python3 -c "import sys; print(f'python{sys.version_info.major}.{sys.version_info.minor}')")
cp -rL "/usr/lib/${PY_SYS_VER}"/* AppDir/usr/lib/${PY_SYS_VER}/ 2>/dev/null || true

AppDir/usr/bin/pip install --upgrade pip
AppDir/usr/bin/pip install --no-cache-dir .

echo "=== 3. Création du script de lancement AppRun ==="
cat << 'EOF' > AppDir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"

# Nettoyage de l'environnement Python système
unset PYTHONHOME
unset PYTHONPATH

# Chemins système de l'AppImage
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM=xcb

# CORRECTION : On lance le binaire python3 embarqué et on lui passe le script de lancement en argument
exec "${HERE}/usr/bin/python3" "${HERE}/usr/bin/spektrafilm" "$@"
EOF

chmod +x AppDir/AppRun

echo "=== 4. Métadonnées (.desktop & icône) ==="
cat << 'EOF' > AppDir/spektrafilm.desktop
[Desktop Entry]
Name=Spektrafilm
Comment=Film simulation and LUT generator
Exec=spektrafilm
Icon=spektrafilm
Type=Application
Categories=Graphics;Photography;
EOF

touch AppDir/spektrafilm.png

echo "=== 5. Génération AppImage ==="
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

ARCH=x86_64 ./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir Spektrafilm-x86_64.AppImage