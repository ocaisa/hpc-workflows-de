---
title: Verkettung von Regeln
teaching: 40
exercises: 30
---


::: questions

- "Wie kombiniere ich Regeln zu einem Workflow?"
- "Wie erstelle ich eine Regel mit mehreren Eingaben und Ausgaben?"

:::

::: objectives

- ""

:::

## Eine Pipeline mit mehreren Regeln

Wir haben jetzt eine Regel, die eine Ausgabe für jeden Wert von `-p` und eine beliebige
Anzahl von Aufgaben erzeugen kann, wir müssen Snakemake nur mit den gewünschten
Parametern aufrufen:

```bash
snakemake --profile cluster_profile p_0.999/runs/amdahl_run_6.json
```

Das ist allerdings nicht gerade praktisch, denn um einen vollständigen Datensatz zu
erzeugen, müssen wir Snakemake viele Male mit verschiedenen Ausgabedateien ausführen.
Lassen Sie uns stattdessen eine Regel erstellen, die diese Dateien für uns generieren
kann.

Die Verkettung von Regeln in Snakemake ist eine Frage der Wahl von Dateinamensmustern,
die die Regeln verbinden. Das ist eine Kunst für sich - meistens gibt es mehrere
Möglichkeiten, die funktionieren:

```python
rule generate_run_files:
    output: "p_{parallel_proportion}_runs.txt"
    input:  "p_{parallel_proportion}/runs/amdahl_run_6.json"
    shell:
        "echo {input} done > {output}"
```

::: challenge

Die neue Regel macht keine Arbeit, sie stellt nur sicher, dass wir die gewünschte Datei
erzeugen. Sie ist es nicht wert, auf dem Cluster ausgeführt zu werden. Wie kann man
sicherstellen, dass sie nur auf dem Anmeldeknoten ausgeführt wird?

:::::: solution

Wir müssen die neue Regel zu unserer `localrules` hinzufügen:

```python
localrules: hostname_login, generate_run_files
```

:::

:::

Führen wir nun die neue Regel aus (denken Sie daran, dass wir die Ausgabedatei mit dem
Namen anfordern müssen, da das `output` in unserer Regel ein Platzhaltermuster enthält):

```bash
[ocaisa@node1 ~]$ snakemake --profile cluster_profile/ p_0.999_runs.txt
```

```output
Using profile cluster_profile/ for setting default command line arguments.
Building DAG of jobs...
Retrieving input from storage.
Using shell: /cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64/bin/bash
Provided remote nodes: 3
Job stats:
job                   count
------------------  -------
amdahl_run                1
generate_run_files        1
total                     2

Select jobs to execute...
Execute 1 jobs...

[Tue Jan 30 17:39:29 2024]
rule amdahl_run:
    output: p_0.999/runs/amdahl_run_6.json
    jobid: 1
    reason: Missing output files: p_0.999/runs/amdahl_run_6.json
    wildcards: parallel_proportion=0.999, parallel_tasks=6
    resources: mem_mb=1000, mem_mib=954, disk_mb=1000, disk_mib=954,
               tmpdir=<TBD>, mem_mb_per_cpu=3600, runtime=2, mpi=mpiexec, tasks=6

mpiexec -n 6 amdahl --terse -p 0.999 > p_0.999/runs/amdahl_run_6.json
No SLURM account given, trying to guess.
Guessed SLURM account: def-users
Job 1 has been submitted with SLURM jobid 342 (log: /home/ocaisa/.snakemake/slurm_logs/rule_amdahl_run/342.log).
[Tue Jan 30 17:47:31 2024]
Finished job 1.
1 of 2 steps (50%) done
Select jobs to execute...
Execute 1 jobs...

[Tue Jan 30 17:47:31 2024]
localrule generate_run_files:
    input: p_0.999/runs/amdahl_run_6.json
    output: p_0.999_runs.txt
    jobid: 0
    reason: Missing output files: p_0.999_runs.txt;
            Input files updated by another job: p_0.999/runs/amdahl_run_6.json
    wildcards: parallel_proportion=0.999
    resources: mem_mb=1000, mem_mib=954, disk_mb=1000, disk_mib=954,
               tmpdir=/tmp, mem_mb_per_cpu=3600, runtime=2

echo p_0.999/runs/amdahl_run_6.json done > p_0.999_runs.txt
[Tue Jan 30 17:47:31 2024]
Finished job 0.
2 of 2 steps (100%) done
Complete log: .snakemake/log/2024-01-30T173929.781106.snakemake.log
```

