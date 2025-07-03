# Suggested Improvements for Boop

This document collects ideas for making Boop better. Items are grouped by how easy they might be to implement and their potential impact.

### Categories
Every enhancement is labeled with one or more categories so that related ideas are easy to find. The current labels are:

- **UI** – changes to Boop's interface or user interactions
- **Editor** – editing or text manipulation features
- **Script Management** – improvements to managing or running scripts
- **Developer Tools** – features that help script authors
- **Community** – sharing or collaborative features

## Quick Wins
These are relatively small changes that should have a noticeable positive effect:

- **Favorites in Script Picker** _(UI, Script Management)_: Mark scripts as favorites so they appear at the top of search results.
- **Categorized Script List** _(UI, Script Management)_: Basic grouping of scripts by category in the picker. Each script can belong to multiple categories.
- **Shortcut Customization** _(UI)_: Allow users to assign hotkeys to frequently used scripts.
- **One‑Click Script Reload** _(Script Management)_: Add a button or menu option to reload scripts without a shortcut.
- **Improved Error Messages** _(Developer Tools)_: Include the script name and line number when a script fails.
- **History Stack** _(Editor)_ ✔: Revert scripts with `Undo Last Script` (`⌥⌘Z`).
- **Clearable History** _(Editor)_ ✔: Option to clear script history and set the
  maximum number of undo steps.
- **Script Template Generator** _(Developer Tools)_ ✔: Scaffold a new script from a built-in template.
- **In‑App Script Editing** _(Script Management)_ ✔: Create, update, and delete scripts right inside Boop.

## Medium Effort
Require a bit more work but still relatively contained:

- **Automatic Script Updates** _(Script Management)_: Check an official repository for script updates and install them on demand.
- **Theme Import/Export** _(UI)_: Let users share color themes via files.
- **Preview Before Apply** _(UI, Editor)_: Show the result of a script in a separate pane before replacing the text.
- **Inline Documentation** _(UI, Developer Tools)_: Display a short explanation or link to docs when hovering over a script in the picker.

## Bigger Projects
These would have high impact but may take longer to design and implement:

- **Plugin System for Extensions** _(Developer Tools, Editor)_: Allow third‑party Swift/JS plugins to extend the editor beyond scripts.
- **Collaborative Script Library** _(Community, Script Management)_: Integrate directly with a Git repository to share and rate community scripts.
- **Multi Cursor Editing** _(Editor)_ *(already in progress)*: Support simultaneous cursors for faster editing.
- **Split Script Repository** _(Script Management, Community)_ *(planned)*: Move built‑in scripts to a separate repo for easier contributions.

This list can serve as a starting point for prioritizing future work.
