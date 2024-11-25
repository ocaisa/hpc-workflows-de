---
title: Platzhalter
teaching: 40
exercises: 30
---


::: questions

- "Wie kann ich eine generische Regel erstellen?"

:::

::: objectives

- "Sehen Sie, wie Snakemake mit einigen Fehlern umgeht"

:::

Unser Snakefile hat einige Duplikate. Zum Beispiel werden die Namen von Textdateien an
einigen Stellen in den Snakefile-Regeln wiederholt. Snakefiles sind eine Form von Code,
und in jedem Code können Wiederholungen zu Problemen führen (z.B. wenn wir eine
Datendatei in einem Teil des Snakefiles umbenennen, aber vergessen, sie an anderer
Stelle umzubenennen).

::: callout

## D.R.Y. (Don't Repeat Yourself)

In vielen Programmiersprachen ist der Großteil der Sprachfunktionen dazu da, dem
Programmierer die Möglichkeit zu geben, langatmige Berechnungsroutinen als kurzen,
ausdrucksstarken und schönen Code zu beschreiben. Funktionen in Python, R oder Java, wie
z. B. benutzerdefinierte Variablen und Funktionen, sind zum Teil deshalb nützlich, weil
sie bedeuten, dass wir nicht alle Details immer und immer wieder ausschreiben (oder
darüber nachdenken) müssen. Diese gute Angewohnheit, Dinge nur einmal auszuschreiben,
ist bekannt als das "Don't Repeat Yourself"-Prinzip oder D.R.Y.

:::

Machen wir uns daran, einige der Wiederholungen aus unserem Snakefile zu entfernen.

## Platzhalter

Um eine allgemeinere Regel zu erstellen, brauchen wir **Platzhalter**. Schauen wir uns
mal an, wie ein Platzhalter aussieht

```python
rule hostname_remote:
    output: "hostname_remote.txt"
    input:
    shell:
        "hostname > {output}"

```

Zur Erinnerung, hier ist die vorherige Version aus der letzten Folge:

```python
rule hostname_remote:
    output: "hostname_remote.txt"
    input:
    shell:
        "hostname > hostname_remote.txt"

```

Die neue Regel hat explizite Dateinamen durch Dinge in `{curly brackets}` ersetzt,
speziell `{output}` (aber es hätte auch `{input}` sein können...wenn das einen Wert
hätte und nützlich wäre).

### `{input}` und `{output}` sind **Platzhalter**

Platzhalter werden im Abschnitt `shell` einer Regel verwendet, und Snakemake ersetzt sie
durch entsprechende Werte - `{input}` durch den vollständigen Namen der Eingabedatei und
`{output}` durch den vollständigen Namen der Ausgabedatei -- bevor der Befehl ausgeführt
wird.

`{resources}` ist auch ein Platzhalter, und wir können auf ein benanntes Element des
`{resources}` mit der Notation `{resources.runtime}` zugreifen (zum Beispiel).

:::keypoints

- "Snakemake-Regeln werden mit Platzhaltern generischer gestaltet"
- "Platzhalter im Shell-Teil der Regel werden durch Werte ersetzt, die auf den gewählten
  Platzhaltern basieren"

:::


