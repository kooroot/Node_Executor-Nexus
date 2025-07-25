# Nexus Node Setup

이 저장소는 **Nexus Node**를 간단히 설치하고 실행하는 스크립트를 제공합니다.  
Mac 또는 Linux 환경에서 동작하도록 작성되었으며, `screen` 세션을 통해 설치 과정을 실시간으로 확인하고 종료 후에도 셸을 유지할 수 있습니다.

---

## 1. 개요

- **OS 자동 식별**  
  스크립트는 Mac, Linux(Ubuntu 계열) 전용 버전으로 각각 준비되어 있습니다.  
- **Rust/Cargo 설치**  
  - Rust가 설치되어 있지 않은 경우, `rustup`을 통해 자동으로 설치하고 `$HOME/.cargo/env`를 로드해 `cargo` 명령어를 사용할 수 있도록 설정합니다.
- **Nexus CLI 설치**  
  - `curl https://cli.nexus.xyz/ | sh` 명령어로 간단히 설치합니다.
- **Node ID 설정 안내**  
  - NEX 포인트를 얻기 위해서는 웹 계정 연동(필수)을 해야합니다..
  - 시크릿 모드(프라이빗 창), 쿠키 차단 환경에서 발생할 수 있는 주의사항을 안내합니다.
- **screen 세션 유지**  
  설치가 완료된 뒤에도 `screen` 세션이 종료되지 않으며, 해당 세션에서 셸이 계속 활성화되어 추가 명령 실행이나 로그 확인이 가능합니다.

---

## 2. 요구 사항

- **인터넷 연결**: `curl`로 Rustup 및 Nexus CLI 설치 스크립트를 다운로드해야 합니다.
- **권한**: 
  - Linux 환경에서 `sudo apt update && sudo apt upgrade -y` 명령 등을 수행하므로 `sudo` 권한이 필요할 수 있습니다.  
  - Mac 환경에서 `brew install ...` 명령을 사용하므로 Homebrew가 필요합니다.
- **screen**:  
  - 대부분의 Linux 배포판에 기본 포함되어 있으나, 없는 경우 `sudo apt install screen`으로 설치할 수 있습니다.  
  - Mac에서는 Homebrew를 통해 `brew install screen` 등으로 설치할 수 있습니다.

---

## 3. 사용 방법

### [Testnet 3]

1. **스크립트 다운로드**  
   ```bash
   wget https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_s3.sh
   ```
2. **실행 권한 부여**  
   ```bash
   chmod +x nexus_s3.sh
   ```
3. **스크립트 실행**  
   ```bash
   ./nexus_s3.sh
   ```
새로운 screen 세션(nexus_node)이 생성되어 Nexus Terms 동의(Y 입력) -> 설치 옵션 선택 및 정보 입력(1(NodeID 기반) or 2(Wallet Address 기반)) -> 노드 구동 확인 순서로 진행됩니다.
설치 완료 후에 `screen -r nexus_node`로 로그를 확인할 수 있으며, 구동을 유지하면서 세션을 빠져나오기 위해서는 Ctrl + A + D를 입력해 세션을 빠져나오면 됩니다.

### [Linux_upgrade]

1. **스크립트 다운로드**  
   ```bash
   wget https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_upgrade.sh
   ```
2. **실행 권한 부여**  
   ```bash
   chmod +x nexus_upgrade.sh
   ```
3. **스크립트 실행**  
   ```bash
   ./nexus_upgrade.sh
   ```
새로운 screen 세션(nexus_node_setup)이 생성되어 Rust 설치 → Nexus CLI 설치 → Prover ID 안내가 진행됩니다.
설치 완료 후에도 동일 세션 내에서 셸이 유지되므로, 추가 명령을 입력할 수 있습니다.

### [MacOS_upgrade]
1. **스크립트 다운로드**  
   ```bash
   wget https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_upgrade_mac.sh
   ```
2. **실행 권한 부여**  
   ```bash
   chmod +x nexus_upgrade_mac.sh
   ```
3. **스크립트 실행**  
   ```bash
   ./nexus_upgrade_mac.sh
   ```

### [Linux]

1. **스크립트 다운로드**  
   ```bash
   wget https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_node.sh
   ```
2. **실행 권한 부여**  
   ```bash
   chmod +x nexus_node.sh
   ```
3. **스크립트 실행**  
   ```bash
   ./nexus_node.sh
   ```
새로운 screen 세션(nexus_node_setup)이 생성되어 Rust 설치 → Nexus CLI 설치 → Prover ID 안내가 진행됩니다.
설치 완료 후에도 동일 세션 내에서 셸이 유지되므로, 추가 명령을 입력할 수 있습니다.

### [MacOS]
1. **스크립트 다운로드**  
   ```bash
   wget https://raw.githubusercontent.com/kooroot/Node_Executor-Nexus/refs/heads/main/nexus_node_mac.sh
   ```
2. **실행 권한 부여**  
   ```bash
   chmod +x nexus_node_mac.sh
   ```
3. **스크립트 실행**  
   ```bash
   ./nexus_node_mac.sh
   ```

## 4. Prover ID 설정
Nexus Node를 실행할 때, Node ID를 입력하라는 메시지가 표시될 수 있습니다:

1. 웹 계정 연동 (필수)
   - beta.nexus.xyz 웹사이트에서 로그인 후 Add node의 node id값을 복사해둡니다.
   - 스크립트(또는 첫 실행 시) node id를 입력하면, CLI 기여 내용이 웹 계정과 연동됩니다.
   - <img width="635" alt="image" src="https://github.com/user-attachments/assets/4fd92a3f-7d02-4a39-b353-9acf0a155526" />

주의:
- 시크릿 모드(프라이빗 창), 쿠키/스토리지 차단, 자동 쿠키 삭제, 특정 확장프로그램을 사용하는 경우
- 웹 계정에 저장된 Prover ID 정보를 불러오지 못할 수 있습니다.
- 문제를 피하려면 일반 창에서 로그인하거나 쿠키/스토리지 저장을 허용하세요.

## 5. 참고사항
- **Rust/Cargo 환경**
  - 스크립트가 Rust 설치를 마친 후 ~/.cargo/env를 로드하므로, screen 세션 내에서 즉시 cargo를 사용할 수 있습니다.
  - 새로운 터미널(또는 세션)에서는 source ~/.cargo/env 명령을 다시 실행하거나, ~/.bashrc, ~/.zshrc 등에 추가해주어야 Cargo를 인식할 수 있습니다.
- **screen 세션 조작**
  - 스크립트 실행이 끝나면 자동으로 screen 세션이 활성화됩니다.
  - 세션 내에서 exit 입력으로 종료하거나, Ctrl + A, D(detach)로 백그라운드로 보낼 수 있습니다.
  - 다시 접속하려면 screen -r nexus_node_setup 명령을 사용하세요.
