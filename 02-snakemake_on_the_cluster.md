---
title: Ausführen von Snakemake auf dem Cluster
teaching: 30
exercises: 20
---


::: objectives

- "Definieren Sie Regeln, die lokal und auf dem Cluster ausgeführt werden"

:::

::: questions

- "Wie führe ich meine Snakemake-Regel auf dem Cluster aus?"

:::

Was passiert, wenn wir unsere Regel auf dem Cluster und nicht auf dem Anmeldeknoten
laufen lassen wollen? Der Cluster, den wir verwenden, benutzt Slurm, und es ist so, dass
Snakemake eine eingebaute Unterstützung für Slurm hat, wir müssen ihm nur sagen, dass
wir es benutzen wollen.

Snakemake verwendet die Option `executor`, um Ihnen die Möglichkeit zu geben, das Plugin
auszuwählen, mit dem Sie die Regel ausführen möchten. Der schnellste Weg, dies auf Ihr
Snakefile anzuwenden, ist, dies auf der Kommandozeile zu definieren. Probieren wir es
aus

```bash
[ocaisa@node1 ~]$ snakemake -j1 -p --executor slurm hostname_login
```

```output
Building DAG of jobs...
Retrieving input from storage.
Nothing to be done (all requested files are present and up to date).
```

Nichts passiert! Warum nicht? Wenn Snakemake aufgefordert wird, ein Ziel zu erstellen,
prüft es die "letzte Änderungszeit" sowohl des Ziels als auch seiner Abhängigkeiten.
Wenn eine der Abhängigkeiten seit dem Ziel aktualisiert wurde, werden die Aktionen
erneut ausgeführt, um das Ziel zu aktualisieren. Auf diese Weise weiß Snakemake, dass es
nur die Dateien neu erstellen muss, die entweder direkt oder indirekt von der geänderten
Datei abhängen. Dies wird _inkrementeller Build_ genannt.

::: callout

## Inkrementelle Builds verbessern die Effizienz

Indem Snakemake Dateien nur bei Bedarf neu erstellt, macht es Ihre Verarbeitung
effizienter.

:::

::: challenge

## Läuft auf dem Cluster

Wir brauchen jetzt eine weitere Regel, die die `hostname` auf dem _Cluster_ ausführt.
Erstellen Sie eine neue Regel in Ihrem Snakefile und versuchen Sie, sie auf dem Cluster
mit der Option `--executor slurm` bis `snakemake` auszuführen.

:::::: solution

Die Regel ist fast identisch mit der vorherigen Regel, außer dem Namen der Regel und der
Ausgabedatei:

```python
rule hostname_remote:
    output: "hostname_remote.txt"
    input:
    shell:
        "hostname > hostname_remote.txt"
```

Sie können die Regel dann ausführen mit

```bash
[ocaisa@node1 ~]$ snakemake -j1 -p --executor slurm hostname_remote
```

```output
Building DAG of jobs...
Retrieving input from storage.
Using shell: /cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64/bin/bash
Provided remote nodes: 1
Job stats:
job                count
---------------  -------
hostname_remote        1
total                  1

Select jobs to execute...
Execute 1 jobs...

[Mon Jan 29 18:03:46 2024]
rule hostname_remote:
    output: hostname_remote.txt
    jobid: 0
    reason: Missing output files: hostname_remote.txt
    resources: tmpdir=<TBD>

hostname > hostname_remote.txt
No SLURM account given, trying to guess.
Guessed SLURM account: def-users
No wall time information given. This might or might not work on your cluster.
If not, specify the resource runtime in your rule or as a reasonable default
via --default-resources. No job memory information ('mem_mb' or 
'mem_mb_per_cpu') is given - submitting without.
This might or might not work on your cluster.
Job 0 has been submitted with SLURM jobid 326 (log: /home/ocaisa/.snakemake/slurm_logs/rule_hostname_remote/326.log).
[Mon Jan 29 18:04:26 2024]
Finished job 0.
1 of 1 steps (100%) done
Complete log: .snakemake/log/2024-01-29T180346.788174.snakemake.log
```

Beachten Sie die Warnungen, die Snakemake ausgibt, dass die Regel möglicherweise nicht
auf unserem Cluster ausgeführt werden kann, da wir nicht genügend Informationen
angegeben haben. Zum Glück für uns funktioniert dies auf unserem Cluster und wir können
einen Blick in die Ausgabedatei werfen, die die neue Regel erzeugt,
`hostname_remote.txt`:

```bash
[ocaisa@node1 ~]$ cat hostname_remote.txt
```

```output
tmpnode1.int.jetstream2.hpc-carpentry.org
```

::::::

:::

## Snakemake-Profil

Das Anpassen von Snakemake an eine bestimmte Umgebung kann viele Flags und Optionen mit
sich bringen. Daher ist es möglich, ein Konfigurationsprofil anzugeben, das verwendet
wird, um Standardoptionen zu erhalten. Das sieht dann so aus

```bash
snakemake --profile myprofileFolder ...
```

Der Profilordner muss eine Datei namens `config.yaml` enthalten, in der unsere Optionen
gespeichert werden. Der Ordner kann auch andere Dateien enthalten, die für das Profil
erforderlich sind. Erstellen wir die Datei `cluster_profile/config.yaml` und fügen wir
einige unserer bestehenden Optionen ein:

