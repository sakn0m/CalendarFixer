import tkinter as tk
from tkinter import filedialog, messagebox
from ics import Calendar

def filter_calendar():
    """
    Apre un file .ics, forza il fuso orario 'Europe/Brussels' su ogni evento
    per prevenire conversioni errate, filtra gli eventi non desiderati
    e salva una copia modificata.
    """
    root = tk.Tk()
    root.withdraw()

    try:
        file_path = filedialog.askopenfilename(
            title="Seleziona il file del calendario (.ics)",
            filetypes=(("File iCalendar", "*.ics"), ("Tutti i file", "*.*"))
        )

        if not file_path:
            return

        with open(file_path, 'r', encoding='utf-8') as f:
            calendar = Calendar(f.read())

        # Elenco dei corsi da mantenere
        # Elenco dei corsi da mantenere
        courses_to_keep = []
        
        # Fuso orario da forzare su ogni evento
        TARGET_TZ = "Europe/Brussels"

        # Iteriamo su ogni evento e gli riassegnamo il fuso orario corretto.
        # Il metodo .replace(tzinfo=...) cambia il fuso orario di un evento
        # SENZA cambiare l'orario (es. le 10:30 rimangono 10:30, ma vengono etichettate
        # come orario di Bruxelles, non più UTC o altro).
        
        events_processed_and_filtered = []
        kept_count = 0
        total_count = len(calendar.events)

        for event in calendar.events:
            # Forziamo il fuso orario corretto
            event.begin = event.begin.replace(tzinfo=TARGET_TZ)
            event.end = event.end.replace(tzinfo=TARGET_TZ)
            
            # Ora che l'evento ha il fuso orario giusto, controlliamo se va tenuto
            # Case insensitive check
            event_name_lower = event.name.lower() if event.name else ""
            if any(course.lower() in event_name_lower for course in courses_to_keep):
                events_processed_and_filtered.append(event)
                kept_count += 1
        
        # Sostituiamo la vecchia lista di eventi con la nostra nuova lista
        # che contiene solo gli eventi filtrati e con il fuso orario corretto.
        calendar.events = set(events_processed_and_filtered)

        output_path = file_path.replace(".ics", "_filtered.ics")
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.writelines(calendar)
        
        messagebox.showinfo(
            "Successo",
            f"Calendario filtrato creato con successo!\n\n"
            f"Eventi totali trovati: {total_count}\n"
            f"Eventi mantenuti: {kept_count}\n\n"
            f"Il file è stato salvato come:\n{output_path}"
        )

    except Exception as e:
        messagebox.showerror(
            "Errore",
            f"Si è verificato un errore durante l'elaborazione del file:\n\n{e}"
        )

if __name__ == "__main__":
    filter_calendar()
