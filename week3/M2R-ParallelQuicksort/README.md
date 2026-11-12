# Analyse des performances

## 1. Configuration expérimentale

Les benchmarks ont été réalisés sous **Linux dans WSL2** sur une machine équipée d'un **AMD Ryzen 7 6800HS Creator Edition**. WSL2 expose 8 cœurs physiques et 16 processeurs logiques. La mémoire visible est de 6,6 Gio, avec 2 Gio de swap. Le programme a été compilé avec **GCC 16.2.0** et les options `-O2 -Wall -g`.

Le benchmark compare trois méthodes de tri : le tri séquentiel, notre implémentation de tri parallèle et `qsort` fourni par la bibliothèque standard C.

Pour le tri parallèle, plusieurs niveaux de récursion ont été testés :

```text
THREAD_LEVEL = 0, 1, 2, 4, 6, 8, 10
```
### Démarche expérimentale

Pour chaque taille de tableau et chaque `THREAD_LEVEL`, le benchmark est exécuté plusieurs fois. Les temps obtenus sont ensuite regroupés par configuration afin de calculer la moyenne et l'écart-type.

À partir de ces répétitions, un intervalle de confiance à 95 % est calculé avec :

```text
IC 95 % = moyenne ± 1,96 × écart-type / √n
```
où `n` correspond au nombre de répétitions.

Le coefficient 1,96 correspond au niveau de confiance de 95 %. n correspond au nombre de répétitions. ( P (-1,96 < Z < 1,96) )

Details de calcul : On veut un intervalle central de 95 %

soit : P (-z < Z < +z )  = 0,95 implique qu'il reste : P( Z < -z ) + P( Z > z ) = 0,05
        1-0,95 = 0,05 => 0,05/2 = 0,025 ( car par symétrie P( Z < -z ) = P( Z > z ) )

On cherche z tel que : P(Z < -z) = 0,025
Par symétrie de la loi normale : P(Z > z) = 0,025
Donc : P(Z < z) = 1 - 0,025 = 0,975
Avec la table de la loi normale, on trouve : z = fct_de_repartition(0,975) ≈ 1,96

Le speedup est ensuite calculé entre le temps séquentiel et le temps parallèle. Pour chaque taille de tableau, le `THREAD_LEVEL` donnant le meilleur speedup moyen est retenu. Les résultats sont enfin représentés sous forme de graphiques et de tableaux.

## 2. Fichiers ajoutés

### Benchmark

- `scripts/benchmark_improved.sh` : lance automatiquement les benchmarks pour les différentes tailles, les niveaux de `THREAD_LEVEL` et le nombre de répétitions.
- `src/parallelQuicksort.c` : permet de définir la taille du tableau et le `THREAD_LEVEL` directement depuis la ligne de commande.

### Analyse statistique

- `scripts/analyse_benchmark.R`: calcule les moyennes, les écarts-types, les speedups et le meilleur THREAD_LEVEL.
- `data/benchmark_*.csv` : contient les mesures brutes produites par les benchmarks.
- `data/analysis/statistiques_thread_level.csv` : contient les statistiques calculées pour chaque taille et chaque `THREAD_LEVEL`.
- `data/analysis/best_thread_level.csv` : contient le meilleur `THREAD_LEVEL` identifié pour chaque taille.

### Visualisations

- `data/analysis/parallel_thread_levels.png` : évolution des performances du tri parallèle selon `THREAD_LEVEL`.
- `data/analysis/speedup_thread_levels.png` : évolution du speedup selon la taille du tableau et le `THREAD_LEVEL`.

Les fichiers CSV et les graphiques sont générés automatiquement à partir des mesures du benchmark.

## 3. Lancement du benchmark

Le benchmark est lancé avec le nombre de répétitions souhaité :

```bash
./scripts/benchmark_improved.sh 10
```

Le fichier CSV généré est ensuite utilisé pour l'analyse :

```bash
Rscript scripts/analyse_benchmark.R data/benchmark_20261111_180819.csv
```

Le script calcule les moyennes, les écarts-types, les intervalles de confiance à 95 %, les speedups et le meilleur `THREAD_LEVEL` pour chaque taille.

## 4. Influence de `THREAD_LEVEL`

![Temps du tri parallèle selon THREAD_LEVEL](data/analysis/parallel_thread_levels.png)

*Figure 2 - Temps d'exécution du tri parallèle pour les différents niveaux de `THREAD_LEVEL`.*

Le meilleur niveau dépend de la taille du tableau. `THREAD_LEVEL = 2` donne les meilleurs résultats pour 500 000 éléments puis pour les tailles de 5 à 50 millions d'éléments.

| Taille      | Meilleur `THREAD_LEVEL` | Speedup moyen |
|:------------|:-----------------------:|--------------:|
| 10 000      | 1                       | 0,568         |
| 100 000     | 0                       | 0,954         |
| 500 000     | 2                       | 1,055         |
| 1 000 000   | 1                       | 1,081         |
| 5 000 000   | 2                       | 1,117         |
| 10 000 000  | 2                       | 1,176         |
| 20 000 000  | 2                       | 1,162         |
| 50 000 000  | 2                       | 1,230         |

