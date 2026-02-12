using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Collections.Generic;

namespace CalendarFixerWin
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.SetHighDpiMode(HighDpiMode.SystemAware);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class MainForm : Form
    {
        private TextBox keywordBox;
        private Button selectButton;
        private Label statusLabel;
        private Label instructionLabel;
        private const string SETTINGS_FILE = "settings.txt";

        public MainForm()
        {
            this.Text = "Calendar Fixer";
            this.Size = new Size(400, 300);
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;

            // Instructions
            instructionLabel = new Label();
            instructionLabel.Text = "Courses to keep (comma separated):";
            instructionLabel.Location = new Point(20, 20);
            instructionLabel.AutoSize = true;
            this.Controls.Add(instructionLabel);

            // Keyword Text Box
            keywordBox = new TextBox();
            keywordBox.Location = new Point(20, 45);
            keywordBox.Size = new Size(340, 25);
            
            // Load settings
            try
            {
                if (File.Exists(SETTINGS_FILE))
                {
                    keywordBox.Text = File.ReadAllText(SETTINGS_FILE);
                }
            }
            catch { /* Ignore */ }

            this.Controls.Add(keywordBox);

            // Select File Button
            selectButton = new Button();
            selectButton.Text = "Select .ics File";
            selectButton.Location = new Point(20, 90);
            selectButton.Size = new Size(150, 40);
            selectButton.Click += SelectButton_Click;
            this.Controls.Add(selectButton);

            // Status
            statusLabel = new Label();
            statusLabel.Text = "Ready.";
            statusLabel.Location = new Point(20, 150);
            statusLabel.AutoSize = true;
            this.Controls.Add(statusLabel);
        }

        private void SelectButton_Click(object? sender, EventArgs e)
        {
            // Save settings
            try
            {
                File.WriteAllText(SETTINGS_FILE, keywordBox.Text);
            }
            catch { /* Ignore save errors */ }

            using (OpenFileDialog openFileDialog = new OpenFileDialog())
            {
                openFileDialog.Filter = "iCalendar files|*.ics|All files|*.*";
                openFileDialog.Title = "Select .ics File";

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    ProcessFile(openFileDialog.FileName);
                }
            }
        }

        private void ProcessFile(string filePath)
        {
            statusLabel.Text = "Processing...";
            Application.DoEvents();

            try
            {
                string content = File.ReadAllText(filePath);
                string keywordsRaw = keywordBox.Text;
                
                string[] keywords = keywordsRaw.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(k => k.Trim().ToLower())
                    .Where(k => !string.IsNullOrEmpty(k))
                    .ToArray();
                
                bool keepAll = keywords.Length == 0;

                // Simple parser logic (matches Swift/Python implementation)
                List<string> outputLines = new List<string>();
                
                // Unfold lines first
                string unfolded = content.Replace("\r\n ", "").Replace("\n ", ""); 
                string[] lines = unfolded.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);

                bool inEvent = false;
                List<string> currentEventLines = new List<string>();
                int total = 0;
                int kept = 0;

                foreach (string line in lines)
                {
                    if (line.StartsWith("BEGIN:VEVENT"))
                    {
                        inEvent = true;
                        currentEventLines.Clear();
                        currentEventLines.Add(line);
                        continue;
                    }

                    if (inEvent)
                    {
                        currentEventLines.Add(line);
                        if (line.StartsWith("END:VEVENT"))
                        {
                            total++;
                            var processedEvent = ProcessEvent(currentEventLines, keywords, keepAll);
                            if (processedEvent != null)
                            {
                                outputLines.AddRange(processedEvent);
                                kept++;
                            }
                            inEvent = false;
                            currentEventLines.Clear();
                        }
                        continue;
                    }

                    // Non-event lines
                    outputLines.Add(line);
                }

                string outputPath = Path.ChangeExtension(filePath, "_filtered.ics");
                File.WriteAllLines(outputPath, outputLines);

                statusLabel.Text = $"Done! Kept {kept}/{total} events.";
                statusLabel.ForeColor = Color.Green;
                
                MessageBox.Show($"Success!\nFile saved to:\n{outputPath}\n\nKept {kept} of {total} events.", "Calendar Fixer", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                statusLabel.Text = "Error: " + ex.Message;
                statusLabel.ForeColor = Color.Red;
                MessageBox.Show("Error processing file: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private List<string>? ProcessEvent(List<string> eventLines, string[] keywords, bool keepAll)
        {
            // Filter check
            if (!keepAll)
            {
                bool match = false;
                foreach (var line in eventLines)
                {
                    if (line.StartsWith("SUMMARY") || line.StartsWith("summary")) // Case insensitive check
                    {
                        string lowerLine = line.ToLower();
                        if (keywords.Any(k => lowerLine.Contains(k)))
                        {
                            match = true;
                            break;
                        }
                    }
                }
                
                if (!match) return null;
            }

            // Timezone fix
            List<string> newLines = new List<string>();
            string targetTZ = "Europe/Brussels";

            foreach (var line in eventLines)
            {
                string newLine = line;

                bool isDateTime = line.StartsWith("DTSTART") || line.StartsWith("DTEND");
                if (isDateTime)
                {
                    // Format: KEY;PARAM=VAL:VALUE
                    // We want to force TZID=...
                    
                    int colonIndex = line.IndexOf(':');
                    if (colonIndex > 0)
                    {
                        string keyPart = line.Substring(0, colonIndex);
                        string valuePart = line.Substring(colonIndex + 1);

                        // Only process if it looks like a datetime (has T)
                        if (valuePart.Contains("T"))
                        {
                            if (valuePart.EndsWith("Z"))
                            {
                                valuePart = valuePart.Substring(0, valuePart.Length - 1);
                            }

                            string baseProp = keyPart.Contains(";") ? keyPart.Split(';')[0] : keyPart;
                            newLine = $"{baseProp};TZID={targetTZ}:{valuePart}";
                        }
                    }
                }
                newLines.Add(newLine);
            }

            return newLines;
        }
    }
}
