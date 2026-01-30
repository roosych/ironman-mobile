#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}🔍 Проверка текущего окружения...${NC}\n"

# Проверяем наличие активных конфигов
if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${RED}❌ Android конфигурация не найдена${NC}"
    echo -e "${YELLOW}ℹ️  Запустите: ./switch-env.sh [dev|staging|prod]${NC}\n"
    exit 1
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${RED}❌ iOS конфигурация не найдена${NC}"
    echo -e "${YELLOW}ℹ️  Запустите: ./switch-env.sh [dev|staging|prod]${NC}\n"
    exit 1
fi

# Получаем project_id из Android конфига
PROJECT_ID=$(grep '"project_id"' android/app/google-services.json | cut -d '"' -f 4)

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Не удалось определить project_id${NC}\n"
    exit 1
fi

echo -e "${GREEN}✅ Активное окружение:${NC} $PROJECT_ID"

# Определяем тип окружения
case $PROJECT_ID in
    *-dev)
        echo -e "${BLUE}🔧 Тип: DEVELOPMENT${NC}"
        ;;
    *-staging)
        echo -e "${YELLOW}🧪 Тип: STAGING${NC}"
        ;;
    *-prod)
        echo -e "${PURPLE}🚀 Тип: PRODUCTION${NC}"
        ;;
    *)
        echo -e "${RED}❓ Тип: НЕИЗВЕСТНЫЙ${NC}"
        ;;
esac

echo

# Показываем информацию о конфигурации
echo -e "${BLUE}📱 Конфигурация:${NC}"
if [ -f "android/app/google-services.json" ]; then
    ANDROID_APP_ID=$(grep '"mobilesdk_app_id"' android/app/google-services.json | head -1 | cut -d '"' -f 4)
    echo -e "   Android App ID: ${ANDROID_APP_ID}"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    IOS_APP_ID=$(grep -A 1 "GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist | tail -1 | sed 's/<string>//g' | sed 's/<\/string>//g' | sed 's/^[ \t]*//')
    if [ ! -z "$IOS_APP_ID" ]; then
        echo -e "   iOS App ID: ${IOS_APP_ID}"
    fi
fi

echo

# Показываем историю переключений
if [ -f "switch-env.log" ]; then
    echo -e "${BLUE}📊 Последние переключения:${NC}"
    tail -3 switch-env.log | while read line; do
        echo -e "   ${line}"
    done
else
    echo -e "${YELLOW}ℹ️  История переключений пуста${NC}"
fi

echo