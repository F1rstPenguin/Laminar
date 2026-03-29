#!/bin/bash
# Laminar + SampleManager Installer / Updater
# Usage: bash install.sh
#
# 첫 실행 시: 플러그인 설치 + SampleManager clone + 가상환경 설정
# 재실행 시: 플러그인 업데이트 + SampleManager 업데이트

set -e

echo "============================================"
echo "  Laminar + SampleManager Installer"
echo "============================================"
echo ""

# --- 1. Obsidian vault 경로 확인 ---
VAULT_PATH=""

# Try to auto-detect vault path
if [ -d "$HOME/Library/CloudStorage/Dropbox/obsidian/.obsidian" ]; then
    VAULT_PATH="$HOME/Library/CloudStorage/Dropbox/obsidian"
elif [ -d "$HOME/Documents/obsidian/.obsidian" ]; then
    VAULT_PATH="$HOME/Documents/obsidian"
fi

if [ -n "$VAULT_PATH" ]; then
    echo "Obsidian vault 자동 감지: $VAULT_PATH"
    read -p "이 경로가 맞습니까? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        VAULT_PATH=""
    fi
fi

if [ -z "$VAULT_PATH" ]; then
    read -p "Obsidian vault 경로를 입력하세요: " VAULT_PATH
fi

if [ ! -d "$VAULT_PATH/.obsidian" ]; then
    echo "ERROR: $VAULT_PATH/.obsidian 폴더를 찾을 수 없습니다."
    echo "올바른 Obsidian vault 경로를 입력해주세요."
    exit 1
fi

PLUGINS_DIR="$VAULT_PATH/.obsidian/plugins"
mkdir -p "$PLUGINS_DIR"

echo ""

# --- 2. Laminar 플러그인 설치/업데이트 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/4] Laminar 플러그인 설치 중..."
mkdir -p "$PLUGINS_DIR/laminar"
cp "$SCRIPT_DIR/laminar/main.js"      "$PLUGINS_DIR/laminar/"
cp "$SCRIPT_DIR/laminar/styles.css"    "$PLUGINS_DIR/laminar/"
cp "$SCRIPT_DIR/laminar/manifest.json" "$PLUGINS_DIR/laminar/"
echo "  ✓ Laminar 플러그인 설치 완료"

echo "[2/4] Sample Manager Launcher 플러그인 설치 중..."
mkdir -p "$PLUGINS_DIR/obsidian-samplelog-main"
cp "$SCRIPT_DIR/obsidian-samplelog-main/main.js"      "$PLUGINS_DIR/obsidian-samplelog-main/"
cp "$SCRIPT_DIR/obsidian-samplelog-main/manifest.json" "$PLUGINS_DIR/obsidian-samplelog-main/"
echo "  ✓ Launcher 플러그인 설치 완료"

# Enable plugins in community-plugins.json
CP_FILE="$VAULT_PATH/.obsidian/community-plugins.json"
if [ -f "$CP_FILE" ]; then
    # Check if laminar is already registered
    if ! grep -q '"laminar"' "$CP_FILE"; then
        # Add laminar to the array
        python3 -c "
import json
with open('$CP_FILE', 'r') as f:
    plugins = json.load(f)
for p in ['laminar', 'obsidian-sample-manager-launcher']:
    if p not in plugins:
        plugins.append(p)
with open('$CP_FILE', 'w') as f:
    json.dump(plugins, f, indent=2)
print('  ✓ 플러그인 자동 등록 완료')
"
    fi
else
    echo '["laminar", "obsidian-sample-manager-launcher"]' > "$CP_FILE"
    echo "  ✓ 플러그인 목록 생성 완료"
fi

echo ""

# --- 3. SampleManager 설치/업데이트 ---
SM_DIR="$(dirname "$SCRIPT_DIR")/Sample_Manager"

echo "[3/4] SampleManager 확인 중..."
if [ -d "$SM_DIR/.git" ]; then
    echo "  SampleManager 발견: $SM_DIR"
    echo "  업데이트 중..."
    cd "$SM_DIR" && git pull 2>&1 | head -5
    echo "  ✓ SampleManager 업데이트 완료"
else
    echo "  SampleManager가 없습니다. clone 중..."
    git clone https://github.com/F1rstPenguin/Sample_Manager.git "$SM_DIR" 2>&1 | tail -2
    echo "  ✓ SampleManager clone 완료"
fi

# --- 4. Python 가상환경 ---
echo ""
echo "[4/4] Python 가상환경 확인 중..."
if [ -d "$SM_DIR/.venv" ]; then
    echo "  ✓ 가상환경 이미 존재"
else
    echo "  가상환경 생성 중..."
    python3 -m venv "$SM_DIR/.venv"
    echo "  패키지 설치 중..."
    "$SM_DIR/.venv/bin/pip" install -r "$SM_DIR/requirements.txt" -q
    echo "  ✓ 가상환경 설정 완료"
fi

# --- 5. Launcher 플러그인 경로 자동 설정 ---
LAUNCHER_DATA="$PLUGINS_DIR/obsidian-samplelog-main/data.json"
if [ ! -f "$LAUNCHER_DATA" ]; then
    PYTHON_PATH="$SM_DIR/.venv/bin/python"
    SCRIPT_PATH="$SM_DIR/lab_main.py"
    if [ -f "$PYTHON_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
        cat > "$LAUNCHER_DATA" << DATEOF
{
  "pythonPath": "$PYTHON_PATH",
  "scriptPath": "$SCRIPT_PATH"
}
DATEOF
        echo ""
        echo "  ✓ Launcher 경로 자동 설정 완료"
    fi
fi

echo ""
echo "============================================"
echo "  설치 완료!"
echo "============================================"
echo ""
echo "다음 단계:"
echo "  1. Obsidian을 실행하고 vault를 엽니다"
echo "  2. 설정 → 커뮤니티 플러그인에서 Laminar, Sample Manager Launcher 활성화"
echo "  3. SampleManager 첫 실행 시 Obsidian vault 경로를 설정합니다"
echo ""
echo "업데이트할 때:"
echo "  cd $(dirname "$SCRIPT_DIR")/Laminar && git pull && bash install.sh"
echo ""
