# CalendarFixer

CalendarFixer is a simple macOS tool to fix timezones in ICS calendar files and filter out unwanted courses. It's designed to ensure your calendar events are always in the correct timezone, regardless of where they were originally created, and to help you manage your schedule more effectively.

## Features

- **Universal Binary**: Runs natively on both Apple Silicon (M1/M2/M3) and Intel Macs.
- **Timezone Fix**: Forces events to `Europe/Brussels` (configurable in code) to prevent timezone shifts.
- **Event Filtering**: Allows you to specify keywords (e.g., course names) to keep. All other events are removed. *If no keywords are provided, all events are kept.*
- **Persistent Settings**: Remembers your filter keywords between launches.
- **Privacy First**: Runs entirely locally on your machine. No data is sent to any server.

## Installation

1.  Go to the [Releases](../../releases) page.
2.  Download `CalendarFixer.zip`.
3.  Unzip the file.
4.  Drag `CalendarFixer.app` to your `Applications` folder.

## Usage

1.  Open **CalendarFixer** from your Applications folder.
    - *Note*: You may see a warning about an "Unidentified Developer". Right-click the app and select **Open** to bypass this.
2.  Enter the names of the courses/events you want to keep in the text field, separated by commas (e.g., `Math, Physics, History`).
    - Leave it empty to keep *all* events and just fix the timezones.
3.  Click **Select .ics File**.
4.  Choose your `.ics` calendar file.
5.  Success! The app will create a new file ending in `_filtered.ics` in the same folder as the original.
