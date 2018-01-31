# Beeminder AppleScript Library

## Overview

Post data to Beeminder from any AppleScript in an elegant and reliable way!

*This is a small, 100% unofficial project not developed or maintained by the creators of Beeminder. I made it for myself and wanted to share it. I hope it makes Beeminding from AppleScript easy!*

## Setup

1. Download or clone this repository (or just Beeminder.applescript) anywhere.
2. Open Beeminder.applescript in Script Editor and run it once.
3. That's it!

## Usage

From any AppleScript:
  
    tell script "Beeminder" to enter_datapoint("writing", 25, "Spent 25 minutes writing!")

This will post 25 minutes (or whatever units your goal uses) to your `writing` goal with the comment "Spent 25 minutes writing!".

***Caution!*** For now, only use letters, numbers, spaces, and `,.!:;` (**NO backslashes, quotes of any variety, or line breaks**) in comments (e.g. "Spent 25 minutes writing!" in the example above) to avoid unexpected behavior.

The first time `enter_datapoint` is called, you will be prompted for your Beeminder username and auth token (available [here](https://www.beeminder.com/api/v1/auth_token.json)).

If data entry fails, you will be given the option to try again immediately (e.g. after checking internet connectivity) or to save the data for later. Data is saved on disk until it is successfully entered. Beeminder.applescript contains a special function to retry sending saved data:
	
	tell script "Beeminder" to resend_last_unentered_datapoint()

*(If your script says a Beeminder Update failed and you are connected to the internet and your credentials are correct, it is probably because of the characters in the comment. Click "Save Update For Later" then delete the last line of `/usr/local/etc/beeminder-applescript/unentered-data.txt` to resolve the issue.)*

## How It Works

All functions within Beeminder.applescript are documented—check them out!

Beeminder.applscript saves your Beeminder credentials and unentered data in `/usr/local/etc/beeminder-applescript/`, and compiles itself into `~/Library/Script Libraries` to make it accessible to any AppleScript in your user account. Beeminder.applescript does not modify anything outside these two directories.

If your Beeminder username or auth_token change or you enter them incorrectly, just delete `/usr/local/etc/beeminder-applescript/auth.txt` and call `enter_datapoint` again. (Or just edit auth.txt directly.)
