# Boop

Hey there! Thanks for trying out Boop. This documentation should hopefully help you understand how it works, how you can extend it, and how you can contribute back.

## Child Pages

 - [Custom Scripts](CustomScripts.md)
 - [Modules](Modules.md)
 - [Debugging Scripts](Debugging.md)
 - [Converting Node Modules](ConvertingNodeModules.md)

## Getting Boop

You can download Boop from the Mac App Store, or from the [Releases page on GitHub](https://github.com/IvanMathy/Boop/releases). If you'd like to roll your own, you can clone the repository and follow the build instructions in the README.

## Using Boop

Boop is pretty easy to use: Open it, paste some text, run some scripts, optionally copy the text out.

To run scripts, simply open the script picker by pressing `⌘B` or in the top menu under `Scripts > Open Picker`. 

From the script picker, start typing to search for a script. You can then press `Enter ⏎` to pick the first script, or use the arrow keys to select another one. 

You can run the last script again by pressing `⇧⌘B` or from the option in the scripts menu.

To start over, you can clear the editor by pressing `⌘N`.

If a script messed up your text, you can undo it with `⌥⌘Z`. To redo an undone script, use `⇧⌥⌘Z`.
You can clear the script history with `⌥⌘K` and change how many undo steps are kept in the Scripts preferences.

If you are developing scripts, you can reload all the script by pressing `⇧⌘R` or  from the script menu as well.

You can also manage scripts without leaving the app. Choose **Scripts → New Script** to insert a template, **Open Script…** to load an existing file, then **Save Script** or **Save Script As…** to store your changes. Use **Delete Script…** to remove a script you no longer need. The script list reloads automatically after saving or deleting.

## Questions

### Can I see a list of all scripts?

Yes! Simply open the script picker and search for `*`.

### Why can't I open/Save a file?

Because that's not the goal of Boop. It's not really an editor, more of an unstructured limbo for your plain text pasted content.

### Where can I find more scripts?

You can find more functions in the [Boop Script Repository](https://github.com/IvanMathy/Boop/tree/main/Scripts). It contains scripts suggested by the community that are not in the built-in script library. You can go there to find new functionality, or suggest your own! 

### Can I make my own scripts?

Yes! Simply follow the instruction in the [Custom Scripts page](CustomScripts.md) to know how to get started.
Scripts can also be written in Python, Ruby, Perl, Lua and Node.js via small bridge programs that expose the same API used in JavaScript. These interpreters exchange data through JSON in the `BOOP_STATE` environment variable.
Modules can be imported with a special require function (default `boop_require`) in Python, Ruby, Perl and Lua. You can set a global or per-runtime keyword in the Runtime preferences. Node.js and JavaScript still use `require`.

### Can scripts make network requests?

Yes, but only if they declare the `network` permission in their metadata. When
allowed, a script can call `state.fetch(url, method, body)` to synchronously download data or POST payloads.

### Does Boop collect data on me?

No. The only time Boop communicates outside of itself is to check whether a new version is available. This is done by fetching a static .json file, with no additional data passed along. If you downloaded Boop through the Mac App Store, it's possible that standard data and/or crash reports get sent back to Apple and shared with me if you enabled App Analytics sharing, though I have not seen that happen yet.

### How can I report a problem?

The best way to do that is to [file an issue on GitHub](https://github.com/IvanMathy/Boop/issues/new). Otherwise, you can [talk to me on Twitter](https://twitter.com/OKatBest), as long as you're nice.

### How is Boop built?

Boop is mostly built using a custom fork of [SavannaKit](https://github.com/IvanMathy/savannakit), originally created by [Louis D'hauwe](http://twitter.com/LouisDhauwe). The search is powered by a custom fork of [Fuse-swift](https://github.com/IvanMathy/fuse-swift). The rest of Boop is simply built in Swift, besides scripts which are primarily JavaScript (but Python, Ruby, Perl, Lua and Node.js are supported too). Go ahead and open some of them to check their license!

### Do I have to say "Boop" out loud when I press ⌘+B?

Yes.
