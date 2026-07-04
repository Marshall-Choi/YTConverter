#!/bin/bash
# YouTube → Apple Music 변환기 실행 스크립트
# pyenv Python에 tkinter가 없을 경우 시스템 Python 또는 Homebrew Python을 사용합니다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# tkinter가 있는 Python 찾기
find_python() {
    for py in \
        "/opt/homebrew/opt/python@3.13/bin/python3.13" \
        "/opt/homebrew/opt/python@3.12/bin/python3.12" \
        "/opt/homebrew/opt/python@3.11/bin/python3.11" \
        "/usr/bin/python3" \
        "python3"; do
        if command -v "$py" &>/dev/null 2>&1 || [ -f "$py" ]; then
            if "$py" -c "import tkinter" &>/dev/null 2>&1; then
                echo "$py"
                return
            fi
        fi
    done
    echo ""
}

PYTHON=$(find_python)

if [ -z "$PYTHON" ]; then
    echo "❌ tkinter가 포함된 Python을 찾을 수 없습니다."
    echo "   다음 명령어로 설치하세요:"
    echo "   brew install python-tk@3.11"
    exit 1
fi

# yt-dlp 설치 확인
if ! command -v yt-dlp &>/dev/null; then
    echo "❌ yt-dlp가 설치되어 있지 않습니다."
    echo "   brew install yt-dlp  또는  pip install yt-dlp"
    exit 1
fi

echo "✅ Python: $PYTHON"
echo "✅ yt-dlp: $(which yt-dlp)"
echo ""

cd "$SCRIPT_DIR"
"$PYTHON" app.py
