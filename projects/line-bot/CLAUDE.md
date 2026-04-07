# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LINE Messaging Bot built with Laravel 5.6 and the LINE Bot SDK v2.3. Receives webhook callbacks from LINE, processes messages, and replies/pushes messages back. Deployed on Heroku with Apache.

## Commands

```bash
# Install dependencies
composer install
npm install   # or: yarn install

# Run dev server
php artisan serve

# Build frontend assets
npm run dev          # one-time build
npm run watch        # watch mode
npm run prod         # production build

# Run tests
vendor/bin/phpunit                        # all tests
vendor/bin/phpunit tests/Unit             # unit only
vendor/bin/phpunit tests/Feature          # feature only
vendor/bin/phpunit tests/Unit/Services/LineBotServiceTest.php  # single test
```

## Architecture

```
LINE Platform --> POST /callback --> LineBotController::handle()
                                          |
                                    LineBotService
                                     - replyMessage()
                                     - pushMessage()
                                          |
                                    LINE Bot SDK (LINEBot)
                                          |
                                    LINE API
```

- **Routes**: `routes/web.php` and `routes/api.php` define the `/callback` endpoint
- **Controller**: `app/Http/Controllers/LineBotController.php` - webhook entry point
- **Service**: `app/Services/LineBotService.php` - message processing logic
- **DI bindings**: `app/Providers/AppServiceProvider.php` registers `LINEBot` and `LineBotService` as singletons, plus SlackService, TwitchService, ComicService

## Environment Variables

Critical LINE Bot credentials (set in `.env`, see `.env.example`):

- `LINEBOT_TOKEN` - LINE channel access token
- `LINEBOT_SECRET` - LINE channel secret
- `LINE_USER_ID` - target user ID for push messages

Optional integrations: `SLACK_WEBHOOK_URL`, `TWITCH_CLIENT_ID`

## Deployment

Heroku with Apache (`Procfile`: `web: vendor/bin/heroku-php-apache2 public/`).
