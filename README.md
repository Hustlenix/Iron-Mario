# ONLYEDUCATION

This is my idea in play for a nostalgic gaming platform.

I want to bring back the games we used to play on sites like Friv, Miniclip and Poki, but with my own little pixel games. You open the website, pick something and play. Thats the idea.

This used to be **Iron-Mario**. I changed the name because OnlyEducation felt better for what I wanted to build.

My project: [Iron-Mario on GitHub](https://github.com/Hustlenix/Iron-Mario).
My idea in play: [OnlyEducation](https://hustlenix.github.io/Iron-Mario/arcade/).

![Dino Dash](onlyeducation/arcade/art/dino-dash-card.png)

## Play

I published it on GitHub Pages, and am using GitHub for version control.

**[Play](https://hustlenix.github.io/Iron-Mario/arcade/)** · **[Original Godot game](https://hustlenix.github.io/Iron-Mario/legacy.html)**

The website currently has **14 games**. This branch has the **20-game beta**, which still needs actual player feedback before I publish it.

And yes, there is a dino game set **67 million years ago**.

## Verified status

I tested it, but I still need people to actually play it and tell me what feels wrong.

The beta passed **179 rule/engine tests, 100 browser checks and 23 platform checks**. That does not mean 100 people played it🤣.

See: [verification evidence and what still needs testing](docs/arcade/TWENTY_GAME_BETA.md).

## The plan

I asked for way too many games at once before giving them enough attention. That was actually a bad idea.

Now I want to improve them one by one. Better controls, better pixel art, and games you would actually come back to play.

The old 105-game Godot collection is still here. The new browser arcade is a separate collection, so dont confuse those numbers.

## Art and licenses

I use Aseprite for the shared pixel art, and the browser games also use original Canvas drawings. The thumbnails show the actual games.

I have packs like **Modern Interiors by LimeZu** for the wider project too. The raw paid packs are not included in this browser arcade.

Asset sources and licenses: [here](docs/arcade/ASSETS.md).

## Architecture

I started this in **Godot**. The newer browser arcade uses **HTML, CSS and JavaScript Canvas**.

The game files are in `onlyeducation/arcade/games/`. The shared engine handles controls, sound, pause and restart.

If you want the original Godot project, open `project.godot` in Godot 4.7.1 with the Compatibility renderer.

## Run it

**Dependencies**

1. Node.js
2. Python
3. Godot 4.7.1, if you are working on the original game

**Commands**

```sh
node --test tests/arcade/*.test.mjs
python tools/package_arcade.py
python -m http.server 8785 --bind 127.0.0.1 --directory build/web
```

Open **http://127.0.0.1:8785/arcade/**. Keep the terminal running, or the preview stops working.

The release steps are in [DEPLOYMENT.md](docs/arcade/DEPLOYMENT.md). Pushing this branch does not publish the website by itself.

Try the games,
tell me the annoying parts,
and **DONT JUST LOOK AT THE THUMBNAILS, ACTUALLY PLAY THEM!**

I am gonna keep building this, man✌🏻
