#!/bin/bash
# =============================================================================
# setup-intel.sh — Configuración para Mac Intel (x86_64)
# Instala dependencias, compila el juego y lo deja listo para jugar.
# =============================================================================
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[setup]${NC} $*"; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# Moverse al directorio del script (la raíz del repo)
cd "$(dirname "$0")"
REPO_ROOT="$PWD"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   IKEMEN-GO — Setup para Mac Intel (x86_64) ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Verificar arquitectura ───────────────────────────────────────────────
ARCH="$(uname -m)"
info "Arquitectura detectada: $ARCH"
if [[ "$ARCH" == "arm64" ]]; then
    error "Este script es para Mac Intel (x86_64). Tu Mac tiene chip Apple Silicon (ARM).
Usá './build/build.sh MacOSARM' en cambio."
fi

# ── 2. Xcode Command Line Tools ─────────────────────────────────────────────
info "Verificando Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Instalando Xcode Command Line Tools (puede tomar unos minutos)..."
    xcode-select --install 2>/dev/null || true
    echo "  → Aceptá el diálogo que apareció en pantalla y esperá que termine."
    echo "    Cuando termine, volvé a ejecutar este script."
    exit 0
fi
success "Xcode CLI tools: OK"

# ── 3. Homebrew ─────────────────────────────────────────────────────────────
info "Verificando Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Agregar brew al PATH de esta sesión
    eval "$(/usr/local/bin/brew shellenv 2>/dev/null || true)"
fi

# Asegurar que brew esté en el PATH (Intel lo instala en /usr/local)
eval "$(/usr/local/bin/brew shellenv 2>/dev/null || true)"
success "Homebrew: $(brew --version | head -1)"

# ── 4. Dependencias con Homebrew ─────────────────────────────────────────────
BREW_DEPS=(go sdl2 libxmp pkg-config)
info "Instalando dependencias: ${BREW_DEPS[*]}..."
brew install "${BREW_DEPS[@]}"
success "Dependencias instaladas"

# ── 5. Configurar entorno de compilación ────────────────────────────────────
info "Configurando entorno..."
export PATH="/usr/local/go/bin:/usr/local/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/opt/sdl2/lib/pkgconfig:/usr/local/opt/libxmp/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CGO_CFLAGS="-I/usr/local/include"
export CGO_LDFLAGS="-L/usr/local/lib"

go version || error "Go no encontrado luego de la instalación."
success "Go: $(go version)"

# ── 6. Compilar ─────────────────────────────────────────────────────────────
info "Compilando IKEMEN-GO para Mac Intel... (puede tomar 3-8 minutos la primera vez)"
./build/build.sh MacOS
success "Compilación exitosa → bin/Ikemen_GO_MacOS"

# ── 7. Copiar dylibs necesarias ─────────────────────────────────────────────
info "Copiando librerías dinámicas al directorio lib/..."
mkdir -p lib

# SDL2
SDL2_LIB="$(brew --prefix sdl2)/lib/libSDL2-2.0.0.dylib"
if [[ -f "$SDL2_LIB" ]]; then
    cp -f "$SDL2_LIB" lib/
    ln -sf libSDL2-2.0.0.dylib lib/libSDL2.dylib 2>/dev/null || true
    success "SDL2 copiado"
else
    error "No se encontró libSDL2 en $SDL2_LIB"
fi

# libxmp (si el binario la usa)
XMP_LIB="$(brew --prefix libxmp)/lib/libxmp.dylib"
if [[ -f "$XMP_LIB" ]]; then
    cp -f "$XMP_LIB" lib/
    success "libxmp copiado"
fi

# ── 8. Corregir rpath del binario ────────────────────────────────────────────
info "Ajustando rpath del binario para buscar libs locales..."
install_name_tool -add_rpath "@executable_path/lib" bin/Ikemen_GO_MacOS 2>/dev/null || true
install_name_tool -add_rpath "@executable_path/../lib" bin/Ikemen_GO_MacOS 2>/dev/null || true

# Quitar restricción de cuarentena de macOS
xattr -rd com.apple.quarantine . 2>/dev/null || true
chmod +x bin/Ikemen_GO_MacOS
chmod +x build/Ikemen_GO.command

# ── 9. Crear acceso directo en la raíz ──────────────────────────────────────
if [[ ! -f "Iniciar Juego.command" ]]; then
    cat > "Iniciar Juego.command" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
xattr -rd com.apple.quarantine . 2>/dev/null || true
DYLD_LIBRARY_PATH="$PWD/lib:${DYLD_LIBRARY_PATH:-}"
export DYLD_LIBRARY_PATH
exec ./bin/Ikemen_GO_MacOS
EOF
    chmod +x "Iniciar Juego.command"
fi

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   ✅ ¡Todo listo!                            ║"
echo "  ║                                              ║"
echo "  ║   Para jugar: doble-click en              ║"
echo "  ║   'Iniciar Juego.command'                    ║"
echo "  ║                                              ║"
echo "  ║   Para agregar personajes:                   ║"
echo "  ║   Poné archivos .zip o .rar en               ║"
echo "  ║   autoload/chars/                            ║"
echo "  ║                                              ║"
echo "  ║   Para agregar stages:                       ║"
echo "  ║   Poné archivos .zip o .rar en               ║"
echo "  ║   autoload/stages/                           ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
