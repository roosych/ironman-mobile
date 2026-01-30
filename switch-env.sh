#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ $# -eq 0 ]; then
    echo -e "\n${RED}❌ Использование: ./switch-env.sh [dev|prod]${NC}"
    echo -e "\n${BLUE}📱 Доступные окружения:${NC}"
    echo -e "   dev     - Разработка"
    echo -e "   prod    - Продакшн\n"
    exit 1
fi

ENV=$1

echo -e "\n${BLUE}🔄 Переключение на $ENV окружение...${NC}\n"

SOURCE_ENV=$ENV

# Проверяем существование файлов для выбранного окружения
if [ ! -f "firebase-configs/$SOURCE_ENV/google-services.json" ]; then
    echo -e "${RED}❌ Файл firebase-configs/$SOURCE_ENV/google-services.json не найден!${NC}"
    echo -e "\n${YELLOW}📋 Инструкция:${NC}"
    echo -e "1. Скачайте google-services.json из Firebase Console для $ENV проекта"
    echo -e "2. Поместите его в firebase-configs/$ENV/\n"
    exit 1
fi

if [ ! -f "firebase-configs/$SOURCE_ENV/GoogleService-Info.plist" ]; then
    echo -e "${RED}❌ Файл firebase-configs/$SOURCE_ENV/GoogleService-Info.plist не найден!${NC}"
    echo -e "\n${YELLOW}📋 Инструкция:${NC}"
    echo -e "1. Скачайте GoogleService-Info.plist из Firebase Console для $ENV проекта"
    echo -e "2. Поместите его в firebase-configs/$ENV/\n"
    exit 1
fi

# Создаем директории если они не существуют
mkdir -p android/app
mkdir -p ios/Runner

# Копируем Android конфиг
if cp "firebase-configs/$SOURCE_ENV/google-services.json" "android/app/google-services.json"; then
    echo -e "${GREEN}✅ Android конфиг обновлен (из $SOURCE_ENV)${NC}"
else
    echo -e "${RED}❌ Ошибка обновления Android конфига${NC}"
    exit 1
fi

# Копируем iOS конфиг
if cp "firebase-configs/$SOURCE_ENV/GoogleService-Info.plist" "ios/Runner/GoogleService-Info.plist"; then
    echo -e "${GREEN}✅ iOS конфиг обновлен (из $SOURCE_ENV)${NC}"
else
    echo -e "${RED}❌ Ошибка обновления iOS конфига${NC}"
    exit 1
fi

# Логируем переключение
echo "$(date) - Switched to $ENV environment" >> switch-env.log

echo -e "\n${GREEN}🎯 Переключение на $ENV завершено!${NC}\n"

# Показываем информацию о текущем проекте
if [ -f "android/app/google-services.json" ]; then
    PROJECT_ID=$(grep '"project_id"' android/app/google-services.json | cut -d '"' -f 4)
    echo -e "${BLUE}📊 Текущий Firebase проект:${NC} $PROJECT_ID"
fi

echo -e "\n${YELLOW}⚠️  Не забудьте переключить бекенд на то же окружение!${NC}\n"