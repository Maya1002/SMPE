## Fichiers produits

Les principaux fichiers générés par les scripts sont :

- `data/benchmark_*.csv` : les mesures brutes du benchmark ;
- `data/analysis/statistiques.csv` : les statistiques calculées par le script d'analyse, selon la version utilisée ;
- `data/analysis/execution_times.png` : le graphique des temps d'exécution ;
- `data/analysis/speedup.png` : le graphique du speedup ;
- `data/analysis/analysis_report.txt` : le rapport statistique généré par `statistiques_benchmark.R`.

## 1. Configuration de la machine

Les tests ont été réalisés sur un ordinateur utilisant Linux sous WSL2 (Windows Subsystem for Linux 2). Voici les caractéristiques relevées dans le terminal :

Processeur --> AMD Ryzen 7 6800HS Creator Edition 
Architecture --> x86-64 
Nombre de cœurs physiques annoncés --> 8 
Processeurs logiques visibles dans WSL2 --> 16 
Threads par cœur --> 2 
Mémoire totale visible dans WSL2 --> 6,6 Gio 
Mémoire disponible au moment de la vérification -->  4,5 Gio 
Mémoire swap --> 2 Gio 
Système d'exploitation --> Linux sous WSL2 
Version du noyau Linux --> 6.18.54.1-microsoft-standard-WSL2 
Compilateur C --> GCC 16.2.0 (Debian) 

Le programme est compilé avec les options `-O2`, `-Wall` et `-g`, d'après le script de benchmark utilisé.

## 2. Objectif du projet

Comparer les performances de trois méthodes de tri :

- **Tri séquentiel** : les opérations de tri sont réalisées dans un seul flux d'exécution.
- **Tri parallèle** : le travail est réparti entre plusieurs tâches ou threads, selon l'implémentation du programme.
- **qsort** : la fonction de tri fournie par la bibliothèque standard du langage C.

## 3. Exécution des scripts

### 3.1. Lancer le benchmark

1 - bash scripts/benchmark_improved.sh 10

Le nombre 10 correspond au nombre de répétitions par taille. Les résultats sont enregistrés dans un fichier CSV daté.

Remplacer le nom du fichier par celui du benchmark obtenu :

2 - Rscript scripts/analyse_benchmark.R data/benchmark_20261026_010407.csv

3 - Générer le rapport statistique : Rscript scripts/statistiques_benchmark.R data/benchmark_20261026_010407.csv

Le rapport est enregistré dans data/analysis/analysis_report.txt. Il contient les médianes, les moyennes, les écarts-types et les intervalles de confiance bootstrap à 95 %.

5. Analyse des résultats

Le tri séquentiel reste le plus rapide et obtient le meilleur temps médian pour toutes les tailles testées.

Pour 50 millions d'éléments, il prend environ 5,90 secondes, contre 7,40 secondes pour le tri parallèle. Le parallèle est donc environ 25 % plus lent que le séquentiel.

Le tri parallèle devient plus compétitif

Le speedup augmente globalement avec la taille du tableau, passant de 0,0079 pour 10 000 éléments à 0,8062 pour 50 millions.

Le tri parallèle se rapproche donc du séquentiel lorsque la quantité de données augmente, mais son speedup reste inférieur à 1 : il ne devient jamais plus rapide dans ces tests.

Une explication possible est le coût supplémentaire de gestion des threads ou des tâches, particulièrement important pour les petits tableaux. Pour confirmer cette hypothèse, il faudrait examiner le code du tri parallèle.

## Comparaison avec qsort

Pour les tableaux de 5, 10, 20 et 50 millions d'éléments, le tri parallèle est plus rapide que qsort dans ce benchmark. À 50 millions d'éléments, qsort prend environ 8,84 secondes, contre 7,40 secondes pour le parallèle.

Cela ne signifie pas que qsort est toujours moins performant

## Fiabilité des mesures

Les 10 répétitions par taille donnent une meilleure base de comparaison que le premier test à 3 répétitions. Les intervalles de confiance bootstrap à 95 % du speedup restent sous 1 pour toutes les tailles, ce qui va dans le même sens que les médianes.

Ces intervalles indiquent l'incertitude autour de la médiane estimée ; ils ne représentent pas la plage contenant 95 % des mesures individuelles. Les résultats restent liés à cette machine, à WSL2 et aux implémentations testées.

## 6. Conclusion

Dans cette expérience, le tri séquentiel reste le plus rapide pour toutes les tailles testées, jusqu'à 50 millions d'éléments. Le tri parallèle devient plus compétitif lorsque les tableaux grandissent et dépasse qsort pour les plus grandes tailles, mais il ne dépasse pas le séquentiel.

Le parallélisme ne garantit donc pas automatiquement un gain de performance. Pour améliorer les résultats, il serait intéressant d'examiner la gestion des threads, de tester différents nombres de threads et de mesurer l'effet de ces changements avec le même protocole.
