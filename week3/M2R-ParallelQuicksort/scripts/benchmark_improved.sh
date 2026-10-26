#!/usr/bin/env bash
set -euo pipefail

# Nombre de répétitions passé en argument (2 par défaut)
REPS="${1:-2}"

if ! [[ "$REPS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Usage: $0 [nombre_de_repetitions]"
    exit 1
fi

SIZES=(10000 100000 500000 1000000 5000000 10000000 20000000 50000000)

# Compiler avec optimisations
make -C src clean
make -C src WARNINGS="-g -Wall -O2"

# Créer un fichier de résultats distinct pour chaque expérience
mkdir -p data
OUT="data/benchmark_$(date +%Y%m%d_%H%M%S).csv"

echo "repetition,size,sequential_sec,parallel_sec,libc_sec" > "$OUT"

echo "Résultats enregistrés dans : $OUT"

for rep in $(seq 1 "$REPS"); do
    echo "Répétition $rep/$REPS"

    # Mélanger l'ordre des tailles à chaque répétition
    while IFS= read -r size; do
        echo "  Taille : $size"

        result=$(./src/parallelQuicksort "$size")

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

        echo "$rep,$size,$seq_time,$par_time,$libc_time" >> "$OUT"

    done < <(shuf -e "${SIZES[@]}")
done

echo "Benchmark terminé."
echo "Fichier CSV : $OUT"