Pour 100 000 éléments, THREAD_LEVEL = 0 donne le meilleur résultat parmi les niveaux testés. Cela correspond au cas séquentiel et montre que le parallélisme n'apporte pas de gain pour cette taille.

Pour les petits tableaux, le travail à effectuer est trop faible pour que la création de plusieurs threads soit intéressante. Pour les grandes tailles, le temps de calcul devient suffisamment important pour compenser ce coût.

## 5. Speedup

![Speedup du tri parallèle](data/analysis/speedup_thread_levels.png)

*Figure 3 - Speedup moyen du tri parallèle par rapport au tri séquentiel.*

Le speedup est calculé par :

```text
speedup = temps séquentiel / temps parallèle
```
Un speedup égal à 1 signifie que les deux méthodes ont le même temps d'exécution. Au-dessus de 1, le tri parallèle est plus rapide ; en dessous de 1, il est plus lent.

Les meilleurs résultats obtenus pour chaque taille sont :

| Taille      | `THREAD_LEVEL` | Speedup moyen | IC 95 % |
|:------------|:--------------:|--------------:|:-------:|
| 10 000      | 1              | 0,568         | [0,483 ; 0,653]|
| 100 000     | 0              | 0,954         | [0,908 ; 1,000] |
| 500 000     | 2              | 1,055         | [1,023 ; 1,087] |
| 1 000 000   | 1              | 1,081         | [1,011 ; 1,150] |
| 5 000 000   | 2              | 1,117         | [1,083 ; 1,151] |
| 10 000 000  | 2              | 1,176         | [1,116 ; 1,237] |
| 20 000 000  | 2              | 1,162         | [1,112 ; 1,212] |
| 50 000 000  | 2              | **1,230**     |**[1,177 ; 1,283]** |

Pour 10 000 éléments, le meilleur speedup moyen est seulement de **0,568** avec `THREAD_LEVEL = 1`. Le parallélisme est donc clairement défavorable pour cette taille.

À 100 000 éléments, le meilleur niveau testé est `THREAD_LEVEL = 0`, avec un speedup moyen de **0,954**. L'intervalle de confiance est très proche de `1`, ce qui ne permet pas de mettre en évidence un gain clair du tri parallèle dans cette configuration.

À partir de 500 000 éléments, le meilleur speedup devient supérieur à `1`. Pour 500 000 éléments, le speedup moyen atteint **1,055** avec `THREAD_LEVEL = 2`. L'intervalle de confiance `[1,023 ; 1,087]` est entièrement supérieur à `1`, ce qui indique un gain en faveur du tri parallèle dans cette configuration.

Pour 1 million d'éléments, le speedup moyen est de 1,081 avec THREAD_LEVEL = 1. Le gain reste faible : la borne inférieure de l'intervalle de confiance est seulement légèrement supérieure à 1.

Pour les tailles de 5 à 50 millions d'éléments, THREAD_LEVEL = 2 est le meilleur niveau testé. Le speedup atteint **1,176** pour 10 millions d'éléments et **1,162** pour 20 millions d'éléments.

Le meilleur résultat est obtenu pour 50 millions d'éléments :

- **Speedup moyen : 1,230**
- **IC 95 % : [1,177 ; 1,283]**
- **THREAD_LEVEL : 2**

Pour 50 millions d'éléments, le speedup moyen de **1,230** correspond à une accélération d'environ **23 %** par rapport au tri séquentiel. L'intervalle de confiance est entièrement supérieur à `1`, ce qui confirme que le gain observé est compatible avec une accélération du tri parallèle dans cette configuration.

Globalement, les résultats montrent donc que le parallélisme devient réellement intéressant lorsque la taille du tableau est suffisamment grande pour amortir son coût de gestion.

## 6. Conclusion

Les résultats montrent que le tri parallèle n'est pas intéressant pour les petites tailles, mais qu'il devient plus efficace lorsque la taille du tableau augmente.

Pour **10 000 éléments**, le tri parallèle est nettement moins performant que le tri séquentiel. Pour 100 000 éléments, le meilleur niveau testé est THREAD_LEVEL = 0, avec un speedup moyen de 0,954. L'intervalle de confiance est très proche de 1, ce qui ne permet pas de mettre en évidence un gain clair du tri parallèle dans cette configuration.

À partir de 500 000 éléments, le parallélisme devient avantageux. THREAD_LEVEL = 2 donne les meilleurs résultats pour les grandes tailles, avec un speedup moyen atteignant 1,230 pour 50 millions d'éléments.

Augmenter THREAD_LEVEL n'améliore donc pas forcément les performances. Dans nos tests, le meilleur niveau dépend de la taille du tableau et les niveaux élevés ne donnent pas systématiquement de meilleurs résultats.