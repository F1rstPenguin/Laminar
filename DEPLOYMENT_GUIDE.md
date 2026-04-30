# Laminar + SampleManager 배포 가이드

---

## 아키텍처: GitHub 리포지토리 3개 체제

```
GitHub Repositories
├── [Private] Obsidian_Vault    ← 개인 vault 전체 백업 (노트, .obsidian 설정 등)
├── [Public]  Laminar            ← 배포용: Laminar(Kanban) 플러그인 빌드물 + Launcher 플러그인
└── [Public]  Sample_Manager    ← 배포용: SampleManager Python 앱 (기존 그대로)
```

### 왜 이 구조인가

| 요구사항                                 | 해결                                       |
| ------------------------------------ | ---------------------------------------- |
| 개인 vault를 통째로 백업하고 싶다                | → `Obsidian_Vault` (private, 민감정보 포함 OK) |
| 플러그인을 사용자에게 배포하고 싶다                  | → `Laminar` (public, 빌드물만)               |
| SampleManager를 사용자에게 배포하고 싶다         | → `Sample_Manager` (public, 기존 그대로)      |
| Obsidian에 연결된 채로 in-situ 개발/테스트하고 싶다 | → vault 안에서 개발 → 빌드 → 배포 리포에 복사          |
| 사용자가 업데이트를 쉽게 받고 싶다                  | → `git pull` 한 줄로 해결                     |

### 개발 → 배포 흐름

```
[개발자 PC]
  vault (Obsidian_Vault repo)
    ├── laminar-main/    ← 소스 코드 (여기서 수정)
    ├── .obsidian/plugins/
    │   ├── laminar/     ← npm run build → 여기에 빌드물 생성
    │   └── obsidian-samplelog-main/
    └── 노트들...
                │
                │ npm run build
                ▼
  .obsidian/plugins/laminar/main.js  (빌드 완료, Obsidian에서 즉시 테스트)
                │
                │ 테스트 완료 후 배포 스크립트 실행
                ▼
  Laminar repo/   ← 빌드물만 복사됨
    ├── laminar/
    │   ├── main.js
    │   ├── styles.css
    │   └── manifest.json
    └── obsidian-samplelog-main/
        ├── main.js
        └── manifest.json
                │
                │ git push
                ▼
  사용자: git pull → .obsidian/plugins/ 에 복사 → Obsidian 새로고침
```

---

## Part A. 개발자(배포자) — 초기 세팅

### 1. 리포지토리 생성

#### 1-1. 개인 vault 리포 (Obsidian_Vault) — 완료

| 항목 | 값 |
|------|-----|
| GitHub | `F1rstPenguin/Obsidian_Vault` (Private) |
| 로컬 | `~/Library/CloudStorage/Dropbox/obsidian` |
| 용도 | vault 전체 백업 (노트, 플러그인, 소스코드, 설정 등) |

> Private이므로 민감정보(API 키, 토큰) 포함해도 안전합니다.
> Obsidian Git 플러그인으로 평소처럼 vault 전체를 commit/push합니다.

#### 1-2. 플러그인 배포 리포 (Laminar) — 완료

| 항목 | 값 |
|------|-----|
| GitHub | `F1rstPenguin/Laminar` (Public) |
| 로컬 | `~/Library/CloudStorage/Dropbox/Laminar` |
| 용도 | Kanban + Launcher 플러그인 빌드물만 배포 |

#### 1-3. Sample_Manager — 기존 그대로

이미 `F1rstPenguin/Sample_Manager` (Public)로 운영 중. 변경 없음.

### 2. 배포 스크립트

vault에서 빌드 후 배포 리포로 복사하는 스크립트를 만듭니다:

**`~/deploy-plugins.sh`** (vault 밖에 저장):
```bash
#!/bin/bash
# Laminar Plugin Deploy Script
# Usage: ~/deploy-plugins.sh

VAULT="$HOME/Library/CloudStorage/Dropbox/obsidian"
DEPLOY="$HOME/Library/CloudStorage/Dropbox/Laminar"

echo "=== Copying Laminar plugin ==="
cp "$VAULT/.obsidian/plugins/laminar/main.js"      "$DEPLOY/laminar/"
cp "$VAULT/.obsidian/plugins/laminar/styles.css"    "$DEPLOY/laminar/"
cp "$VAULT/.obsidian/plugins/laminar/manifest.json" "$DEPLOY/laminar/"

echo "=== Copying Launcher plugin ==="
cp "$VAULT/.obsidian/plugins/obsidian-samplelog-main/main.js"      "$DEPLOY/obsidian-samplelog-main/"
cp "$VAULT/.obsidian/plugins/obsidian-samplelog-main/manifest.json" "$DEPLOY/obsidian-samplelog-main/"

echo "=== Done. Now cd $DEPLOY and commit/push ==="
cd "$DEPLOY"
git status
```

