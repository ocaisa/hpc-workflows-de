---
title: Verarbeitung von Listen von Eingaben
teaching: 50
exercises: 30
---


::: questions

- "Wie kann ich mehrere Dateien auf einmal verarbeiten?"
- "Wie kombiniere ich mehrere Dateien miteinander?"

:::

::: objectives

- "Verwenden Sie Snakemake, um alle unsere Proben auf einmal zu verarbeiten"
- "Erstellen Sie ein Skalierbarkeitsdiagramm, das unsere Ergebnisse zusammenfasst"

:::

Wir haben eine Regel erstellt, die eine einzige Ausgabedatei erzeugen kann, aber wir
werden nicht mehrere Regeln für jede Ausgabedatei erstellen. Wir wollen alle
Ausführungsdateien mit einer einzigen Regel erzeugen, wenn es möglich ist, und Snakemake
kann tatsächlich eine Liste von Eingabedateien annehmen:

```python
rule generate_run_files:
    output: "p_{parallel_proportion}_runs.txt"
    input:  "p_{parallel_proportion}/runs/amdahl_run_2.json", "p_{parallel_proportion}/runs/amdahl_run_6.json"
    shell:
        "echo {input} done > {output}"
```

Das ist großartig, aber wir wollen nicht alle Dateien, an denen wir interessiert sind,
einzeln auflisten müssen. Wie können wir dies tun?

## Definieren einer Liste von zu verarbeitenden Proben

Um dies zu tun, können wir einige Listen als Snakemake **globale Variablen** definieren.

Globale Variablen sollten vor den Regeln in der Snakefile hinzugefügt werden.

```python
# Task sizes we wish to run
NTASK_SIZES = [1, 2, 3, 4, 5]
```

- Anders als bei Variablen in Shell-Skripten können wir Leerzeichen um das `=`-Zeichen
  setzen, aber sie sind nicht zwingend erforderlich.
- Die Listen der in Anführungszeichen gesetzten Zeichenketten werden in eckige Klammern
  gesetzt und durch Kommata getrennt. Wenn Sie Python kennen, werden Sie dies als
  Python-Listensyntax erkennen.
- Eine gute Konvention ist die Verwendung von großgeschriebenen Namen für diese
  Variablen, aber das ist nicht zwingend.
- Obwohl diese als Variablen bezeichnet werden, können Sie die Werte nicht mehr ändern,
  sobald der Arbeitsablauf läuft, so dass auf diese Weise definierte Listen eher
  Konstanten sind.

## Verwendung einer Snakemake-Regel zur Definition eines Stapels von Ausgaben

Nun wollen wir unser Snakefile aktualisieren, um die neue globale Variable zu nutzen und
eine Liste von Dateien zu erstellen:

```python
rule generate_run_files:
    output: "p_{parallel_proportion}_runs.txt"
    input:  expand("p_{{parallel_proportion}}/runs/amdahl_run_{count}.json", count=NTASK_SIZES)
    shell:
        "echo {input} done > {output}"
```

Die Funktion `expand(...)` in dieser Regel erzeugt eine Liste von Dateinamen, indem sie
das erste Element in den einfachen Klammern als Vorlage nimmt und `{count}` durch alle
`NTASK_SIZES` ersetzt. Da die Liste 5 Elemente enthält, ergibt dies 5 Dateien, die wir
erstellen wollen. Beachten Sie, dass wir unseren Platzhalter in einem zweiten Satz von
Klammern schützen mussten, damit er nicht als etwas interpretiert wird, das erweitert
werden muss.

In unserem aktuellen Fall verlassen wir uns immer noch auf den Dateinamen, um den Wert
des Platzhalters `parallel_proportion` zu definieren, also können wir die Regel nicht
direkt aufrufen, sondern müssen immer noch eine bestimmte Datei anfordern:

```bash
snakemake --profile cluster_profile/ p_0.999_runs.txt
```

