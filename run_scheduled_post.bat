@echo off
REM Scheduled Facebook posting run — triggered by Windows Task Scheduler
REM Runs Claude Code headlessly in this project folder using CLAUDE.md rules.
REM Cadence: Mon/Wed/Fri, ~6:00 PM NPT (set the matching trigger in Task Scheduler)

cd /d F:\KRISHNA\mediahandler

REM -p runs a single prompt non-interactively and exits when done.
REM Adjust the prompt text below to change what gets posted each run.
claude -p "Following the rules in CLAUDE.md, create today's scheduled Facebook post for our Page. Pick a topic in line with the content mix. Follow the Approval Workflow setting exactly — do not publish directly unless Auto-publish is explicitly checked in CLAUDE.md."

echo Done. Check post_log.txt or your Facebook Page to confirm.
pause
