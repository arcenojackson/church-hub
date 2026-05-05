#!/bin/bash
set -e

echo ""
echo "========================================"
echo "Limpando projeto..."
echo "========================================"
echo ""
flutter clean

echo ""
echo "========================================"
echo "Instalando dependencias..."
echo "========================================"
echo ""
flutter pub get

echo ""
echo "========================================"
echo "Gerando build Android (App Bundle)..."
echo "========================================"
echo ""
flutter build appbundle --release

echo ""
echo "========================================"
echo "Gerando build iOS..."
echo "========================================"
echo ""
flutter build ios --release

echo ""
echo "========================================"
echo "Abrindo Xcode..."
echo "========================================"
echo ""
open ios/Runner.xcworkspace
