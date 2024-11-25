---
title: MPI-Anwendungen und Snakemake
teaching: 30
exercises: 20
---


::: objectives

- "Definiere Regeln, die lokal und im Cluster laufen sollen"

:::

::: questions

- "Wie kann ich eine MPI-Anwendung über Snakemake auf dem Cluster ausführen?"

:::

Jetzt ist es an der Zeit, sich wieder unserem eigentlichen Arbeitsablauf zuzuwenden. Wir
können einen Befehl auf dem Cluster ausführen, aber was ist mit der Ausführung der
MPI-Anwendung, an der wir interessiert sind? Unsere Anwendung heißt `amdahl` und ist als
Umgebungsmodul verfügbar.

::: challenge

Suchen und laden Sie das Modul `amdahl` und _ersetzen_ Sie dann unsere
`hostname_remote`-Regel durch eine Version, die `amdahl` ausführt. (Machen Sie sich noch
keine Gedanken über paralleles MPI, lassen Sie es mit einer einzelnen CPU laufen,
`mpiexec -n 1 amdahl`).

Wird Ihre Regel korrekt ausgeführt? Wenn nicht, sehen Sie sich die Protokolldateien an,
um herauszufinden, warum?

::::::solution

```bash
module spider amdahl
module load amdahl
```

findet das Modul `amdahl` und lädt es dann. Wir können dann unsere Regel
aktualisieren/ersetzen, um die Anwendung `amdahl` auszuführen:

```python
rule amdahl_run:
    output: "amdahl_run.txt"
    input:
    shell:
        "mpiexec -n 1 amdahl > {output}"
```

Wenn wir jedoch versuchen, die Regel auszuführen, erhalten wir eine Fehlermeldung (es
sei denn, Sie haben bereits eine andere Version von `amdahl` in Ihrem Pfad verfügbar).
Snakemake meldet den Speicherort der Protokolle und wenn wir darin nachsehen, finden wir
(eventuell)

```output
...
mpiexec -n 1 amdahl > amdahl_run.txt
--------------------------------------------------------------------------
mpiexec was unable to find the specified executable file, and therefore
did not launch the job.  This error was first reported for process
rank 0; it may have occurred for other processes as well.

NOTE: A common cause for this error is misspelling a mpiexec command
      line parameter option (remember that mpiexec interprets the first
      unrecognized command line token as the executable).

Node:       tmpnode1
Executable: amdahl
--------------------------------------------------------------------------
...
```

Obwohl wir das Modul vor der Ausführung des Workflows geladen haben, hat unsere
Snakemake-Regel die ausführbare Datei nicht gefunden. Das liegt daran, dass die
Snakemake-Regel in einer sauberen _Laufzeitumgebung_ läuft, und wir müssen ihr irgendwie
sagen, dass sie das notwendige Umgebungsmodul laden soll, bevor wir versuchen, die Regel
auszuführen.

::::::


:::

## Snakemake und Umgebungsmodule

Unsere Anwendung heißt `amdahl` und ist auf dem System über ein Umgebungsmodul
verfügbar, also müssen wir Snakemake sagen, dass es das Modul laden soll, bevor es
versucht, die Regel auszuführen. Snakemake kennt Umgebungsmodule, und diese können über
eine (weitere) Option angegeben werden:

```python
rule amdahl_run:
    output: "amdahl_run.txt"
    input:
    envmodules:
      "mpi4py",
      "amdahl"
    input:
    shell:
        "mpiexec -n 1 amdahl > {output}"
```

Das Hinzufügen dieser Zeilen reicht jedoch nicht aus, damit die Regel ausgeführt wird.
Sie müssen Snakemake nicht nur mitteilen, welche Module geladen werden sollen, sondern
auch, dass es generell Umgebungsmodule verwenden soll (da die Verwendung von
Umgebungsmodulen Ihre Laufzeitumgebung weniger reproduzierbar macht, da sich die
verfügbaren Module von Cluster zu Cluster unterscheiden können). Dazu müssen Sie
Snakemake eine zusätzliche Option geben

```bash
snakemake --profile cluster_profile --use-envmodules amdahl_run
```

::: challenge

Wir werden im weiteren Verlauf des Tutorials Umgebungsmodule verwenden, also machen Sie
dies zu einer Standardoption unseres Profils (indem Sie den Wert auf `True` setzen)

::::::solution

Aktualisiere unser Clusterprofil auf

```yaml
printshellcmds: True
jobs: 3
executor: slurm
default-resources:
  - mem_mb_per_cpu=3600
  - runtime=2
use-envmodules: True
```

Wenn Sie es testen wollen, müssen Sie die Ausgabedatei der Regel löschen und Snakemake
erneut ausführen.

::::::

:::

## Snakemake und MPI

