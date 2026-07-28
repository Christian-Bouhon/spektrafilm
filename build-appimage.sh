#!/bin/bash
set -e

echo "=== 1. Nettoyage des anciens builds ==="
rm -rf AppDir Spektrafilm-x86_64.AppImage python_standalone

echo "=== 2. Téléchargement d'un Python autonome 3.13 (Standalone Runtime) ==="
mkdir -p AppDir/usr
PY_BUILD="20250115"
PY_VER="3.13.1"
wget -q "https://github.com/indygreg/python-build-standalone/releases/download/${PY_BUILD}/cpython-${PY_VER}+${PY_BUILD}-x86_64-unknown-linux-gnu-install_only.tar.gz" -O python_standalone.tar.gz

mkdir -p python_standalone
tar -xzf python_standalone.tar.gz -C python_standalone

# Copie de l'environnement Python propre dans AppDir
cp -r python_standalone/python/* AppDir/usr/

echo "=== 3. Installation des dépendances du projet ==="
AppDir/usr/bin/python3 -m pip install --upgrade pip
AppDir/usr/bin/python3 -m pip install --no-cache-dir .

echo "=== 4. Création du script de lancement AppRun ==="
cat << 'EOF' > AppDir/AppRun
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"

export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM=xcb

# Exécution de l'application via le Python autonome embarqué
exec "${HERE}/usr/bin/python3" "${HERE}/usr/bin/spektrafilm" "$@"
EOF

chmod +x AppDir/AppRun

echo "=== 5. Métadonnées (.desktop & icône) ==="
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

echo "=== 6. Génération AppImage ==="
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

ARCH=x86_64 ./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir Spektrafilm-x86_64.AppImage