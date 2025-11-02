# CLAUDE.md

This file provides a high-level overview for AI assistants working on this repository. For detailed setup, architecture, and deployment instructions, please refer to the main **[README.md](README.md)** file.

## Project Overview

CardStudio is a comprehensive **digital souvenir and exhibition platform** that creates interactive experiences for museums, tourist attractions, and cultural sites.

## Core Architecture

-   **Frontend**: Vue 3 with TypeScript, PrimeVue, and Vite.
-   **Backend**: Express.js server handling payments, translations, and AI features.
-   **Database**: Supabase PostgreSQL, accessed exclusively via stored procedures (`.rpc()`).
-   **Services**: Supabase (Auth, Storage), Stripe (Payments), OpenAI (AI/ML).

## Key Files & Directories

-   `README.md`: **Primary source of truth for all project documentation.**
-   `src/`: Frontend Vue application source.
-   `backend-server/`: Backend Express.js server source.
-   `sql/`: Database schema, stored procedures, and policies.
-   `scripts/deploy-cloud-run.sh`: All-in-one script for backend deployment to Google Cloud Run.