Im letzten Abschnitt haben wir nicht wirklich eine MPI-Anwendung ausgeführt, da wir nur
auf einem Kern gearbeitet haben. Wie können wir für eine einzelne Regel die Ausführung
auf mehreren Kernen anfordern?

Snakemake bietet allgemeine Unterstützung für MPI, aber der einzige Executor, der MPI
derzeit explizit unterstützt, ist der Slurm-Executor (ein Glück für uns!). Wenn wir uns
unsere Übersetzungstabelle von Slurm nach Snakemake ansehen, stellen wir fest, dass die
relevanten Optionen in der Nähe des unteren Randes erscheinen:

| SLURM             | Snakemake       | Description                                                    |
| ----------------- | --------------- | -------------------------------------------------------------- |
| ...               | ...             | ...                                                            |
| `--ntasks`        | `tasks`         | number of concurrent tasks / ranks                             |
| `--cpus-per-task` | `cpus_per_task` | number of cpus per task (in case of SMP, rather use `threads`) |
| `--nodes`         | `nodes`         | number of nodes                                                |

Diejenige, die uns interessiert, ist `tasks`, da wir nur die Anzahl der Ränge erhöhen
wollen. Wir können diese in einem `resources`-Abschnitt unserer Regel definieren und mit
Platzhaltern auf sie verweisen:

```python
rule amdahl_run:
    output: "amdahl_run.txt"
    input:
    envmodules:
      "amdahl"
    resources:
      mpi='mpiexec',
      tasks=2
    input:
    shell:
        "{resources.mpi} -n {resources.tasks} amdahl > {output}"
```

Das hat funktioniert, aber jetzt haben wir ein kleines Problem. Wir möchten dies für
einige verschiedene Werte von `tasks` tun, was bedeuten würde, dass wir für jeden Lauf
eine andere Ausgabedatei benötigen. Es wäre großartig, wenn wir irgendwie in `output`
den Wert angeben könnten, den wir für `tasks` verwenden wollen... und Snakemake das
übernehmen könnte.

Wir könnten eine _Wildcard_ in der `output` verwenden, um die `tasks` zu definieren, die
wir verwenden wollen. Die Syntax für einen solchen Platzhalter sieht wie folgt aus

```python
output: "amdahl_run_{parallel_tasks}.txt"
```

wobei `parallel_tasks` unser Platzhalter ist.

::: callout

## Wildcards

Wildcards werden in den Zeilen `input` und `output` der Regel verwendet, um Teile von
Dateinamen zu repräsentieren. Ähnlich wie das `*`-Muster in der Shell, kann der
Platzhalter für jeden beliebigen Text stehen, um den gewünschten Dateinamen zu bilden.
Wie bei der Benennung Ihrer Regeln können Sie auch für Ihre Platzhalter einen beliebigen
Namen wählen, hier also `parallel_tasks`. Durch die Verwendung der gleichen Platzhalter
in der Eingabe und der Ausgabe wird Snakemake mitgeteilt, wie die Eingabedateien den
Ausgabedateien zugeordnet werden sollen.

Wenn zwei Regeln einen Platzhalter mit demselben Namen verwenden, behandelt Snakemake
sie als unterschiedliche Einheiten - Regeln in Snakemake sind auf diese Weise in sich
geschlossen.

In der Zeile `shell` kann man den Platzhalter mit `{wildcards.parallel_tasks}`
referenzieren

:::

## Snakemake Reihenfolge der Operationen

Wir fangen gerade erst mit ein paar einfachen Regeln an, aber es lohnt sich, darüber
nachzudenken, was Snakemake genau macht, wenn Sie es ausführen. Es gibt drei
verschiedene Phasen:

1. Bereitet sich auf die Ausführung vor:
    1. Liest alle Regeldefinitionen aus dem Snakefile ein
1. Planen, was zu tun ist:
    1. Zeigt an, welche Datei(en) Sie erstellen lassen wollen
    1. Sucht nach einer passenden Regel, indem es die `output` aller ihm bekannten
       Regeln betrachtet
    1. Füllt die Platzhalter aus, um die `input` für diese Regel zu berechnen
    1. Prüft, ob diese Eingabedatei (falls erforderlich) tatsächlich vorhanden ist
1. Führt die Schritte aus:
    1. Erzeugt das Verzeichnis für die Ausgabedatei, falls erforderlich
    1. Entfernt die alte Ausgabedatei, wenn sie bereits vorhanden ist
    1. Nur dann wird der Shell-Befehl mit den ersetzten Platzhaltern ausgeführt
    1. Prüft, ob der Befehl ohne Fehler ausgeführt *und* die neue Ausgabedatei wie
       erwartet erstellt wurde

::: callout

## Trockenlauf (`-n`) Modus

