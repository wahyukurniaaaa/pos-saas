# Project Plan: Advanced Cloud Sync & Owner Analytics

Plan for implementing sophisticated synchronization, offline media handling, and cross-outlet business intelligence.

## Overview
- **Project Type**: MOBILE (Flutter)
- **Goal**: Transition from basic master-slave sync to a robust, fault-tolerant multi-device ecosystem with aggregated analytics.

## Success Criteria
- [ ] Conflicts resolved using Last Write Wins (LWW) without data loss.
- [ ] Stock calculations remain accurate across devices (Delta-sync).
- [ ] Product/Receipt images uploaded in the background without blocking the UI.
- [ ] Owner can view real-time "Total Sales" across all outlets from a single screen.

## Tech Stack
- **Framework**: Flutter (Riverpod for state management)
- **Local DB**: Drift (SQLite) + Work Manager (Background Tasks)
- **Cloud**: Supabase (PostgreSQL + Realtime + Storage)

## File Structure Changes
- `lib/features/analytics/` (New Feature Folder)
- `lib/core/services/upload_service.dart` (Background Upload handling)

## Task Breakdown

### Phase 1: Conflict Resolution & Delta-Sync
- **Task ID**: `conf-res-01`
- **Name**: "Delta Stock Logic Implementation"
- **Agent**: `mobile-developer`
- **Skills**: `clean-code`, `database-design`
- **Priority**: P0
- **INPUT**: Current stock update logic (Direct overwrite).
- **OUTPUT**: Function that sends `current_stock + delta` to Supabase.
- **VERIFY**: Perform updates on two devices simultaneously; final stock must equal the sum of changes.

### Phase 2: Background Media Sync
- **Task ID**: `bg-upload-01`
- **Name**: "Supabase Storage & WorkManager Integration"
- **Agent**: `mobile-developer`
- **Skills**: `app-builder`
- **Priority**: P1
- **INPUT**: Local image file paths.
- **OUTPUT**: Reliable background upload queue.
- **VERIFY**: Take photo -> Close app -> Check Supabase dashboard to verify file arrived after 1-2 minutes.

### Phase 3: Owner Dashboard
- **Task ID**: `analytics-01`
- **Name**: "Multi-Outlet Aggregation Screen"
- **Agent**: `mobile-developer`
- **Skills**: `frontend-design`, `api-patterns`
- **Priority**: P1
- **INPUT**: Supabase authenticated session with Owner role.
- **OUTPUT**: Dashboards displaying bar charts and KPIs for "All Outlets".
- **VERIFY**: Switch filter between 'Outlet A' and 'All Outlets'; totals should update correctly.

## Phase X: Verification Checklist
- [ ] Run `python .agent/scripts/checklist.py .`
- [ ] Verify UI flows on Android/iOS emulators.
- [ ] Inspect Supabase Storage usage.
- [ ] Confirm RLS (Row Level Security) prevents Managers from seeing other outlets' data.