Wenn Sie beim Ausführen von Snakemake auf der Befehlszeile keinen Namen für eine
Zielregel oder Dateinamen angeben, wird standardmäßig **die erste Regel** in der
Snake-Datei als Ziel verwendet.

::: callout

## Regeln als Ziele

Wenn Sie Snakemake den Namen einer Regel auf der Kommandozeile geben, funktioniert das
nur, wenn diese Regel *keine Platzhalter* in den Ausgaben hat, weil Snakemake keine
Möglichkeit hat, zu wissen, was die gewünschten Platzhalter sein könnten. Sie erhalten
die Fehlermeldung "Target rules may not contain wildcards" Dies kann auch passieren,
wenn Sie in der Befehlszeile keine expliziten Ziele angeben und Snakemake versucht, die
erste im Snakefile definierte Regel auszuführen.

:::

## Regeln, die mehrere Eingaben kombinieren

Unsere `generate_run_files` Regel ist eine Regel, die eine Liste von Eingabedateien
annimmt. Die Länge dieser Liste ist nicht durch die Regel festgelegt, sondern kann sich
je nach `NTASK_SIZES` ändern.

In unserem Arbeitsablauf besteht der letzte Schritt darin, alle erzeugten Dateien zu
einem Diagramm zusammenzufassen. Vielleicht haben Sie schon gehört, dass einige Leute
dafür eine Python-Bibliothek namens `matplotlib` verwenden. Es würde den Rahmen dieses
Tutorials sprengen, das Python-Skript zu schreiben, um einen endgültigen Plot zu
erstellen, daher stellen wir Ihnen das Skript als Teil dieser Lektion zur Verfügung. Sie
können es herunterladen mit

```bash
curl -O https://ocaisa.github.io/hpc-workflows/files/plot_terse_amdahl_results.py
```

Das Skript `plot_terse_amdahl_results.py` benötigt eine Befehlszeile, die wie folgt
aussieht:

```bash
python plot_terse_amdahl_results.py --output <output image filename> <1st input file> <2nd input file> ...
```

Lass uns das in unsere `generate_run_files` Regel einfügen:

```python
rule generate_run_files:
    output: "p_{parallel_proportion}_runs.txt"
    input:  expand("p_{{parallel_proportion}}/runs/amdahl_run_{count}.json", count=NTASK_SIZES)
    shell:
        "python plot_terse_amdahl_results.py --output {output} {input}"
```

::: challenge

Dieses Skript verlässt sich auf `matplotlib`, ist es als Umgebungsmodul verfügbar? Fügen
Sie diese Bedingung zu unserer Regel hinzu.

:::::: solution

```python
rule generate_run_files:
    output: "p_{parallel_proportion}_scalability.jpg"
    input:  expand("p_{{parallel_proportion}}/runs/amdahl_run_{count}.json", count=NTASK_SIZES)
    envmodules:
      "matplotlib"
    shell:
        "python plot_terse_amdahl_results.py --output {output} {input}"
```

::::::

:::

Jetzt können wir endlich ein Skalierungsdiagramm erstellen! Führen Sie den letzten
Snakemake-Befehl aus:

```bash
snakemake --profile cluster_profile/ p_0.999_scalability.jpg
```

::: challenge

Erzeugen Sie das Skalierbarkeitsdiagramm für alle Werte von 1 bis 10 Kernen.

:::::: solution

```python
NTASK_SIZES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

::::::

:::

::: challenge

Wiederholung des Arbeitsablaufs für einen `p`-Wert von 0,8

:::::: solution

```bash
snakemake --profile cluster_profile/ p_0.8_scalability.jpg
```

::::::

:::

::: challenge

## Bonusrunde

Erstellen Sie eine endgültige Regel, die direkt aufgerufen werden kann und ein
Skalierungsdiagramm für 3 verschiedene Werte von `p` erzeugt.

:::

::: keypoints

- "Verwenden Sie die Funktion `expand()`, um Listen von Dateinamen zu erzeugen, die Sie
  kombinieren wollen"
- "Jede `{input}` zu einer Regel kann eine Liste variabler Länge sein"

:::


