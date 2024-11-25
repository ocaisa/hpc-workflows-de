---
title: Ausführen von Befehlen mit Snakemake
teaching: 30
exercises: 30
---


::: questions

- "Wie führe ich einen einfachen Befehl mit Snakemake aus?"

:::

:::objectives

- "Erstelle ein Snakemake-Rezept (eine Snake-Datei)"

:::

## Für welchen Arbeitsablauf interessiere ich mich?

In dieser Lektion werden wir ein Experiment durchführen, bei dem wir eine parallel
laufende Anwendung auf ihre Skalierbarkeit hin untersuchen. Dazu müssen wir Daten
sammeln. In diesem Fall bedeutet das, dass wir die Anwendung mehrmals mit einer
unterschiedlichen Anzahl von CPU-Kernen ausführen und die Ausführungszeit aufzeichnen.
Danach müssen wir eine Visualisierung der Daten erstellen, um zu sehen, wie sie sich im
Vergleich zum Idealfall verhalten.

Anhand der Visualisierung können wir dann entscheiden, in welchem Maßstab es am
sinnvollsten ist, die Anwendung in der Produktion laufen zu lassen, um die CPU-Zuweisung
auf dem System optimal zu nutzen.

Wir könnten all dies manuell tun, aber es gibt nützliche Tools, die uns bei der
Verwaltung von Datenanalyse-Pipelines, wie wir sie in unserem Experiment haben, helfen.
Heute werden wir eines dieser Tools kennenlernen: Snakemake.

Um mit Snakemake zu beginnen, nehmen wir zunächst einen einfachen Befehl und sehen, wie
wir ihn mit Snakemake ausführen können. Wählen wir den Befehl `hostname`, der den Namen
des Rechners ausgibt, auf dem der Befehl ausgeführt wird:

```bash
[ocaisa@node1 ~]$ hostname
```

```output
node1.int.jetstream2.hpc-carpentry.org
```

Das gibt das Ergebnis aus, aber Snakemake ist auf Dateien angewiesen, um den Status
Ihres Arbeitsablaufs zu kennen, also leiten wir die Ausgabe in eine Datei um:

```bash
[ocaisa@node1 ~]$ hostname > hostname_login.txt
```

## Erstellen einer Snake-Datei

Bearbeiten Sie eine neue Textdatei mit dem Namen `Snakefile`.

Inhalt von `Snakefile`:

```python
rule hostname_login:
    output: "hostname_login.txt"
    input:  
    shell:
        "hostname > hostname_login.txt"
```

::: callout

## Wichtige Punkte zu dieser Datei

1. Die Datei heißt `Snakefile` - mit einem großen `S` und ohne Dateierweiterung.
1. Einige Zeilen sind eingerückt. Einrückungen müssen mit Leerzeichen, nicht mit
   Tabulatoren erfolgen. Wie Sie Ihren Texteditor dazu bringen, dies zu tun, erfahren
   Sie im Abschnitt "Setup".
1. Die Regeldefinition beginnt mit dem Schlüsselwort `rule`, gefolgt von dem Namen der
   Regel und einem Doppelpunkt.
1. Wir haben die Regel `hostname_login` genannt. Sie können Buchstaben, Zahlen oder
   Unterstriche verwenden, aber der Name der Regel muss mit einem Buchstaben beginnen
   und darf kein Schlüsselwort sein.
1. Die Schlüsselwörter `input`, `output` und `shell` werden alle von einem Doppelpunkt
   (":") gefolgt.
1. Die Dateinamen und der Shell-Befehl sind alle in `"quotes"`.
1. Der Name der Ausgabedatei wird vor dem Namen der Eingabedatei angegeben. Eigentlich
   ist es Snakemake egal, in welcher Reihenfolge sie erscheinen, aber wir geben in
   diesem Kurs die Ausgabe zuerst an. Wir werden gleich sehen, warum.
1. In diesem Anwendungsfall gibt es keine Eingabedatei für den Befehl, also lassen wir
   dieses Feld leer.

:::

Zurück in der Shell werden wir unsere neue Regel ausführen. An diesem Punkt, wenn es
irgendwelche fehlenden Anführungszeichen, falsche Einrückungen, etc. gab, werden wir
einen Fehler sehen.

```bash
snakemake -j1 -p hostname_login
```

::: callout

## `bash: snakemake: command not found...`

Wenn Ihre Shell Ihnen mitteilt, dass sie den Befehl `snakemake` nicht finden kann,
müssen wir die Software irgendwie verfügbar machen. In unserem Fall bedeutet das, dass
wir nach dem Modul suchen müssen, das wir laden wollen:

```bash
module spider snakemake
```

```output
[ocaisa@node1 ~]$ module spider snakemake

--------------------------------------------------------------------------------------------------------
  snakemake:
--------------------------------------------------------------------------------------------------------
     Versions:
        snakemake/8.2.1-foss-2023a
        snakemake/8.2.1 (E)

Names marked by a trailing (E) are extensions provided by another module.


--------------------------------------------------------------------------------------------------------
  For detailed information about a specific "snakemake" package (including how to load the modules) use the module's full name.
  Note that names that have a trailing (E) are extensions provided by other modules.
  For example:

     $ module spider snakemake/8.2.1
--------------------------------------------------------------------------------------------------------
```

Jetzt wollen wir das Modul, also laden wir es, um das Paket verfügbar zu machen

```bash
[ocaisa@node1 ~]$ module load snakemake
```

und dann stellen Sie sicher, dass der Befehl `snakemake` verfügbar ist

```bash
[ocaisa@node1 ~]$ which snakemake
```

```output
/cvmfs/software.eessi.io/host_injections/2023.06/software/linux/x86_64/amd/zen3/software/snakemake/8.2.1-foss-2023a/bin/snakemake
```

```bash
snakemake -j1 -p hostname_login
```

:::

::: challenge

## Ausführen von Snakemake

Führen Sie `snakemake --help | less` aus, um die Hilfe für alle verfügbaren Optionen zu
sehen. Was bewirkt die Option `-p` in dem obigen Befehl `snakemake`?

1. Schützt bestehende Ausgabedateien
1. Gibt die Shell-Befehle, die gerade ausgeführt werden, auf dem Terminal aus
1. Sagt Snakemake, dass es nur einen Prozess auf einmal ausführen soll
1. Fordert den Benutzer auf, die richtige Eingabedatei zu wählen

:::::: hint

Sie können im Text suchen, indem Sie <kbd>/</kbd> drücken, und mit <kbd>q</kbd> zur
Shell zurückkehren.

::::::

:::::: solution

(2) Gibt die Shell-Befehle, die gerade ausgeführt werden, auf dem Terminal aus

Dies ist so nützlich, dass wir nicht wissen, warum es nicht die Standardeinstellung ist!
Die Option `-j1` sagt Snakemake, dass es immer nur einen Prozess auf einmal ausführen
soll, und wir bleiben vorerst dabei, da es die Dinge einfacher macht. Antwort 4 ist ein
totales Ablenkungsmanöver, da Snakemake niemals interaktiv nach Benutzereingaben fragt.

::::::


:::

::: keypoints

- "Bevor Sie Snakemake starten, müssen Sie ein Snakefile schreiben"
- "Ein Snakefile ist eine Textdatei, die eine Liste von Regeln definiert"
- "Regeln haben Eingänge, Ausgänge und Shell-Befehle, die ausgeführt werden sollen"
- "Du sagst Snakemake, welche Datei es erstellen soll, und es wird den in der
  entsprechenden Regel definierten Shell-Befehl ausführen"

:::


