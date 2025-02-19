#!/usr/bin/env bash

SESSION_NAME="nexus_node_setup"

# 1. screen 세션 존재 여부 확인
screen -list | grep -q "$SESSION_NAME"
if [ $? -eq 0 ]; then
  echo "[안내] 이미 '$SESSION_NAME' screen 세션이 존재합니다. 접속합니다..."
  exec screen -r "$SESSION_NAME"
fi

# 2. 새 screen 세션 생성
screen -S "$SESSION_NAME" -m zsh -c '
  # OS 확인
  OS=$(uname -s)
  if [ "$OS" = "Darwin" ]; then
    echo "Mac 환경: git 설치 (Homebrew 필요)"
    brew update
    brew install git
    brew install unzip
    brew install protobuf
    echo "Rust 설치 (rustup)"
    curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # *** 핵심: 여기서 .cargo/env 로드
    if [ -f "$HOME/.cargo/env" ]; then
      . "$HOME/.cargo/env"
    fi

    echo "cargo 버전 확인:"
    cargo --version  # 이제 정상적으로 동작
  else
    echo "이 스크립트는 Mac 전용 예시입니다."
    exit 1
  fi

  echo "[단계] Nexus CLI 설치 (curl https://cli.nexus.xyz/ | sh)"
  curl https://cli.nexus.xyz/ | sh

  echo
  echo "=== Nexus Node 설치가 완료되었습니다. ==="
  echo

  echo "[안내] screen 세션은 종료되지 않고 zsh 쉘이 유지됩니다."
  echo "      작업 완료 후 exit로 종료하거나 Ctrl + A, D로 detach 하세요."
  exec zsh
'

# 3. 세션에 자동 접속
echo "[안내] screen 세션이 생성되었습니다. 접속합니다..."
exec screen -r "$SESSION_NAME"
