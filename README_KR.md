[English](README.md) | [简体中文](README.zh_CN.md) | [日本語](README.ja.md) | 한국어

# Hail 雹 (Android 앱 동결 관리 도구)

[![Android CI status](https://github.com/aistra0528/Hail/workflows/Android%20CI/badge.svg)](https://github.com/aistra0528/Hail/actions)
[![Downloads](https://img.shields.io/github/downloads/aistra0528/Hail/total.svg)](https://github.com/aistra0528/Hail/releases)
[![License](https://img.shields.io/github/license/aistra0528/Hail)](LICENSE)

Hail은 불필요한 안드로이드 앱을 즉시 동결(Freeze)하여 배터리와 시스템 RAM 리소스를 절약하고 기기 성능을 최적화할 수 있는 오픈소스 소프트웨어입니다.

---

## 🧊 동결(Freeze) 방식 안내

**동결(Freeze)**이란 사용하지 않는 앱을 완전히 멈추거나 차단하여 백그라운드 리소스 소모를 방지하고, 필요할 때만 즉시 해제하여 사용하는 기능입니다.

Hail은 3가지 방식의 동결을 지원합니다:

### 1. 비활성화 (Disable)
- 홈 런처 및 설치된 앱 목록에서 비활성화 상태로 전환됩니다.
- 해제(Enable)하면 원래대로 복원됩니다.

### 2. 숨김 (Hide)
- 앱이 런처와 일반 앱 목록에서 완전히 숨겨집니다.
- 데이터와 APK는 유지된 상태로 시스템에서 보이지 않게 처리됩니다.

### 3. 일시중지 (Suspend, Android 7.0+)
- 런처의 앱 아이콘이 **회색(Grayscale)**으로 표시됩니다.
- 알림 표시 및 백그라운드 액티비티가 제한되며, 앱 클릭 시 시스템에서 일시중지 해제 여부를 묻는 팝업이 나타납니다.
- 앱을 빠르게 실행하고 관리하기에 가장 권장되는 방식입니다.

---

## ⚙️ 작동 모드 (Working Mode)

> **주의**: 특정 모드로 동결된 앱은 반드시 동일한 모드로 해제되어야 합니다.

| 권한 모드 | 강제 종료 | 비활성화(Disable) | 숨김(Hide) | 일시중지(Suspend) | 시스템 앱 삭제/재설치 |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Shizuku (adb)** *(권장)* | ✓ | ✓ | ✗ | ✓ | ✓ |
| **Shizuku (root) / Sui** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Root** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Device Owner** | ✗ | ✗ | ✓ | ✓ | ✗ |
| **Privileged System App** | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Dhizuku** | ✗ | ✗ | ✓ | ✓ | ✗ |

---

## ✨ 커스텀 포크 확장 기능 (Custom Enhancements)

본 포크 버전에는 편리한 대량 앱 관리와 자동화를 위한 강력한 기능들이 추가되었습니다:

### 1. 💾 JSON 기반 백업 및 복원 (Backup & Restore)
- **설정 메뉴 파일 입출력**:
  - `설정(Settings)` ➔ `[백업 및 복원]` 메뉴를 통해 관리 중인 앱 목록과 태그, 고정(Pinned), 화이트리스트 상태를 JSON 파일로 내보내기/복원할 수 있습니다.
- **클립보드 연동**:
  - 홈 화면 상단 메뉴를 통해 JSON 텍스트를 클립보드로 복사하거나 붙여넣어 즉시 가져올 수 있습니다.
- **유연한 데이터 파싱**:
  - 전체 백업 JSON, 앱 오브젝트 리스트, 단순 패키지명 배열(`["com.foo", "com.bar"]`) 등 다양한 형태를 자동으로 인식하여 병합합니다.

### 2. ⚡ 동적 앱 관리 API (Dynamic App Management API)
- 앱을 UI에서 일일이 찾지 않아도, 쉘 스크립트나 외부 자동화 앱(Tasker, Macrodroid 등)에서 Intent 및 URI 스키마를 통해 Hail 관리 DB에 즉시 등록/삭제할 수 있습니다.
- `hail://freeze` 또는 `ACTION_FREEZE` 호출 시 대상 앱이 관리 목록에 없으면 자동으로 등록한 후 동결을 수행합니다.

---

## 📡 API 및 URI 스키마 레퍼런스

### 1. Android Intent Action (`am start`)

```shell
adb shell am start -a <ACTION> -e <KEY> <VALUE>
```

| Intent Action | 파라미터 Extra | 설명 |
| :--- | :--- | :--- |
| `com.aistra.hail.action.LAUNCH` | `-e package <pkg>` | 대상 앱을 해제하고 즉시 실행 |
| `com.aistra.hail.action.FREEZE` | `-e package <pkg>` | 대상 앱 동결 (미등록 앱인 경우 자동 등록 후 동결) |
| `com.aistra.hail.action.UNFREEZE` | `-e package <pkg>` | 대상 앱 동결 해제 |
| `com.aistra.hail.action.ADD_APP` | `-e package <pkg>`<br>`-e tag <태그명>` (선택)<br>`-ez freeze true` (선택) | 관리 목록에 앱 추가 (태그 지정 및 즉시 동결 가능) |
| `com.aistra.hail.action.REMOVE_APP` | `-e package <pkg>` | 관리 목록에서 앱 제거 |
| `com.aistra.hail.action.ADD_APPS` | `-e packages <pkg1,pkg2,...>`<br>`-e tag <태그명>` (선택)<br>`-ez freeze true` (선택) | 여러 앱을 관리 목록에 일괄 추가 |
| `com.aistra.hail.action.FREEZE_TAG` | `-e tag <태그명>` | 해당 태그의 비-화이트리스트 앱 일괄 동결 |
| `com.aistra.hail.action.UNFREEZE_TAG` | `-e tag <태그명>` | 해당 태그의 모든 앱 동결 해제 |
| `com.aistra.hail.action.FREEZE_ALL` | *(없음)* | 관리 목록의 모든 앱 일괄 동결 |
| `com.aistra.hail.action.UNFREEZE_ALL` | *(없음)* | 관리 목록의 모든 앱 동결 해제 |
| `com.aistra.hail.action.FREEZE_NON_WHITELISTED`| *(없음)* | 화이트리스트 제외 모든 앱 동결 |
| `com.aistra.hail.action.LOCK_FREEZE` | *(없음)* | 모든 앱 동결 후 화면 잠금 |

### 2. URI Scheme (`hail://`)

웹 브라우저 링크나 바로가기 앱에서 직접 실행할 수 있습니다:

- **실행 / 동결 / 해제**:
  - `hail://launch?package=com.example.app`
  - `hail://freeze?package=com.example.app`
  - `hail://unfreeze?package=com.example.app`
- **동적 관리 (추가 / 삭제 / 일괄 추가)**:
  - `hail://add?package=com.example.app&tag=금융&freeze=true`
  - `hail://remove?package=com.example.app`
  - `hail://add_all?packages=com.pkg1,com.pkg2,com.pkg3&tag=소셜&freeze=true`
- **태그 및 전체 제어**:
  - `hail://freeze_tag?tag=금융`
  - `hail://unfreeze_tag?tag=금융`
  - `hail://freeze_all`
  - `hail://unfreeze_all`
  - `hail://lock_freeze`

---

## 🛠️ APK 빌드 스크립트 (`build_apk.sh`)

프로젝트 루트의 `build_apk.sh` 스크립트를 사용하여 DEV(디버그) 및 PROD(릴리즈 최적화) APK를 빌드하고 기기에 바로 설치할 수 있습니다.

### 빌드 명령어

```bash
# 1. DEV (Debug) APK 빌드 (Package ID: com.aistra.hail.debug)
./build_apk.sh dev

# 2. PROD (Release / R8 최적화) APK 빌드 (Package ID: com.aistra.hail)
./build_apk.sh prod

# 3. DEV + PROD 전체 빌드
./build_apk.sh all

# 4. 빌드 후 s26u 기기에 자동 전송 및 설치 (-i / --install)
./build_apk.sh dev -i
./build_apk.sh prod -i

# 5. Clean 후 빌드 (-c / --clean)
./build_apk.sh prod -c
```

### 산출물 위치
빌드된 APK는 프로젝트 루트의 `dist/` 폴더에 생성됩니다:
- `dist/Hail-DEV-Hail-v*.apk`: 디버깅용 APK
- `dist/Hail-PROD-Hail-v*.apk`: 프로덕션 배포용 최적화 APK

### 빌드 환경 설정 참고사항 (ARM64 / Raspberry Pi)
- 본 프로젝트는 Debian aarch64 환경에서도 빌드가 가능하도록 OpenJDK 21 및 네이티브 `aapt2`(`android-arm-build-tools`) 바인딩이 설정되어 있습니다.
- `gradle.properties`에 `android.aapt2FromMavenOverride` 및 저사양 메모리 튜닝(`-Xmx1024m`, worker 2개 제한)이 적용되어 있습니다.

---

## 📱 S26U 기기 동결 도구 (`s26u_freeze_tool.sh`) 연동

CSV 파일에 정리된 패키지 목록을 Hail 관리 DB에 원클릭으로 등록하고 관리할 수 있습니다:

```bash
# Hail 관리 DB에 CSV 앱 전체 일괄 등록 및 동결
~/s26u_freeze_tool.sh hail-add-batch

# 특정 앱 개별 추가
~/s26u_freeze_tool.sh hail-add com.skt.skaf.OA00018282

# 특정 앱 제거
~/s26u_freeze_tool.sh hail-remove com.skt.skaf.OA00018282
```

---

## 📄 라이선스 (License)

Hail은 GNU General Public License v3.0 (GPL-3.0)에 따라 배포되는 자유 소프트웨어입니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하십시오.
