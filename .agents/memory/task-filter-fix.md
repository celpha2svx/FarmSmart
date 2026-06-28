---
name: Task template filter bug
description: The get_task_templates region/season filter must skip the filter when value is "all", not filter for literal "all"
---

## Rule
When `region="all"` is requested, skip the region WHERE clause entirely — do not filter `WHERE region = "all"`.

**Why:** The seeded templates have `region="north"` or `region="south"` for region-specific tasks, and `region="all"` only for universal tasks. Querying `WHERE region="all"` would only return universal tasks, missing all regional ones. The same applies for `season="all"`.

**How to apply:** In `get_task_templates` (database/operations.py):
```python
if region != "all":
    q = q.filter((FarmingTaskTemplate.region == region) | (FarmingTaskTemplate.region == "all"))
if season != "all":
    q = q.filter((FarmingTaskTemplate.season == season) | (FarmingTaskTemplate.season == "all"))
```
