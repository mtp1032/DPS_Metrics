# DPS_Metrics
## VERSION 
0.5.0 (Beta)
## DESCRIPTION
DPS_Metrics is an addon that collects personal encounter combat performance metrics. In this context 'personal' means that the encounter metrics are collected for a single character (UnitName("Player) and the character's pet (UnitName("Pet)). For the purposes of data collection, an encounter is defined as the time over which a single character (includng its pet) engages with one or more enemy NPCs. Combat ends witht he last NPC dies.
What differentiates DPS_Metrics from other combat-oriented addons its ability to collect accurate combat metrics from target dummies.

NB: this is important since Blizzard's combat dummies do not die. Hence, event-based (e.g., "UNIT_DEATH" or "PARTY_KILL") measurements are not readily derived from practice sessions with a target dummy. DPS_Metrics displays a target-dummy's health bar that responds to damaging attacks. When the health bar reaches zero, the combat stats are collected and summarized.
