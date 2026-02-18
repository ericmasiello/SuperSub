# Phase Roadmap - Visual Summary

## 🎯 Project Goal
Transform 2 large view files into 26+ focused, testable components

**Before**: 1,059 lines in 2 files  
**After**: ~1,500 lines in 27+ files (better organized)

---

## 📈 Visual Progress Tracker

```
PHASE 1: TIMERVIEW REFACTORING
═══════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────┐
│ Phase 1.1: Timer Controls (1-2 days)                    [✅] │
├─────────────────────────────────────────────────────────────┤
│ Extract: TimerControlsView.swift                            │
│ Lines: 55 (COMPLETE)                                         │
│ Priority: HIGH - COMPLETE ✅                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 1.2: Time Display (1-2 days)                      [✅] │
├─────────────────────────────────────────────────────────────┤
│ Extract: PreferredTimeDisplayView.swift                     │
│          TimeFormatter.swift (utility - existed)             │
│ Lines: 112 + 138 (COMPLETE)                                 │
│ Priority: HIGH - COMPLETE ✅                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 1.3: Player Rows (2-3 days)                       [ ] │
├─────────────────────────────────────────────────────────────┤
│ Extract: ActivePlayerRowView.swift (~40 lines)              │
│          BenchPlayerRowView.swift (~40 lines)               │
│          TemporarilyOutPlayerRowView.swift (~30 lines)      │
│ Priority: HIGH                                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 1.4: Player Sections (2-3 days)                   [ ] │
├─────────────────────────────────────────────────────────────┤
│ Extract: ActivePlayersSectionView.swift (~60 lines)         │
│          BenchSectionView.swift (~60 lines)                 │
│          TemporarilyOutSectionView.swift (~50 lines)        │
│ Priority: MEDIUM                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 1.5: Substitution (2-3 days)                      [ ] │
├─────────────────────────────────────────────────────────────┤
│ Extract: SubstitutionButtonView.swift (~40 lines)           │
│          ManualSubstitutionSheetView.swift (~60 lines)      │
│          PlayerActionsSheetView.swift (~80 lines)           │
│ Priority: MEDIUM                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 1.6: Consolidate (1-2 days)                       [ ] │
├─────────────────────────────────────────────────────────────┤
│ Update: TimerView.swift (reduce to <200 lines)              │
│ Add: Integration tests, documentation                       │
│ Priority: HIGH                                               │
└─────────────────────────────────────────────────────────────┘

Progress: [██████░░░░] 33% (2/6 phases) ✅
Timeline: 10-18 days (2 days elapsed)


PHASE 2: SETTINGSVIEW REFACTORING
═══════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────┐
│ Phase 2.1: Player Management (2-3 days)                 [ ] │
├─────────────────────────────────────────────────────────────┤
│ Extract: PlayerListSectionView.swift (~60 lines)            │
│          PlayerRowView.swift (~40 lines)                    │
│          AddPlayerSheetView.swift (~50 lines)               │
│          EditPlayerSheetView.swift (~100 lines)             │
│ Priority: MEDIUM                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 2.2: Configuration (1-2 days)                     [ ] │
├─────────────────────────────────────────────────────────────┤
│ Extract: ConfigurationSectionView.swift (~60 lines)         │
│          ActivePlayersStepperView.swift (~40 lines)         │
│          PreferredTimePickerView.swift (~50 lines)          │
│ Priority: LOW                                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 2.3: Session Management (2-3 days)                [ ] │
├─────────────────────────────────────────────────────────────┤
│ Extract: SessionManagementSectionView.swift (~40 lines)     │
│          SessionHistoryView.swift (~80 lines)               │
│          SessionRowView.swift (~40 lines)                   │
│ Priority: LOW                                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Phase 2.4: Consolidate (1 day)                          [ ] │
├─────────────────────────────────────────────────────────────┤
│ Update: SettingsView.swift (reduce to <150 lines)           │
│ Add: Integration tests, documentation                       │
│ Priority: MEDIUM                                             │
└─────────────────────────────────────────────────────────────┘

Progress: [░░░░░░░░░░] 0% (0/4 phases)
Timeline: 5-8 days


PHASE 3: SHARED COMPONENTS
═══════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────┐
│ Phase 3.0: Component Library (1-2 days)                 [ ] │
├─────────────────────────────────────────────────────────────┤
│ Extract: EmptyStateView.swift (~30 lines)                   │
│          SectionHeaderView.swift (~30 lines)                │
│          PlayerStatusBadge.swift (~40 lines)                │
│          TimeDisplayView.swift (~30 lines)                  │
│ Organize: Final directory structure                         │
│ Document: Component showcase and guide                      │
│ Priority: LOW                                                │
└─────────────────────────────────────────────────────────────┘

Progress: [░░░░░░░░░░] 0% (0/1 phases)
Timeline: 1-2 days
```

