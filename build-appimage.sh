#!/bin/bash
set -e

echo "=== 1. Nettoyage des anciens builds ==="
rm -rf AppDir Spektrafilm-x86_64.AppImage

echo "=== 2. Préparation du venv Python dans AppDir ==="
mkdir -p AppDir/usr
python3 -m venv --copies AppDir/usr

# COPIE CRUCIALE : On embarque la libpython partagée du système de build dans l'AppImage
mkdir -p AppDir/usr/lib
cp /usr/lib/x86_64-linux-gnu/libpython3*.so* AppDir/usr/lib/ 2>/dev/null || true
cp /usr/lib/libpython3*.so* AppDir/usr/lib/ 2>/dev/null || true

AppDir/usr/bin/pip install --upgrade pip

# Installation du dépôt courant
AppDir/usr/bin/pip install --no-cache-dir .

echo "=== 3. Création du script de lancement AppRun ==="
cat << 'EOF' > AppDir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"

# On force Linux à chercher les bibliothèques embarquées (libpython...) en PREMIER
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