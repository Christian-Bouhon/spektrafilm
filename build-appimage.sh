#!/bin/bash
set -e

echo "=== 1. Nettoyage des anciens builds ==="
rm -rf AppDir Spektrafilm-x86_64.AppImage

echo "=== 2. Préparation du venv Python dans AppDir ==="
mkdir -p AppDir/usr
python3 -m venv --copies AppDir/usr

# COPIE AUTOMATIQUE ET INFAILLIBLE DE LIBPYTHON
# 1. On demande à Python où se trouve son binaire libpython
LIBPYTHON_PATH=$(python3 -c "import sysconfig, os; print(os.path.join(sysconfig.get_config_var('LIBDIR'), sysconfig.get_config_var('LDLIBRARY')))")

# 2. Si non trouvé via sysconfig, on recherche la lib liée dynamiquement
if [ ! -f "$LIBPYTHON_PATH" ]; then
    LIBPYTHON_PATH=$(ldd $(which python3) | grep libpython | awk '{print $3}')
fi

echo "Copie de la bibliothèque système : $LIBPYTHON_PATH"
mkdir -p AppDir/usr/lib
cp -L "$LIBPYTHON_PATH"* AppDir/usr/lib/

AppDir/usr/bin/pip install --upgrade pip

# Installation du dépôt courant
AppDir/usr/bin/pip install --no-cache-dir .

echo "=== 3. Création du script de lancement AppRun ==="
cat << 'EOF' > AppDir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"

# On force la recherche des bibliothèques embarquées en PREMIER
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export PATH="${HERE}/usr/bin:${PATH}"
export QT_QPA_PLATFORM=xcb

PY_VER=$(ls "${HERE}/usr/lib" | grep -E '^python3\.' | head -n 1)
export PYTHONPATH="${HERE}/usr/lib/${PY_VER}/site-packages:${PYTHONPATH}"

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