---

## 📊 Overall Progress

```
╔═══════════════════════════════════════════════════════════════╗
║                    REFACTORING PROGRESS                       ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Phase 1 (TimerView):      [████░░░░░░] 2/6  ( 33%)          ║
║  Phase 2 (SettingsView):   [░░░░░░░░░░] 0/4  (  0%)          ║
║  Phase 3 (Shared):         [░░░░░░░░░░] 0/1  (  0%)          ║
║                            ─────────────────                  ║
║  TOTAL:                    [██░░░░░░░░] 2/11 ( 18%)          ║
║                                                               ║
║  Components Created:       2 / 26                            ║
║  Lines Refactored:         51 / 1,059                        ║
║  Days Elapsed:             1 / 22 (estimated)                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 🎯 Current Focus

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  👉 NEXT ACTION: Start Phase 1.3                           ┃
┃                                                             ┃
┃  Task: Extract Player Row Components (3 components)        ┃
┃  Files: ActivePlayerRowView.swift                          ┃
┃         BenchPlayerRowView.swift                           ┃
┃         TemporarilyOutPlayerRowView.swift                  ┃
┃  Est. Time: 2-3 days                                        ┃
┃  Guide: See REFACTORING_PRD.md → Phase 1.3                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## 📅 Week-by-Week Plan

### Week 1: TimerView Foundation
```
Mon-Tue:   Phase 1.1 - Timer Controls        [░░]
Wed-Thu:   Phase 1.2 - Time Display          [░░]
Fri:       Phase 1.3 - Player Rows (start)   [░]
           
Progress: ~20% of refactoring complete
```

### Week 2: TimerView Completion
```
Mon-Tue:   Phase 1.3 - Player Rows (finish)  [░░]
Wed-Thu:   Phase 1.4 - Player Sections       [░░]
Fri:       Phase 1.5 - Substitution (start)  [░]
           
Progress: ~50% of refactoring complete
```

### Week 3: SettingsView
```
Mon-Tue:   Phase 1.5 - Substitution (finish) [░░]
           Phase 1.6 - Consolidate TimerView [░]
Wed-Thu:   Phase 2.1 - Player Management     [░░]
Fri:       Phase 2.2 - Configuration         [░]
           
Progress: ~75% of refactoring complete
```

### Week 4: Finish & Polish
```
Mon:       Phase 2.3 - Session Management    [░]
Tue:       Phase 2.4 - Consolidate Settings  [░]
Wed:       Phase 3.0 - Shared Components     [░]
Thu-Fri:   Buffer / Testing / Documentation  [░░]
           
Progress: 100% of refactoring complete ✅
```

---

## 🏆 Milestone Tracker

| Milestone | Phase | Status | Date |
|-----------|-------|--------|------|
| First component created | 1.1 | ✅ Complete | Feb 17, 2026 |
| Timer controls working | 1.1 | ✅ Complete | Feb 17, 2026 |
| Time formatting extracted | 1.2 | ✅ Complete | Feb 17, 2026 |
| All player rows componentized | 1.3 | ⬜ Not Started | ___ |
| All sections componentized | 1.4 | ⬜ Not Started | ___ |
| Substitution flow complete | 1.5 | ⬜ Not Started | ___ |
| **TimerView refactored** | 1.6 | ⬜ Not Started | ___ |
| Player CRUD componentized | 2.1 | ⬜ Not Started | ___ |
| Config settings extracted | 2.2 | ⬜ Not Started | ___ |
| Session mgmt componentized | 2.3 | ⬜ Not Started | ___ |
| **SettingsView refactored** | 2.4 | ⬜ Not Started | ___ |
| Shared library created | 3.0 | ⬜ Not Started | ___ |
| **PROJECT COMPLETE** | 3.0 | ⬜ Not Started | ___ |

Legend: ⬜ Not Started | 🚧 In Progress | ✅ Complete

---

## 📦 Component Delivery Schedule

### Sprint 1: Timer Basics (Days 1-4) ✅
- [✅] TimerControlsView (COMPLETE)
- [✅] PreferredTimeDisplayView (COMPLETE)
- [✅] TimeFormatter utility (COMPLETE)

### Sprint 2: Player Display (Days 5-10)
- [ ] ActivePlayerRowView
- [ ] BenchPlayerRowView
- [ ] TemporarilyOutPlayerRowView
- [ ] ActivePlayersSectionView
- [ ] BenchSectionView
- [ ] TemporarilyOutSectionView

### Sprint 3: Actions (Days 11-15)
- [ ] SubstitutionButtonView
- [ ] ManualSubstitutionSheetView
- [ ] PlayerActionsSheetView
- [ ] Refactored TimerView

### Sprint 4: Settings (Days 16-20)
- [ ] PlayerListSectionView
- [ ] PlayerRowView
- [ ] AddPlayerSheetView
- [ ] EditPlayerSheetView
- [ ] ConfigurationSectionView
- [ ] ActivePlayersStepperView
- [ ] PreferredTimePickerView

### Sprint 5: Polish (Days 21-22)
- [ ] SessionManagementSectionView
- [ ] SessionHistoryView
- [ ] SessionRowView
- [ ] Refactored SettingsView
- [ ] Shared components
- [ ] Documentation

---

## 🎨 Component Categories

```
Timer Components (6)          Settings Components (10)
├─ TimerControlsView         ├─ PlayerListSectionView
├─ PreferredTimeDisplayView  ├─ PlayerRowView
├─ SubstitutionButtonView    ├─ AddPlayerSheetView
└─ (3 sheets/modals)         ├─ EditPlayerSheetView
                             ├─ ConfigurationSectionView