Es ist oft nützlich, nur die ersten beiden Phasen laufen zu lassen, so dass Snakemake
die auszuführenden Jobs plant und sie auf dem Bildschirm ausgibt, sie aber nie
tatsächlich ausführt. Dies wird mit dem `-n` Flag erreicht, z.B.:

```bash
> $ snakemake -n ...
```

:::

Die Anzahl der Überprüfungen mag im Moment noch pedantisch erscheinen, aber wenn der
Arbeitsablauf mehr Schritte umfasst, wird dies in der Tat sehr nützlich für uns werden.

## Verwendung von Wildcards in unserer Regel

Wir möchten einen Platzhalter in `output` verwenden, um die Anzahl der `tasks` zu
definieren, die wir verwenden möchten. Ausgehend von dem, was wir bisher gesehen haben,
könnten Sie sich vorstellen, dass dies wie folgt aussehen könnte

```python
rule amdahl_run:
    output: "amdahl_run_{parallel_tasks}.txt"
    input:
    envmodules:
      "amdahl"
    resources:
      mpi="mpiexec",
      tasks="{parallel_tasks}"
    input:
    shell:
        "{resources.mpi} -n {resources.tasks} amdahl > {output}"
```

aber es gibt zwei Probleme damit:

- Die einzige Möglichkeit für Snakemake, den Wert des Platzhalters zu erfahren, besteht
  darin, dass der Benutzer explizit eine konkrete Ausgabedatei anfordert (anstatt die
  Regel aufzurufen):

```bash
  snakemake --profile cluster_profile amdahl_run_2.txt
```

Dies ist vollkommen gültig, da Snakemake herausfinden kann, dass es eine Regel gibt, die
mit diesem Dateinamen übereinstimmen kann.

- Das größere Problem ist, dass selbst das nicht funktioniert, es scheint, dass wir
  keinen Platzhalter für `tasks` verwenden können:

  ```output
  WorkflowError:
  SLURM job submission failed. The error message was sbatch:
  error: Invalid numeric value "{parallel_tasks}" for --ntasks.
  ```

Leider gibt es für uns keine direkte Möglichkeit, auf die Platzhalter für `tasks`
zuzugreifen. Der Grund dafür ist, dass Snakemake versucht, den Wert von `tasks` während
seiner Initialisierungsphase zu verwenden, also bevor wir den Wert des Platzhalters
kennen. Wir müssen die Bestimmung von `tasks` auf einen späteren Zeitpunkt verschieben.
Dies kann erreicht werden, indem für dieses Szenario eine Eingabefunktion anstelle eines
Wertes angegeben wird. Die Lösung besteht also darin, eine einmalig zu verwendende
Funktion zu schreiben, die Snakemake dazu bringt, dies für uns zu tun. Da die Funktion
speziell für die Regel gedacht ist, können wir eine einzeilige Funktion ohne Namen
verwenden. Diese Art von Funktionen werden entweder anonyme Funktionen oder
Lamdba-Funktionen genannt (beide bedeuten dasselbe) und sind ein Merkmal von Python (und
anderen Programmiersprachen).

Um eine Lambda-Funktion in Python zu definieren, ist die allgemeine Syntax wie folgt:

```python
lambda x: x + 54
```

Da unsere Funktion die Wildcards als Argumente annehmen kann, können wir damit den Wert
für `tasks` festlegen:

```python
rule amdahl_run:
    output: "amdahl_run_{parallel_tasks}.txt"
    input:
    envmodules:
      "amdahl"
    resources:
      mpi="mpiexec",
      # No direct way to access the wildcard in tasks, so we need to do this
      # indirectly by declaring a short function that takes the wildcards as an
      # argument
      tasks=lambda wildcards: int(wildcards.parallel_tasks)
    input:
    shell:
        "{resources.mpi} -n {resources.tasks} amdahl > {output}"
```

Jetzt haben wir eine Regel, die verwendet werden kann, um die Ausgabe von Läufen einer
beliebigen Anzahl von parallelen Aufgaben zu erzeugen.

::: callout

## Kommentare in Snakefiles

Im obigen Code ist die Zeile, die mit `#` beginnt, eine Kommentarzeile. Hoffentlich
haben Sie sich bereits angewöhnt, Kommentare in Ihre eigenen Skripte einzufügen. Gute
Kommentare machen jedes Skript besser lesbar, und das gilt auch für Snakefiles.

:::

Da unsere Regel nun in der Lage ist, eine beliebige Anzahl von Ausgabedateien zu
erzeugen, könnte es in unserem aktuellen Verzeichnis sehr voll werden. Es ist daher
wahrscheinlich am besten, die Läufe in einen separaten Ordner zu legen, um Ordnung zu
schaffen. Wir können den Ordner direkt zu unserem `output` hinzufügen und Snakemake wird
die Erstellung des Verzeichnisses für uns übernehmen:

