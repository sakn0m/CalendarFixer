# CalendarFixer

CalendarFixer is a simple macOS tool to fix timezones in ICS calendar files and filter out unwanted courses. It's designed to ensure your calendar events are always in the correct timezone, regardless of where they were originally created, and to help you manage your schedule more effectively.

## Features

- **Cross-Platform**:
    - **macOS**: Native Universal App (Apple Silicon + Intel).
    - **Windows**: Native executable (`.exe`).
- **Timezone Fix**: Forces events to `Europe/Brussels` (configurable in code) to prevent timezone shifts.
- **Event Filtering**: Allows you to specify keywords (e.g., course names) to keep. All other events are removed. *If no keywords are provided, all events are kept.*
- **Persistent Settings**: Remembers your filter keywords between launches.
- **Privacy First**: Runs entirely locally on your machine. No data is sent to any server.

## Installation

### macOS
1.  Go to the [Releases](../../releases) page.
2.  Download `CalendarFixer_macOS.zip`.
3.  Unzip the file.
4.  Drag `CalendarFixer.app` to your `Applications` folder.

### Windows
1.  Go to the [Releases](../../releases) page.
2.  Download `CalendarFixer_Windows.exe`.
3.  Run the executable directly.

## Usage

### macOS
1.  Open **CalendarFixer** from your Applications folder.
    - *Note*: You may see a warning about an "Unidentified Developer". Right-click the app and select **Open** to bypass this.
2.  Enter the names of the courses/events you want to keep.
3.  Click **Select .ics File**.

### Windows
1.  Run `CalendarFixer_Windows.exe`.
2.  A window will appear allowing you to select the file.
3.  Choose your `.ics` calendar file.
4.  Success! The app will create a new file ending in `_filtered.ics` in the same folder as the original.
