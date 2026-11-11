#!/usr/bin/env bash
set -euo pipefail

# Nombre de répétitions passé en argument (2 par défaut)
REPS="${1:-2}"

if ! [[ "$REPS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Usage: $0 [nombre_de_repetitions]"
    exit 1
fi

# Tailles des tableaux
SIZES=(10000 100000 500000 1000000 5000000 10000000 20000000 50000000)

# Niveaux de parallélisme testés
THREAD_LEVELS=(0 1 2 4 6 8 10)

# Compiler avec optimisations
make -C src clean
make -C src WARNINGS="-g -Wall -O2"

# Créer un fichier de résultats distinct pour chaque expérience
mkdir -p data
OUT="data/benchmark_$(date +%Y%m%d_%H%M%S).csv"

# Ajouter le niveau de threads dans le CSV
echo "repetition,size,thread_level,sequential_sec,parallel_sec,libc_sec" > "$OUT"

echo "Résultats enregistrés dans : $OUT"

for rep in $(seq 1 "$REPS"); do
    echo "=================================================="
    echo "Répétition $rep/$REPS"
    echo "=================================================="

    # Mélanger l'ordre des tailles à chaque répétition
    while IFS= read -r size; do

        # Tester chaque niveau de parallélisme
        for thread_level in "${THREAD_LEVELS[@]}"; do

            echo "  Taille : $size | THREAD_LEVEL : $thread_level"

            result=$(./src/parallelQuicksort "$size" "$thread_level")

            seq_time=$(printf '%s\n' "$result" |
                awk -F': ' '/Sequential quicksort took:/ {
                    gsub(/ sec\./, "", $2); print $2
                }')

            par_time=$(printf '%s\n' "$result" |
                awk -F': ' '/Parallel quicksort took:/ {
                    gsub(/ sec\./, "", $2); print $2
                }')

            libc_time=$(printf '%s\n' "$result" |
                awk -F': ' '/Built-in quicksort took:/ {
                    gsub(/ sec\./, "", $2); print $2
                }')

            if [[ -z "$seq_time" || -z "$par_time" || -z "$libc_time" ]]; then
                echo "Erreur : impossible d'extraire les temps."
                echo "$result"
                exit 1
            fi

            # Ajouter le niveau de parallélisme au CSV
            echo "$rep,$size,$thread_level,$seq_time,$par_time,$libc_time" >> "$OUT"

        done

    done < <(printf '%s\n' "${SIZES[@]}")
done

echo "=================================================="
echo "Benchmark terminé."
echo "Fichier CSV : $OUT"
echo "=================================================="