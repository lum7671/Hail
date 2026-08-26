#!/usr/bin/env bash
# ==============================================================================
# 🧊 Hail APK Build Automation Script (DEV & PROD)
# ==============================================================================
# 사용법:
#   ./build_apk.sh dev          : DEV (Debug) APK 빌드
#   ./build_apk.sh prod         : PROD (Release) APK 빌드
#   ./build_apk.sh all          : DEV + PROD 동시 빌드
#   ./build_apk.sh dev -i       : DEV 빌드 후 s26u 기기에 자동 설치
#   ./build_apk.sh prod -i      : PROD 빌드 후 s26u 기기에 자동 설치
#   ./build_apk.sh prod -c      : Clean 후 PROD 빌드
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUTPUT_DIR="$SCRIPT_DIR/dist"
mkdir -p "$OUTPUT_DIR"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "=================================================================="
    echo " 🔨 Hail APK Build System"
    echo "=================================================================="
    echo -e "${NC}"
}

usage() {
    print_header
    echo -e "${BOLD}사용법:${NC}"
    echo "  $0 <모드> [옵션]"
    echo ""
    echo -e "${BOLD}빌드 모드:${NC}"
    echo -e "  ${GREEN}dev${NC}   | ${GREEN}debug${NC}    : 개발용 디버그 빌드 (Package ID: com.aistra.hail.debug)"
    echo -e "  ${YELLOW}prod${NC}  | ${YELLOW}release${NC}  : 배포용 릴리즈 빌드 (Package ID: com.aistra.hail, R8 최적화)"
    echo -e "  ${CYAN}all${NC}              : DEV 및 PROD 전체 빌드"
    echo ""
    echo -e "${BOLD}옵션:${NC}"
    echo -e "  ${BLUE}-i, --install${NC}    : 빌드 완료 후 s26u 기기에 자동 전송 및 설치"
    echo -e "  ${BLUE}-c, --clean${NC}      : 빌드 전 clean 작업 수행"
    echo -e "  ${BLUE}-h, --help${NC}       : 사용법 안내"
    echo ""
    echo -e "${BOLD}예시:${NC}"
    echo "  $0 dev"
    echo "  $0 prod -i"
    echo "  $0 all"
    echo "=================================================================="
    exit 0
}

# 파라미터 파싱
MODE=""
INSTALL=false
CLEAN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        dev|debug|d)
            MODE="dev"
            shift
            ;;
        prod|release|p)
            MODE="prod"
            shift
            ;;
        all|a)
            MODE="all"
            shift
            ;;
        -i|--install)
            INSTALL=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}❌ 알 수 없는 인자: $1${NC}"
            usage
            ;;
    esac
done

if [ -z "$MODE" ]; then
    usage
fi

print_header

# Clean 수행
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}[*] Gradle Clean 수행 중...${NC}"
    ./gradlew clean --no-daemon
    echo -e "${GREEN}✅ Clean 완료!${NC}\n"
fi

# 기기 설치 함수
install_to_device() {
    local apk_path="$1"
    local apk_name="$(basename "$apk_path")"
    
    echo -e "\n${BLUE}[*] 📲 s26u 기기에 APK 전송 및 설치 진행 중... ($apk_name)${NC}"
    if ssh -q -o ConnectTimeout=3 s26u exit 2>/dev/null; then
        scp "$apk_path" s26u:/sdcard/Download/"$apk_name"
        ssh s26u "rish -c 'pm install -r /sdcard/Download/$apk_name'" < /dev/null
        echo -e "${GREEN}✅ s26u 기기에 $apk_name 설치 완료!${NC}"
    elif command -v adb >/dev/null 2>&1 && adb devices | grep -q "device$"; then
        adb install -r "$apk_path"
        echo -e "${GREEN}✅ ADB 기기에 $apk_name 설치 완료!${NC}"
    else
        echo -e "${YELLOW}⚠️  연결된 기기(s26u / adb)를 찾을 수 없어 설치를 건너뜁니다.${NC}"
        echo -e "👉 빌드된 파일: $apk_path"
    fi
}

# 빌드 실행 함수
build_variant() {
    local variant="$1" # "dev" or "prod"
    local gradle_task=""
    local build_type=""
    local apk_dir=""

    if [ "$variant" = "dev" ]; then
        echo -e "${GREEN}${BOLD}▶ [DEV] Debug APK 빌드 시작...${NC}"
        gradle_task="assembleDebug"
        build_type="debug"
    else
        echo -e "${YELLOW}${BOLD}▶ [PROD] Release APK 빌드 시작 (R8 최적화)...${NC}"
        gradle_task="assembleRelease"
        build_type="release"
    fi

    local start_time=$(date +%s)
    ./gradlew "$gradle_task" --no-daemon

    apk_dir="$SCRIPT_DIR/app/build/outputs/apk/$build_type"
    local built_apk=$(find "$apk_dir" -maxdepth 1 -name "*.apk" | head -n 1)

    if [ -z "$built_apk" ] || [ ! -f "$built_apk" ]; then
        echo -e "${RED}❌ 빌드 실패: 생성된 APK를 찾을 수 없습니다. ($apk_dir)${NC}"
        return 1
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # dist 폴더로 복사 및 표준 네이밍
    local base_name="$(basename "$built_apk")"
    local dest_name=""
    if [ "$variant" = "dev" ]; then
        dest_name="Hail-DEV-${base_name}"
    else
        dest_name="Hail-PROD-${base_name}"
    fi
    local final_dest="$OUTPUT_DIR/$dest_name"
    cp -f "$built_apk" "$final_dest"

    local file_size=$(du -h "$final_dest" | cut -f1)
    local sha256=$(sha256sum "$final_dest" | awk '{print $1}')

    echo -e "${GREEN}=================================================================="
    echo -e " 🎉 [${variant^^}] APK 빌드 성공! (${duration}초 소요)"
    echo -e " 📁 파일: ${BOLD}$final_dest${NC}"
    echo -e " 📦 크기: $file_size"
    echo -e " 🔒 SHA256: ${CYAN}$sha256${NC}"
    echo -e "${GREEN}==================================================================${NC}"

    if [ "$INSTALL" = true ]; then
        install_to_device "$final_dest"
    fi
}

# 메인 실행 분기
case "$MODE" in
    dev)
        build_variant "dev"
        ;;
    prod)
        build_variant "prod"
        ;;
    all)
        build_variant "dev"
        echo ""
        build_variant "prod"
        ;;
esac

echo -e "\n${CYAN}✨ 모든 빌드 작업이 완료되었습니다. 결과물 폴더: ${BOLD}$OUTPUT_DIR${NC}"