### 3. 일상 개발 워크플로우

```bash
# 1. vault에서 소스 수정 (Obsidian 열어둔 채로)
cd ~/Library/CloudStorage/Dropbox/obsidian/laminar-main
# ... 코드 수정 ...

# 2. 빌드 (Obsidian에 즉시 반영됨 — in-situ 테스트)
npm run build

# 3. Obsidian에서 Cmd+R → 테스트

# 4. 만족하면 개인 vault 커밋 (Obsidian Git 플러그인 또는 터미널)
cd ~/Library/CloudStorage/Dropbox/obsidian
git add -A && git commit -m "v2.0.52: 기능 추가" && git push

# 5. 배포 리포에 복사 & push
~/deploy-plugins.sh
cd ~/Library/CloudStorage/Dropbox/Laminar
git add -A && git commit -m "v2.0.52" && git push

# 6. SampleManager도 수정했다면
cd ~/Library/CloudStorage/Dropbox/Sample_Manager
git add -A && git commit -m "Update description" && git push
```

### 4. .gitignore 설정

**개인 vault (Obsidian_Vault)** — Private이므로 느슨하게:
```
.DS_Store
```
> Private 리포이므로 data.json, workspace.json 등 포함해도 무방.
> 원하면 민감파일 제외 가능하지만 필수는 아님.

**배포 리포 (Laminar)** — 빌드물만:
```
# 빌드물만 포함, 그 외 제외
.DS_Store
```
> 리포에는 `laminar/` + `obsidian-samplelog-main/` 폴더만 존재.

**Sample_Manager** — 이미 적용됨:
```
lab_settings.json       # 개인 경로 설정
Lab_Shared_Data/        # 실험 데이터
.venv/                  # 가상환경
__pycache__/
```

---

## Part B. 사용자 설치 매뉴얼

### 전제 조건

- **Obsidian** v1.0 이상 설치
- **Python** 3.9 이상 설치[^python]
- **Git** 설치[^git]
- macOS 또는 Windows

[^python]: 터미널(macOS: Terminal 앱, Windows: CMD 또는 PowerShell)을 열고 `python3 --version` (Windows: `python --version`)을 입력했을 때 `Python 3.9.x` 이상이 출력되면 됩니다. 설치가 안 되어 있다면 https://www.python.org/downloads/ 에서 다운로드합니다.

[^git]: 터미널에서 `git --version`을 입력했을 때 버전이 출력되면 됩니다. macOS는 Xcode Command Line Tools에 포함되어 있어 대부분 이미 설치되어 있습니다. Windows는 https://git-scm.com/download/win 에서 설치합니다.

---

### 자동 설치 (권장)

터미널을 열고 아래 명령을 순서대로 입력합니다.[^terminal]

```bash
# 1. Laminar 리포를 다운로드합니다
git clone https://github.com/F1rstPenguin/Laminar.git
```
> [^clone] `git clone`은 GitHub에 올라가 있는 파일들을 내 컴퓨터로 복사하는 명령입니다. 이 명령을 실행한 위치에 `Laminar` 폴더가 생깁니다. 예를 들어 `~/Documents`에서 실행했다면 `~/Documents/Laminar/`가 됩니다.

```bash
# 2. 다운로드한 폴더로 이동합니다
cd Laminar
```

```bash
# 3. 설치 스크립트를 실행합니다
# macOS / Linux
bash install.sh

# Windows
install.bat
```
> [^install] 스크립트를 실행하면 터미널에서 **Obsidian vault 경로**를 묻습니다. 자신의 Obsidian vault 폴더 경로를 입력하면 됩니다.[^vault-path] 이후 나머지는 자동으로 진행됩니다.

[^terminal]: **터미널 여는 법** — macOS: Spotlight(Cmd+Space)에서 "Terminal" 검색 후 실행. Windows: 시작 메뉴에서 "CMD" 또는 "PowerShell" 검색 후 실행. 열리면 검은/흰 배경에 커서가 깜빡이는 텍스트 입력 창이 나타납니다. 여기에 명령을 한 줄씩 붙여넣고 Enter를 누르면 됩니다.

[^vault-path]: **Obsidian vault 경로 찾는 법** — Obsidian 앱을 열면 좌하단에 vault 이름이 표시됩니다. 해당 vault의 폴더 위치를 모르겠다면: Obsidian → 설정(톱니바퀴) → "파일 및 링크" → 상단에 표시된 "Vault 위치"가 경로입니다. macOS 예시: `/Users/이름/Documents/MyVault`, Windows 예시: `C:\Users\이름\Documents\MyVault`

