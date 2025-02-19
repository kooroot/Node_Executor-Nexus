#!/usr/bin/env bash

SESSION_NAME="nexus_node_setup"

##################################
# 0. screen 세션 중복 확인
##################################
screen -list | grep -q "$SESSION_NAME"
if [ $? -eq 0 ]; then
  echo "[안내] 이미 '$SESSION_NAME' screen 세션이 존재합니다. 접속합니다..."
  exec screen -r "$SESSION_NAME"
fi

##################################
# 1. 새 screen 세션 생성
##################################
echo "[안내] '$SESSION_NAME' screen 세션을 새로 생성하고, Nexus Node 세팅을 진행합니다..."

screen -S "$SESSION_NAME" -m bash -c '
    ##################################
    # (A) 환경 확인 (Ubuntu 가정)
    ##################################
    OS=$(uname -s)
    if [ "$OS" != "Linux" ]; then
        echo "[오류] 이 스크립트는 Linux(Ubuntu) 전용 스크립트입니다."
        exit 1
    fi

    # 간단히 /etc/os-release 로 Ubuntu 여부 확인(선택 사항)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      if [[ "$ID" != "ubuntu" && "$ID_LIKE" != *"ubuntu"* ]]; then
        echo "[경고] 우분투 계열이 아닌 것으로 보입니다. apt 명령이 동작하지 않을 수 있음."
      fi
    fi

    ##################################
    # (B) 사전 준비 (패키지 설치)
    ##################################
    echo "[단계] apt 업데이트 & 업그레이드"
    sudo apt update && sudo apt upgrade -y

    echo "[단계] 필수 패키지 설치 (build-essential, pkg-config, etc.)"
    sudo apt install -y build-essential pkg-config libssl-dev git-all curl screen unzip protobuf-compiler

    ##################################
    # (C) Rust/Cargo 설치
    ##################################
    echo "[단계] Rust 설치 (rustup)"
    curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # *** Rust 설치 직후 즉시 .cargo/env 로드 (현재 쉘에 반영)
    if [ -f "$HOME/.cargo/env" ]; then
      . "$HOME/.cargo/env"
    fi

    echo "[확인] cargo 버전:"
    cargo --version || {
      echo "[오류] cargo 명령을 찾지 못했습니다. ~/.cargo/env 로드가 제대로 안 된 것 같습니다."
      exit 1
    }

    rustup target add riscv32i-unknown-none-elf

    echo "protobuf 수동 설치"
    wget https://github.com/protocolbuffers/protobuf/releases/download/v25.6/protoc-25.6-linux-x86_64.zip
    unzip protoc-25.6-linux-x86_64.zip
    mv bin/protoc /usr/local/bin

    ##################################
    # (D) Nexus CLI 설치
    ##################################
    echo "[단계] Nexus CLI 설치 (curl https://cli.nexus.xyz/ | sh)"
    curl https://cli.nexus.xyz/ | sh

    echo
    echo "=== Nexus Node 설치가 완료되었습니다. ==="
    echo

    ##################################
    # (E) Prover ID 설정 안내 (한국어)
    ##################################
    cat <<EOF
[안내] Nexus Node를 실행하거나 첫 설정 시, Prover ID 구성 옵션이 있습니다.

1) 웹 계정 연동 (권장):
   - beta.nexus.xyz 웹사이트(로그인 후)에서 “Prover ID”를 확인하여,
   - Node 실행 시 해당 ID를 입력합니다.
   - 이렇게 하면 CLI에서 기여한 내용이 웹 계정과 연동되어 일관되게 관리됩니다.

2) 랜덤 ID 생성:
   - Prover ID 입력을 건너뛰면, 자동으로 임의 ID가 생성됩니다.
   - 단, 추후에 다시 실행할 때 웹 계정과 연결하고 싶으면 새로 ID를 등록해야 합니다.

[주의사항] 웹 브라우저 사용 시:
 - “시크릿 모드” 또는 “프라이빗 창”을 사용 중이면, 쿠키/세션 유지가 제한될 수 있습니다.
 - 브라우저 설정에서 사이트 데이터 저장을 명시적으로 거부한 경우
 - 브라우저가 쿠키를 정기적으로 삭제하도록 설정된 경우
 - 위와 같은 작업을 수행하는 브라우저 확장 프로그램이 활성화된 경우

이러한 환경에서는 웹 계정에 저장된 Prover ID 정보를 원활하게 불러오지 못할 수 있으니,
해당 기능을 정상적으로 활용하려면 일반 창에서 로그인하거나 쿠키/스토리지 저장을 허용해 주세요.

EOF

    echo "모든 준비가 완료되었습니다."
    echo "이제 Prover ID를 입력하라는 메시지가 나올 때, 위 안내에 따라 설정하세요."

    ##################################
    # (F) 세션 종료 방지: 쉘 유지
    ##################################
    echo "[안내] 설치가 끝났습니다. screen 세션은 종료되지 않고 쉘이 유지됩니다."
    echo "스크립트를 종료하려면 exit 입력."
    exec bash
'

##################################
# 2. 생성된 세션에 자동 접속(attach)
##################################
echo "[안내] '$SESSION_NAME' screen 세션을 생성했습니다. 곧바로 접속(attach)합니다..."
exec screen -r "$SESSION_NAME"
