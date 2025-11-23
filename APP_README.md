## CamSplit Mobile App – Connection Notes

**Backend hosting**: The CamSplit API is deployed on Render using the free tier.

### Why the app may appear "offline"
- **Free-tier cold starts**: Render free instances go to sleep after a period of inactivity. The first request after sleeping has to wake the server, which can take 15–60 seconds (sometimes a bit longer).
- During this warm-up window, the app may show connection errors or time out.

### What to do if the connection seems down
1. Wait ~30–60 seconds to allow the server to start.
2. From the app, try the action again (pull-to-refresh, navigate back and re-open, or retry the previous action).
3. If it still fails after 2–3 attempts, wait another minute and retry.

### Tips
- Keep the app open for a moment after the first launch so the backend can finish booting.
- Subsequent actions should be fast once the server is warm.

### Known limitations of free hosting
- Instance may sleep after inactivity, causing occasional delays on the next request.
- Short idle timeouts can end longer-running background work.

### Reporting issues
If the app continues to show connectivity errors after several minutes, please share:
- The approximate time you tried
- What screen/action you were on
- Any error message shown

This helps verify whether it was a cold start or something else.

— CamSplit Team