Player Components (6)        ├─ ActivePlayersStepperView
├─ ActivePlayerRowView       ├─ PreferredTimePickerView
├─ BenchPlayerRowView        ├─ SessionManagementSectionView
├─ TemporarilyOutPlayerRowView ├─ SessionHistoryView
├─ ActivePlayersSectionView  └─ SessionRowView
├─ BenchSectionView          
└─ TemporarilyOutSectionView Shared Components (4)
                             ├─ EmptyStateView
                             ├─ SectionHeaderView
                             ├─ PlayerStatusBadge
                             └─ TimeDisplayView
```

---

## 🔄 Daily Workflow

```
┌─────────────────────────────────────────────────────┐
│ 👉 CURRENT FOCUS: Phase 1.3 - Player Rows          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  COMPLETED TODAY:                                   │
│  ✅ Phase 1.1: Timer Controls (55 lines)           │
│  ✅ Phase 1.2: Time Display (112 lines)            │
│                                                     │
│  NEXT UP:                                           │
│  → Phase 1.3: Extract 3 player row components      │
│     • ActivePlayerRowView                          │
│     • BenchPlayerRowView                           │
│     • TemporarilyOutPlayerRowView                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 📈 Success Metrics Dashboard

```
╔═══════════════════════════════════════════════════════════╗
║                     TARGET METRICS                        ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  TimerView Size Reduction:                                ║
║  Before: 634 lines  →  Target: <200 lines                ║
║  [█████░░░░░░░░░░░░░░░░░░░░░░] Current: 583 (8%)         ║
║                                                           ║
║  SettingsView Size Reduction:                             ║
║  Before: 425 lines  →  Target: <150 lines                ║
║  [████████████████████░░░░░░░░░] Current: 425 (0%)       ║
║                                                           ║
║  Components Created:          2 / 26  (7.7%)              ║
║  Components with Previews:    2 / 26  (7 total previews)  ║
║  Test Coverage:               Maintained ✓                ║
║  Breaking Changes:            0 (target: 0) ✓             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 🎯 Quick Access

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **PHASE_ROADMAP.md** | Visual progress | Check daily progress |
| REFACTORING_INDEX.md | Navigation hub | First time orientation |
| REFACTORING_README.md | Project overview | Before starting |
| REFACTORING_PRD.md | Detailed specs | Before each phase |
| QUICKSTART.md | Getting started | Ready to code |
| REFACTORING_CHECKLIST.md | Task tracking | Daily work |
| REFACTORING_SNIPPETS.md | Code examples | While coding |
| COMPONENT_ARCHITECTURE.md | System design | When confused |

---

## 🚀 Let's Go!

**Current Status**: In Progress - Phase 1.3 Next 🚀  
**Last Completed**: Phase 1.2 - Time Display (Feb 17, 2026) ✅  
**Next Action**: Phase 1.3 - Extract Player Row Components  
**Estimated Completion**: 3-5 weeks from start (Day 1 complete)  

**Remember**: 
- One component at a time
- Validate before moving on
- Track progress in this document
- You've got this! 💪

---

*Update this document as you complete each phase!*