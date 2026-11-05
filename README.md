# Candy Collector

A cute Roblox script that creates a candy-themed GUI to track candies collected in games like MM2, sends adorable Discord embeds to your channel whenever candy is collected, and provides a summary embed every 5 minutes. The script automatically detects candy collection from your player data, displays your candy count in a pastel-colored interface, and lets you save your Discord webhook URL directly through the GUI.

## Install

1. Open your Roblox Studio project.
2. In the Explorer, go to `ServerScriptService` (or any server script location).
3. Insert a new `Script` into that folder.
4. Open the script editor and replace the default contents with the code from `src/CandyCollector.server.lua`.
5. (Optional) If you're using a different data storage path than `playerdata.Candy`, modify the `CANDY_PATH` constant near the top of the script.

## Use

1. Run your Roblox game. The Candy Collector GUI will appear for each player.
2. In the GUI, paste your Discord webhook URL into the text box.
3. Click the "Save 💖" button to store your webhook (it's saved to DataStore so you only need to enter it once).
4. Play normally and collect candies in your game – each time your candy count increases, a cute embed will be sent to your Discord channel.
5. Every 5 minutes, a summary embed shows your session's collected candies and current balance.
6. The GUI displays your current candy count in real-time.

---

More Roblox script projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/7053ac04-fab1-4595-8209-26eddd3619dc?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=7053ac04-fab1-4595-8209-26eddd3619dc
