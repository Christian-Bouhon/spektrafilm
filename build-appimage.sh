#!/bin/bash
set -e

echo "=== 1. Nettoyage des anciens builds ==="
rm -rf AppDir Spektrafilm-x86_64.AppImage python_standalone

echo "=== 2. Téléchargement d'un Python autonome 3.13 ==="
mkdir -p AppDir/usr
PY_BUILD="20250115"
PY_VER="3.13.1"
wget -q "https://github.com/indygreg/python-build-standalone/releases/download/${PY_BUILD}/cpython-${PY_VER}+${PY_BUILD}-x86_64-unknown-linux-gnu-install_only.tar.gz" -O python_standalone.tar.gz

mkdir -p python_standalone
tar -xzf python_standalone.tar.gz -C python_standalone

# Copie du runtime Python dans AppDir
cp -r python_standalone/python/* AppDir/usr/

echo "=== 3. Embarquement des bibliothèques système requises (Qt/XCB) ==="
# Copie de libxcb-cursor nécessaire pour Qt 6.5+
mkdir -p AppDir/usr/lib
XCB_CURSOR_LIB=$(ldconfig -p | grep libxcb-cursor.so.0 | awk '{print $NF}' | head -n 1)

if [ -n "$XCB_CURSOR_LIB" ] && [ -f "$XCB_CURSOR_LIB" ]; then
    echo "Copie de $XCB_CURSOR_LIB dans l'AppImage..."
    cp -L "$XCB_CURSOR_LIB"* AppDir/usr/lib/
else
    echo "Recherche alternative pour libxcb-cursor..."
    cp -L /usr/lib/x86_64-linux-gnu/libxcb-cursor.so* AppDir/usr/lib/ 2>/dev/null || true
fi

echo "=== 4. Installation du projet ==="
AppDir/usr/bin/python3 -m pip install --upgrade pip
AppDir/usr/bin/python3 -m pip install --no-cache-dir .

echo "=== 5. Création du script de lancement AppRun ==="
cat << 'EOF' > AppDir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"

export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM=xcb

exec "${HERE}/usr/bin/python3" "${HERE}/usr/bin/spektrafilm" "$@"
EOF

chmod +x AppDir/AppRun

echo "=== 6. Métadonnées (.desktop & icône) ==="
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

echo "=== 7. Génération AppImage ==="
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

ARCH=x86_64 ./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir Spektrafilm-x86_64.AppImage