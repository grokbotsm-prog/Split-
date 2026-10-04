# Split

Split a restaurant check in a phone or desktop browser.

Enter the bill, a tip percent, and how many people. The page shows what each person pays, the tip, and the total. Amounts are calculated in cents, so the shares add up to the total. When the total does not divide evenly, some people pay one cent more. Nothing is left over.

There is no account, no payment, and no ad. The page does not send what you type anywhere. It is three files — `index.html`, `styles.css`, and `app.js` — and there is no build step.

## Open it on this computer

1. Clone or download this repository.
2. Open `index.html` in Chrome, Safari, Firefox, or Edge. Double-click the file, or use File → Open in the browser.
3. Leave `styles.css` and `app.js` in the same folder as `index.html`.

The file works with no internet connection. You do not need a server.

## Put it on the web with GitHub Pages

This repository is public, so GitHub can host the page for free from the `main` branch.

1. Push the project to the `main` branch of [github.com/grokbotsm-prog/Split-](https://github.com/grokbotsm-prog/Split-).
2. On GitHub, open the repository and go to **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to **Deploy from a branch**.
4. Set **Branch** to `main` and the folder to **/ (root)**.
5. Click **Save**.

Leave the `.nojekyll` file where it is. It tells GitHub to serve the page as plain files.

Wait a minute or two. GitHub shows the site address on that Pages screen when the first deploy finishes. The public link is:

**https://grokbotsm-prog.github.io/Split-/**

Open that link on a phone at the table. The page itself still does not talk to a server; the internet is only used to load it. If you rename the repository, the link changes to match the new name. If the repository is made private, this free Pages site stops.
