# Changelog

---

## v1.3 — Operator Dashboard Refactor

### Added
- GridStack based movable/resizable widgets
- Design Mode toggle
- Persistent widget layout storage
- Unified operator dashboard grid
- Git repository initialization

### New Widgets
- Status widget
- GPS / Location widget
- Battery widget
- Phone model widget
- Device information widget
- Network / IP widget
- Camera widget
- Audio widget

### Audio Improvements
- Separate operator audio handling
- Client mute/unmute controls
- Remote volume handling
- Operator audio controls inside Audio widget

### Camera Improvements
- Multi-camera support
- Primitive camera stream handling
- Camera selector widget
- Dynamic stream management
- Separate operator camera controls

### Connection Handling
- Client disconnect detection
- Reconnect handling
- Stream counter in status widget
- Improved operator/client state handling

### Dashboard / UI
- Unified draggable dashboard layout
- Widget resize support
- Persistent layout between reloads
- Design mode controls
- Widget cleanup and normalization

### Cleanup
- Removed duplicated legacy UI elements
- Removed obsolete labels and status displays
- Unified dashboard styling
- Removed duplicate audio/camera controls

### Internal
- Added GridStack
- Added local layout persistence
- Added dashboard patch scripts
- Added backup/restore workflow

---

## Notes
Version 1.3 introduces the first modular operator dashboard architecture
with draggable widgets and persistent layout handling.
