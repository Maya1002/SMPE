#!/usr/bin/env Rscript

# Analyse statistique essentielle du benchmark Parallel Quicksort.
# Résultat : data/analysis/analysis_report.txt

set.seed(123)
B <- 5000

# 1. Charger le CSV fourni ou sélectionner le plus récent
args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 1) {
  input <- args[1]
} else {
  files <- list.files(
    "data",
    pattern = "^benchmark_.*\\.csv$",
    full.names = TRUE
  )

  if (length(files) == 0) {
    stop("Aucun fichier benchmark_*.csv trouvé dans data/.")
  }

  input <- files[which.max(file.info(files)$mtime)]
}

if (!file.exists(input)) {
  stop("Fichier introuvable : ", input)
}

df <- read.csv(input)

required <- c(
  "repetition", "size",
  "sequential_sec", "parallel_sec", "libc_sec"
)

if (!all(required %in% names(df))) {
  stop("Colonnes manquantes dans le CSV du benchmark.")
}

if (any(!is.finite(as.matrix(df[required]))) ||
    any(as.matrix(df[c("sequential_sec", "parallel_sec", "libc_sec")]) <= 0) ||
    any(df$size <= 0)) {
  stop("Le CSV contient des valeurs invalides.")
}

# 2. Calcul de l'intervalle bootstrap de la médiane
median_ci <- function(x) {
  n <- length(x)

  if (n < 2) {
    return(c(NA_real_, NA_real_))
  }

  boot_medians <- replicate(
    B,
    median(sample(x, size = n, replace = TRUE))
  )

  quantile(
    boot_medians,
    probs = c(0.025, 0.975),
    names = FALSE
  )
}

# 3. Préparer le rapport
outdir <- "data/analysis"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

report_file <- file.path(outdir, "analysis_report.txt")

sink(report_file)

cat("====================================================\n")
cat("  PARALLEL QUICKSORT - RAPPORT STATISTIQUE\n")
cat("====================================================\n\n")
cat("Fichier analysé :", input, "\n")
cat("Nombre de mesures :", nrow(df), "\n")
cat("Nombre de répétitions distinctes :",
    length(unique(df$repetition)), "\n")
cat("IC à 95 % estimé par bootstrap,",
    B, "rééchantillonnages.\n\n")

# 4. Temps d'exécution : médiane, IC 95 %, moyenne et écart-type
algorithms <- c(
  "sequential_sec" = "Séquentiel",
  "parallel_sec" = "Parallèle",
  "libc_sec" = "qsort (libc)"
)

cat("----------------------------------------------------\n")
cat("1. TEMPS D'EXECUTION (secondes)\n")
cat("----------------------------------------------------\n")
cat("IC 95 % : intervalle de confiance de la médiane.\n\n")

for (s in sort(unique(df$size))) {
  cat("Taille du tableau :", format(s, scientific = FALSE), "\n")

  for (col in names(algorithms)) {
    x <- df[df$size == s, col]
    ci <- median_ci(x)

    cat("\n", algorithms[[col]], "\n", sep = "")
    cat(sprintf("  Médiane       : %.6f s\n", median(x)))
    cat(sprintf("  IC 95 %%       : [%.6f ; %.6f] s\n", ci[1], ci[2]))
    cat(sprintf("  Moyenne       : %.6f s\n", mean(x)))
    cat(sprintf("  Écart-type    : %.6f s\n", sd(x)))
  }

  cat("\n")
}

# 5. Speedup : comparaison appariée entre séquentiel et parallèle
# Un speedup > 1 signifie que le parallèle est plus rapide.
df$speedup <- df$sequential_sec / df$parallel_sec

cat("----------------------------------------------------\n")
cat("2. SPEEDUP DU TRI PARALLELE\n")
cat("----------------------------------------------------\n")
cat("Speedup = temps séquentiel / temps parallèle.\n")
cat("Speedup > 1 : parallèle plus rapide.\n")
cat("Speedup < 1 : parallèle plus lent.\n\n")

for (s in sort(unique(df$size))) {
  x <- df[df$size == s, "speedup"]
  ci <- median_ci(x)

  cat("Taille du tableau :", format(s, scientific = FALSE), "\n")
  cat(sprintf("  Speedup médian : %.4f\n", median(x)))
  cat(sprintf("  IC 95 %%        : [%.4f ; %.4f]\n\n", ci[1], ci[2]))
}

sink()

cat("Analyse terminée.\n")
cat("Rapport enregistré dans :", report_file, "\n")