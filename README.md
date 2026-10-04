# Split

Split a restaurant check in a phone or desktop browser.

Enter the bill, a tip percent, and how many people. The page shows what each person pays, the tip, and the total. Amounts are calculated in cents, so the shares add up to the total. When the total does not divide evenly, some people pay one cent more. Nothing is left over.

There is no account, no payment, and no ad. The page does not send what you type anywhere. Everything is in `index.html`. There is no build step.

## Open it

Open this link in Chrome, Safari, Firefox, or Edge:

**https://htmlpreview.github.io/?https://raw.githubusercontent.com/grokbotsm-prog/Split-/main/index.html**

That response is `text/html`. The styles and the calculator are inside `index.html`, so the splitter shows up as a page, not as source code.

From a copy of this repository, double-click `index.html`, or use File → Open in the browser. That works with no internet connection.

`https://grokbotsm-prog.github.io/Split-/` is not published. GitHub Pages is off for this repo, and the available GitHub access cannot turn it on. Raw GitHub and jsDelivr send `index.html` as `text/plain` with nosniff, so those links show the source instead of the app.

## iPhone app

The native app is `ios/Split.xcodeproj`. The name on the home screen is Split. It does the same job as the web page: the bill, tip presets of 15, 18, 20, and 25 or a typed percent, how many people, each person's share, the tip, and the total. Shares are figured in cents and add up to the total. It has no account, no network, no ads, and no tracking. It collects no data.

You need a Mac with Xcode and your Apple Developer account. Open the project, pick your team, then archive and upload.

1. On a Mac, open `ios/Split.xcodeproj` in Xcode.
2. In the sidebar, select the Split project, then the Split target, then **Signing & Capabilities**.
3. Turn on **Automatically manage signing**.
4. Choose your team under **Team**.
5. If Xcode says the bundle identifier is already in use, change **Bundle Identifier** to one you own, such as `com.yourname.Split`.
6. In the toolbar, set the destination to **Any iOS Device (arm64)**. A simulator cannot be archived.
7. Choose **Product → Archive**.
8. When the Organizer opens, click **Distribute App**, then **App Store Connect**, then **Upload**. After the build finishes processing, add it to the version you send for review.

The project already answers the export question: the app does not use non-exempt encryption. If App Store Connect still asks, say that it does not.

In App Store Connect, under App Privacy, say that you do not collect data and do not track users. The privacy manifest in the app says the same.
