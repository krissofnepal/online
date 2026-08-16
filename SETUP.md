# Setup Guide — Facebook Auto-Posting via Claude Code + Composio

## 1. Move this folder to your machine
Copy everything in this project to `F:\KRISHNA\mediahandler` (or wherever you keep it).

## 2. Get a Composio API key
- Go to https://dashboard.composio.dev and sign up / log in.
- Copy your API key from the dashboard.

## 3. Fill in `.env`
- Rename `.env.example` to `.env`.
- Paste your real `COMPOSIO_API_KEY` in.
- Set `USER_ID` to anything unique (e.g. `krishna-fb`).

## 4. Install dependencies
Open a terminal in `F:\KRISHNA\mediahandler` and run:
```
npm install
```

## 5. Generate the Facebook MCP URL
```
npm run generate-mcp-url
```
This prints an MCP URL and a ready-to-run `claude mcp add ...` command. Copy that command.

## 6. Register the MCP server with Claude Code
Paste the copied command into your terminal, e.g.:
```
claude mcp add --transport http facebook-composio "https://...mcp.url..." --headers "X-API-Key:your_key"
```
Then restart Claude Code:
```
exit
claude
```

## 7. Verify it connected
```
claude mcp list
```
You should see `facebook-composio` in the list.

## 8. Authenticate your Facebook Page
- Inside Claude Code, run: `claude` then `/mcp`
- Select Composio, click Authenticate.
- It opens a browser OAuth flow — log in to Facebook, approve access to your Page.
- Confirm back in the terminal once done.

## 9. Fill in CLAUDE.md
Open `CLAUDE.md` in this folder and fill in the [ ] sections — your Page name, brand voice,
posting frequency, and approval preference. Claude Code reads this automatically every
time it runs in this folder, so you only set it once.

## 10. Test it
From inside this folder, run `claude` and try:
```
"Post an update about our new tour package to our Facebook Page"
```
If you set Approval Workflow to "draft only" in CLAUDE.md, Claude will show you the draft
first rather than publishing immediately — good for your first few runs.

---

# Automating the Regular Cadence

Once single posts work, choose ONE of these two approaches for recurring posting:

### Option A — Windows Task Scheduler (simplest, fully local)
1. Use `run_scheduled_post.bat` (included in this folder) as the trigger script.
2. Open Windows Task Scheduler → Create Task.
3. Trigger: your chosen days/times (e.g. Mon/Wed/Fri 10:00 AM).
4. Action: run `run_scheduled_post.bat`.
5. This calls Claude Code headlessly with a fixed prompt telling it to draft + post
   according to CLAUDE.md's rules.
6. Note: this runs Claude Code in non-interactive mode, so set Approval Workflow to
   "Auto-publish" in CLAUDE.md if you want this to run with zero manual steps — otherwise
   it'll wait for confirmation and the scheduled run will hang. Safer version: have it
   draft to a file instead of auto-publishing, and review before you manually approve.

### Option B — Claude Desktop Scheduled Tasks (no Task Scheduler needed)
1. Open Claude Desktop, go to Scheduled Tasks (or Cowork).
2. Create a recurring task: "Every Mon/Wed/Fri at 10am, using the Facebook connector,
   draft and post content per the brand voice and posting rules, matching today's topic
   focus from the content mix."
3. Point it at this project folder so it picks up CLAUDE.md context.
4. Claude Desktop must remain open on your machine for local scheduled tasks to fire
   (unless run via Cowork's cloud execution, which doesn't require your machine to stay on).

Recommended: start with Option B while you're building trust in the output quality,
then move to Option A only once you're comfortable letting it auto-publish unattended.
