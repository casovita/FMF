# Skill: fitness-domain

Reference for FMF domain model and academy terminology.

## Usage

```
/fitness-domain [concept]
```

Example: `/fitness-domain skill`

---

## Domain Concepts

### Skill
A specific fitness ability being trained.
```dart
Skill { id, name, description, category: SkillCategory }
SkillCategory: { balance, strength, bodyweight }
```
Instances: `handstand`, `pullups`, `handstand_pushups`

### SkillTrack
The progression path within a skill. A skill has multiple ordered tracks.
```dart
SkillTrack { id, skillId, name, order, description, requiredPracticeCount }
```

### PracticeSession
A logged training session for a skill.
```dart
PracticeSession { id, skillId, date, durationMinutes, notes?, completedAt? }
```

### ProgressSnapshot
Point-in-time record of a user's progress in a skill or track.
```dart
ProgressSnapshot { id, skillId, trackId?, snapshotDate, practiceCount, lastPracticeDate? }
```

### AcademyModuleSummary
Summary card data for the home dashboard (computed, not persisted).
```dart
AcademyModuleEntry { skillId, title, description, route }
```

---

## Repository Interfaces

```dart
// fmf_domain
abstract interface class SkillRepository {
  Future<List<Skill>> getSkills();
  Future<Skill?> getSkillById(String id);
  Stream<ProgressSnapshot?> watchSkillProgress(String skillId);
}

abstract interface class PracticeSessionRepository {
  Future<void> logSession(PracticeSession session);
  Future<List<PracticeSession>> getSessionsForSkill(String skillId);
  Future<List<PracticeSession>> getRecentSessions({int limit = 10});
}
```

---

## Academy Language Rules

| Use                 | Avoid                    |
|---------------------|--------------------------|
| module              | page / section           |
| track / progression track | level / tier      |
| practice session    | workout / exercise       |
| skill               | move / drill             |
| enroll / begin training | start / unlock      |
| curriculum          | program / plan           |
| progression         | progress bar / level up  |