스크립트가 자동으로 수행하는 작업:
1. Obsidian vault에 Laminar + Launcher 플러그인 파일을 복사
2. SampleManager Python 앱을 다운로드 + 가상환경 생성 + 패키지 설치
3. Launcher 플러그인의 Python/Script 경로를 자동 설정
4. Obsidian 플러그인 목록에 자동 등록

#### 스크립트 완료 후 해야 할 것

1. **Obsidian을 실행**하고 vault를 엽니다
2. **설정**(좌하단 톱니바퀴) → **커뮤니티 플러그인**에서:[^community]
   - **Laminar** 우측 토글을 켜서 활성화
   - **Sample Manager Launcher** 우측 토글을 켜서 활성화
3. Obsidian을 **Cmd+R** (Windows: Ctrl+R)로 새로고침

[^community]: 만약 "제한 모드"가 켜져 있다면 먼저 "제한 모드 끄기"를 눌러야 플러그인 목록이 보입니다. 제한 모드는 커뮤니티 플러그인의 실행을 차단하는 안전 장치입니다.

---

### Launcher 플러그인 경로 설정

> [^auto-path] 자동 설치 스크립트를 사용했다면 이 경로가 **이미 자동 설정**되어 있을 수 있습니다. 아래 경로가 맞는지 확인만 하면 됩니다. 비어 있다면 직접 입력합니다.

Obsidian → **설정** → **커뮤니티 플러그인** → 좌측 목록에서 **Sample Manager Launcher** 클릭:

| 설정 항목 | macOS 예시 | Windows 예시 |
|----------|-----------|-------------|
| **Python Executable Path** | `/Users/<이름>/Documents/Laminar/../Sample_Manager/.venv/bin/python`[^python-path] | `C:\Users\<이름>\Documents\Sample_Manager\.venv\Scripts\python.exe` |
| **Script Path** | `/Users/<이름>/Documents/Sample_Manager/lab_main.py` | `C:\Users\<이름>\Documents\Sample_Manager\lab_main.py` |

[^python-path]: `<이름>` 부분은 자신의 OS 사용자 이름으로 바꿉니다. 정확한 경로를 모르겠다면, 터미널에서 `cd Sample_Manager && pwd`를 입력하면 절대경로가 출력됩니다. 거기에 `/.venv/bin/python`(macOS) 또는 `\.venv\Scripts\python.exe`(Windows)를 붙이면 됩니다.

---

### SampleManager 초기 경로 설정

SampleManager를 처음 실행하면 **초기 설정 대화상자**가 자동으로 나타납니다:[^first-run]

1. **Obsidian Vault 경로** (필수): Browse 버튼을 눌러 자신의 Obsidian vault 폴더를 선택
2. **실험 데이터 경로** (선택): XRD/SEM 등 대용량 파일이 저장될 공유 폴더 경로[^data-path]

[^first-run]: SampleManager는 Obsidian의 좌측 리본 바에 있는 flask(플라스크) 아이콘을 클릭하면 실행됩니다. 또는 터미널에서 `cd Sample_Manager && .venv/bin/python lab_main.py`로도 실행할 수 있습니다.

[^data-path]: 실험 데이터 경로는 선택 사항입니다. 비워두면 `Sample_Manager/Lab_Shared_Data/` 폴더가 기본으로 사용됩니다. 팀에서 공유 드라이브(Dropbox, NAS 등)를 사용한다면 해당 경로를 지정하면 됩니다.

> "Save & Continue"를 누르면 `lab_settings.json`이 자동 생성됩니다. 이 파일은 개인 설정 파일이므로 Git에 올라가지 않습니다.

<details>
<summary>수동 설정이 필요한 경우 (팝업에서 Skip을 눌렀을 때)</summary>

```bash
cd Sample_Manager
cp lab_settings.template.json lab_settings.json
```
텍스트 편집기로 `lab_settings.json`을 열어 자신의 경로로 수정:
```json
{
    "raw_data_root": "/path/to/Lab_Shared_Data",
    "obsidian_vault_dir": "/path/to/my-obsidian-vault",
    "obsidian_export_dir": "/path/to/my-obsidian-vault/Sample_Manager"
}
```
</details>

---

### 연동 테스트

1. Obsidian 좌측 리본에서 **flask 아이콘** 클릭 → SampleManager 창이 열리는지 확인
2. SampleManager에서 Sample 선택 → Step 선택
3. **"로 보내기"** 버튼 클릭 → Obsidian의 Calendar board에 카드가 생성되는지 확인
4. 생성된 카드의 **"Open in SampleManager"** 링크 클릭 → SampleManager가 해당 Sample/Step으로 이동하는지 확인