```python
rule amdahl_run:
    output: "runs/amdahl_run_{parallel_tasks}.txt"
    input:
    envmodules:
      "amdahl"
    resources:
      mpi="mpiexec",
      # No direct way to access the wildcard in tasks, so we need to do this
      # indirectly by declaring a short function that takes the wildcards as an
      # argument
      tasks=lambda wildcards: int(wildcards.parallel_tasks)
    input:
    shell:
        "{resources.mpi} -n {resources.tasks} amdahl > {output}"
```

::: challenge

Erstellt eine Ausgabedatei (im Ordner `runs`) für den Fall, dass wir 6 parallele
Aufgaben haben

(TIPP: Denken Sie daran, dass Snakemake in der Lage sein muss, die angeforderte Datei
mit dem `output` einer Regel abzugleichen)

:::::: solution

```bash
snakemake --profile cluster_profile runs/amdahl_run_6.txt
```

::::::

:::

Ein weiterer Punkt bei unserer Anwendung `amdahl` ist, dass wir die Ausgabe schließlich
verarbeiten wollen, um unsere Skalierungsdarstellung zu erzeugen. Die derzeitige Ausgabe
ist zwar nützlich zum Lesen, erschwert aber die Verarbeitung. `amdahl` hat eine Option,
die dies für uns einfacher macht. Um die `amdahl`-Optionen zu sehen, können wir
verwenden

```bash
[ocaisa@node1 ~]$ module load amdahl
[ocaisa@node1 ~]$ amdahl --help
```

```output
usage: amdahl [-h] [-p [PARALLEL_PROPORTION]] [-w [WORK_SECONDS]] [-t] [-e]

options:
  -h, --help            show this help message and exit
  -p [PARALLEL_PROPORTION], --parallel-proportion [PARALLEL_PROPORTION]
                        Parallel proportion should be a float between 0 and 1
  -w [WORK_SECONDS], --work-seconds [WORK_SECONDS]
                        Total seconds of workload, should be an integer greater than 0
  -t, --terse           Enable terse output
  -e, --exact           Disable random jitter
```

Die Option, nach der wir suchen, ist `--terse`, und die bewirkt, dass `amdahl` in einem
viel einfacher zu verarbeitenden Format ausgegeben wird, nämlich JSON. Das JSON-Format
in einer Datei verwendet normalerweise die Dateierweiterung `.json`, also fügen wir
diese Option zu unserem `shell`-Befehl hinzu _und_ ändern das Dateiformat von `output`,
damit es zu unserem neuen Befehl passt:

```python
rule amdahl_run:
    output: "runs/amdahl_run_{parallel_tasks}.json"
    input:
    envmodules:
      "amdahl"
    resources:
      mpi="mpiexec",
      # No direct way to access the wildcard in tasks, so we need to do this
      # indirectly by declaring a short function that takes the wildcards as an
      # argument
      tasks=lambda wildcards: int(wildcards.parallel_tasks)
    input:
    shell:
        "{resources.mpi} -n {resources.tasks} amdahl --terse > {output}"
```

Es gab einen weiteren Parameter für `amdahl`, der mir aufgefallen ist. `amdahl` hat eine
Option `--parallel-proportion` (oder `-p`), an deren Änderung wir interessiert sein
könnten, da sie das Verhalten des Codes verändert und sich somit auf die Werte auswirkt,
die wir in unseren Ergebnissen erhalten. Fügen wir eine weitere Verzeichnisebene zu
unserem Ausgabeformat hinzu, um eine bestimmte Wahl für diesen Wert wiederzugeben. Wir
können einen Platzhalter verwenden, damit wir den Wert gleich auswählen müssen:

```python
rule amdahl_run:
    output: "p_{parallel_proportion}/runs/amdahl_run_{parallel_tasks}.json"
    input:
    envmodules:
      "amdahl"
    resources:
      mpi="mpiexec",
      # No direct way to access the wildcard in tasks, so we need to do this
      # indirectly by declaring a short function that takes the wildcards as an
      # argument
      tasks=lambda wildcards: int(wildcards.parallel_tasks)
    input:
    shell:
        "{resources.mpi} -n {resources.tasks} amdahl --terse -p {wildcards.parallel_proportion} > {output}"
```

::: challenge

Erstellen Sie eine Ausgabedatei für einen Wert von `-p` von 0,999 (der Standardwert ist
0,8) für den Fall, dass wir 6 parallele Aufgaben haben.

:::::: solution

```bash
snakemake --profile cluster_profile p_0.999/runs/amdahl_run_6.json
```

::::::

:::

::: keypoints

- "Snakemake wählt die passende Regel durch Ersetzen von Platzhaltern aus, so dass die
  Ausgabe mit dem Ziel übereinstimmt"
- "Snakemake prüft auf verschiedene Fehlerzustände und hält an, wenn es ein Problem
  sieht"

:::