Schauen Sie sich die Logging-Meldungen an, die Snakemake im Terminal ausgibt. Was ist
hier passiert?

1. Snakemake sucht nach einer Regel, die `p_0.999_runs.txt` erzeugt
1. Es bestimmt, dass "generate_run_files" dies machen kann, wenn
   `parallel_proportion=0.999`
1. Es sieht, dass die benötigte Eingabe also `p_0.999/runs/amdahl_run_6.json` ist
1. Snakemake sucht nach einer Regel, die `p_0.999/runs/amdahl_run_6.json` erzeugt
1. Es wird festgestellt, dass "amdahl_run" dies machen kann, wenn
   `parallel_proportion=0.999` und `parallel_tasks=6`
1. Nachdem Snakemake eine verfügbare Eingabedatei erreicht hat (in diesem Fall ist
   eigentlich keine Eingabedatei erforderlich), führt es beide Schritte aus, um die
   endgültige Ausgabe zu erhalten

Dies ist, kurz gesagt, wie wir Arbeitsabläufe in Snakemake aufbauen.

1. Definieren Sie Regeln für alle Verarbeitungsschritte
1. Wählen Sie `input` und `output` Namensmuster, die es Snakemake erlauben, die Regeln
   zu verknüpfen
1. Sagt Snakemake, dass es die endgültige(n) Ausgabedatei(en) erzeugen soll

Wenn Sie es gewohnt sind, reguläre Skripte zu schreiben, ist dies ein wenig
gewöhnungsbedürftig. Anstatt die Schritte in der Reihenfolge ihrer Ausführung
aufzulisten, arbeiten Sie immer **rückwärts** vom gewünschten Endergebnis aus. Die
Reihenfolge der Operationen wird durch die Anwendung der Mustervergleichsregeln auf die
Dateinamen bestimmt, nicht durch die Reihenfolge der Regeln in der Snakefile.

::: callout

## Outputs first?

Der Ansatz von Snakemake, von der gewünschten Ausgabe rückwärts zu arbeiten, um den
Arbeitsablauf zu bestimmen, ist der Grund, warum wir die `output`-Zeilen an den Anfang
aller unserer Regeln stellen - um uns daran zu erinnern, dass dies die Zeilen sind, auf
die Snakemake zuerst schaut!

Viele Benutzer von Snakemake, und auch die offizielle Dokumentation, bevorzugen es, die
`input` an erster Stelle zu haben, also sollten Sie in der Praxis die Reihenfolge
verwenden, die für Sie sinnvoll ist.

:::

::: callout

## `log` Ausgaben in Snakemake

Snakemake hat ein eigenes Regelfeld für Ausgaben, die [Logdateien]
(https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html#log-files) sind, und
diese werden größtenteils wie reguläre Ausgaben behandelt, außer dass Logdateien nicht
entfernt werden, wenn der Job einen Fehler produziert. Das bedeutet, dass Sie sich das
Protokoll ansehen können, um den Fehler zu diagnostizieren. In einem echten
Arbeitsablauf kann dies sehr nützlich sein, aber um die Grundlagen von Snakemake zu
erlernen, bleiben wir hier bei regulären `input` und `output` Feldern.

:::

::: callout

## Fehler sind normal

Lassen Sie sich nicht entmutigen, wenn Sie beim ersten Testen Ihrer neuen
Snakemake-Pipelines Fehler sehen. Beim Schreiben eines neuen Arbeitsablaufs kann eine
Menge schief gehen, und Sie werden normalerweise mehrere Iterationen benötigen, um alles
richtig zu machen. Ein Vorteil des Snakemake-Ansatzes im Vergleich zu normalen Skripten
ist, dass Snakemake bei Problemen schnell abbricht, anstatt weiterzumachen und
möglicherweise unbrauchbare Berechnungen mit unvollständigen oder beschädigten Daten
durchzuführen. Ein weiterer Vorteil ist, dass wir bei einem Fehlschlag eines Schrittes
sicher dort weitermachen können, wo wir aufgehört haben.

:::



::: keypoints

- "Snakemake verknüpft Regeln, indem es iterativ nach Regeln sucht, die fehlende
  Eingaben machen"
- "Regeln können mehrere benannte Eingänge und/oder Ausgänge haben"
- "Wenn ein Shell-Befehl nicht die erwartete Ausgabe liefert, wird Snakemake dies als
  Fehler betrachten

:::