```yaml
printshellcmds: True
jobs: 3
executor: slurm
```

Wir sollten nun in der Lage sein, unseren Workflow erneut auszuführen, indem wir auf das
Profil verweisen, anstatt die Optionen aufzulisten. Um die erneute Ausführung unseres
Arbeitsablaufs zu erzwingen, müssen wir zuerst die Ausgabedatei `hostname_remote.txt`
entfernen, und dann können wir unser neues Profil ausprobieren

```bash
[ocaisa@node1 ~]$ rm hostname_remote.txt
[ocaisa@node1 ~]$ snakemake --profile cluster_profile hostname_remote
```

Das Profil ist im Kontext unseres Clusters äußerst nützlich, da der Slurm-Executor über
viele Optionen verfügt, die man manchmal nutzen muss, um Jobs an den Cluster zu
übermitteln, auf den man Zugriff hat. Leider sind die Namen der Optionen in Snakemake
nicht _exakt_ dieselben wie die von Slurm, so dass wir die Hilfe einer
Übersetzungstabelle benötigen:

| SLURM             | Snakemake         | Description                                                    |
| ----------------- | ----------------- | -------------------------------------------------------------- |
| `--partition`     | `slurm_partition` | the partition a rule/job is to use                             |
| `--time`          | `runtime`         | the walltime per job in minutes                                |
| `--constraint`    | `constraint`      | may hold features on some clusters                             |
| `--mem`           | `mem, mem_mb`     | memory a cluster node must                                     |
|                   |                   | provide (mem: string with unit), mem_mb: int                   |
| `--mem-per-cpu`   | `mem_mb_per_cpu`  | memory per reserved CPU                                        |
| `--ntasks`        | `tasks`           | number of concurrent tasks / ranks                             |
| `--cpus-per-task` | `cpus_per_task`   | number of cpus per task (in case of SMP, rather use `threads`) |
| `--nodes`         | `nodes`           | number of nodes                                                |

Die von Snakemake ausgegebenen Warnungen wiesen darauf hin, dass wir diese Optionen
möglicherweise bereitstellen müssen. Eine Möglichkeit, dies zu tun, ist, sie als Teil
der Snakemake-Regel mit dem Schlüsselwort `resources` anzugeben, z.B,

```python
rule:
    input: ...
    output: ...
    resources:
        partition: <partition name>
        runtime: <some number>
```

und wir können das Profil auch verwenden, um Standardwerte für diese Optionen zu
definieren, die wir für unser Projekt verwenden, indem wir das Schlüsselwort
`default-resources` verwenden. Der verfügbare Arbeitsspeicher unseres Clusters beträgt
beispielsweise etwa 4 GB pro Kern, so dass wir dies zu unserem Profil hinzufügen können:

```yaml
printshellcmds: True
jobs: 3
executor: slurm
default-resources:
  - mem_mb_per_cpu=3600
```

:::challenge

Wir wissen, dass unser Problem in einer sehr kurzen Zeit abläuft. Ändern Sie die
Standardlänge unserer Jobs auf zwei Minuten für Slurm.

::::::solution

```yaml
printshellcmds: True
jobs: 3
executor: slurm
default-resources:
  - mem_mb_per_cpu=3600
  - runtime=2
```

::::::

:::

Es gibt verschiedene `sbatch` Optionen, die nicht direkt von den Ressourcendefinitionen
in der obigen Tabelle unterstützt werden. Du kannst die `slurm_extra` Ressource
benutzen, um jede dieser zusätzlichen Flags für `sbatch` anzugeben:

```python
rule myrule:
    input: ...
    output: ...
    resources:
        slurm_extra="--mail-type=ALL --mail-user=<your email>"
```

## Lokale Regelausführung

Unsere ursprüngliche Regel war es, den Hostnamen des Anmeldeknotens zu ermitteln. Wir
wollen diese Regel immer auf dem Login-Knoten ausführen, damit sie Sinn macht. Wenn wir
Snakemake anweisen, alle Regeln über den Slurm-Executor auszuführen (was wir über unser
neues Profil tun), wird dies nicht mehr geschehen. Wie können wir also erzwingen, dass
die Regel auf dem Anmeldeknoten ausgeführt wird?

Nun, in dem Fall, in dem eine Snakemake-Regel eine triviale Aufgabe ausführt, könnte die
Übermittlung eines Jobs ein Overkill sein (z.B. weniger als 1 Minute Rechenzeit).
Ähnlich wie in unserem Fall wäre es eine bessere Idee, diese Regeln lokal auszuführen
(d.h. dort, wo der Befehl `snakemake` ausgeführt wird), anstatt sie als Job zu
übermitteln. In Snakemake können Sie mit dem Schlüsselwort `localrules` angeben, welche
Regeln immer lokal ausgeführt werden sollen. Definieren wir `hostname_login` als lokale
Regel nahe dem Anfang unseres `Snakefile`.

```python
localrules: hostname_login
```

::: keypoints

- "Snakemake generiert und übermittelt seine eigenen Batch-Skripte für Ihren Scheduler."
- "Sie können Standardkonfigurationseinstellungen in einem Snakemake-Profil speichern"
- "`localrules` definiert Regeln, die lokal ausgeführt werden und nie an einen Cluster
  übermittelt werden."

:::