> [^test-fail] 3번에서 보드 목록이 비어있다면 SampleManager 초기 경로 설정에서 Obsidian vault 경로가 올바르게 지정되었는지 확인합니다. 4번에서 이동하지 않는다면, SampleManager를 닫고 다시 시도합니다 (이미 실행 중이면 새 인스턴스로 열립니다).

---

### 업데이트 방법

배포자가 새 버전을 공지한 후, 터미널에서:[^update]

```bash
cd Laminar
git pull
bash install.sh    # (Windows: install.bat)
```

[^update]: `cd Laminar`는 처음 설치할 때 `git clone`을 실행했던 위치의 `Laminar` 폴더로 이동하는 것입니다. 예를 들어 `~/Documents`에서 clone했다면 `cd ~/Documents/Laminar`입니다. `git pull`은 GitHub에서 최신 변경사항을 가져오고, `install.sh`를 다시 실행하면 플러그인과 SampleManager가 모두 최신 버전으로 업데이트됩니다. **개인 설정(`lab_settings.json`, 플러그인 `data.json`)은 덮어써지지 않으므로** 재설정할 필요가 없습니다.

---

### 수동 설치

<details>
<summary>자동 설치 스크립트가 동작하지 않을 경우 (펼쳐서 확인)</summary>

#### Step 1. SampleManager 설치

1. 터미널을 열고 원하는 위치로 이동한 뒤 GitHub에서 다운로드:
   ```bash
   # macOS / Linux
   cd ~/Documents
   git clone https://github.com/F1rstPenguin/Sample_Manager.git

   # Windows (CMD)
   cd %USERPROFILE%\Documents
   git clone https://github.com/F1rstPenguin/Sample_Manager.git
   ```

2. **Python 가상환경 생성 & 패키지 설치**:
   ```bash
   cd Sample_Manager

   # macOS / Linux
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt

   # Windows (CMD)
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   ```
   > 설치되는 패키지: `matplotlib`, `numpy`, `pillow`

3. **동작 확인**:
   ```bash
   python lab_main.py
   ```

#### Step 2. 플러그인 설치

1. 플러그인을 다운로드:
   ```bash
   git clone https://github.com/F1rstPenguin/Laminar.git
   ```

2. 자신의 Obsidian vault에 플러그인 폴더를 복사:
   ```bash
   # <MY_VAULT>를 자신의 Obsidian vault 경로로 바꾸세요
   # 예: ~/Documents/MyVault
   cp -r Laminar/laminar              <MY_VAULT>/.obsidian/plugins/
   cp -r Laminar/obsidian-samplelog-main <MY_VAULT>/.obsidian/plugins/
   ```
   > Windows의 경우 파일 탐색기에서 `Laminar` 폴더 안의 `laminar`, `obsidian-samplelog-main` 두 폴더를 vault의 `.obsidian\plugins\` 안에 복사해도 됩니다. `.obsidian`은 숨김 폴더이므로 탐색기에서 "숨김 항목 표시"를 켜야 보입니다.

3. Obsidian 실행 → **설정** → **커뮤니티 플러그인**:
   - "제한 모드" 비활성화
   - **Laminar** 활성화
   - **Sample Manager Launcher** 활성화

#### Step 3. 수동 업데이트

```bash
# SampleManager 업데이트
cd Sample_Manager
git pull

# 플러그인 업데이트
cd ../Laminar
git pull
cp -r laminar/*                 <MY_VAULT>/.obsidian/plugins/laminar/
cp -r obsidian-samplelog-main/* <MY_VAULT>/.obsidian/plugins/obsidian-samplelog-main/
```
이후 Obsidian에서 Cmd+R (Ctrl+R)로 새로고침합니다.

</details>

---

### 문제 해결

| 증상 | 확인 사항 |
|------|----------|
| SampleManager가 실행되지 않음 | Obsidian → 설정 → Sample Manager Launcher에서 Python/Script 경로 확인 |
| "로 보내기" 시 보드 목록이 비어있음 | `lab_settings.json`의 `obsidian_vault_dir` 경로 확인 |
| "Open in SampleManager" 클릭 시 이동하지 않음 | SampleManager를 닫고 다시 시도 |
| 카드가 보드에 보이지 않음 | Obsidian에서 보드 파일을 다시 열거나 Cmd+R로 새로고침 |
| `pip install` 실패 | 가상환경이 활성화되었는지 확인 (`which python` 경로가 `.venv` 안인지) |
| 플러그인 업데이트 후 반영 안 됨 | Obsidian 완전 종료 후 재시작 |
| `.obsidian` 폴더가 보이지 않음 | macOS: Finder에서 Cmd+Shift+. / Windows: 탐색기 → 보기 → 숨김 항목 |
