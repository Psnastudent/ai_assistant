# Animated Desktop Assistant 🤖

[![Auto Commit](https://github.com/Psnastudent/ai_assistant/actions/workflows/auto_commit.yml/badge.svg)](https://github.com/Psnastudent/ai_assistant/actions/workflows/auto_commit.yml)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![ElevenLabs](https://img.shields.io/badge/ElevenLabs-AI_Voice-black?style=for-the-badge)

A smart, animated desktop assistant for Windows built with Flutter. It lives on your desktop, provides a floating UI, and speaks notifications out loud using ElevenLabs AI!

## Features 🚀
- **Transparent Floating UI**: Stays on top of other windows using `window_manager` and `bitsdojo_window`.
- **Draggable Character**: Move your assistant anywhere on your screen.
- **AI Text-to-Speech**: Integrated with the ElevenLabs API for realistic, dynamic voices.
- **Notification Reactivity**: Character physically reacts (jumps) when a new notification comes in.

## Installation 💻
1. Ensure **Developer Mode** is enabled in your Windows settings.
2. Clone this repository.
3. Run `flutter pub get`.
4. Run `flutter run -d windows`.

## Daily Automation (Developer Logs)
To track daily progress and keep the GitHub contribution graph active, this project uses a custom `daily_commit.ps1` script to automate daily commits and push progress to the repository.