#!/usr/bin/env Rscript

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("ggplot2 is missing. Install it with: sudo apt install r-cran-ggplot2")
}

library(ggplot2)

# Input CSV (or use the default file)
args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args) >= 1) args[1] else
  "data/benchmark_20261020_110416.csv"

if (!file.exists(input)) {
  stop("CSV file not found: ", input)
}

outdir <- "data/analysis"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

df <- read.csv(input)

required <- c("repetition", "size", "sequential_sec",
              "parallel_sec", "libc_sec")

if (!all(required %in% names(df))) {
  stop("Missing required columns in CSV.")
}

if (any(!is.finite(as.matrix(df[required]))) ||
    any(df[, c("sequential_sec", "parallel_sec", "libc_sec")] <= 0)) {
  stop("Invalid or non-positive values in CSV.")
}

# Calculate median execution times
stats <- aggregate(
  cbind(sequential_sec, parallel_sec, libc_sec) ~ size,
  data = df,
  FUN = median
)

write.csv(stats, file.path(outdir, "statistiques.csv"), row.names = FALSE)

# Graph 1: execution times
long <- rbind(
  data.frame(size=stats$size, method="Sequential", time=stats$sequential_sec),
  data.frame(size=stats$size, method="Parallel", time=stats$parallel_sec),
  data.frame(size=stats$size, method="qsort (libc)", time=stats$libc_sec)
)

p1 <- ggplot(long, aes(x=size, y=time, color=method)) +
  geom_line() +
  geom_point(size=2.5) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title="Sorting Algorithm Execution Times",
    x="Array size (number of elements)",
    y="Median execution time (seconds)",
    color="Algorithm"
  ) +
  theme_minimal()

ggsave(file.path(outdir, "execution_times.png"), p1,
       width=8, height=5, dpi=150)

# Graph 2: parallel speedup
df$speedup <- df$sequential_sec / df$parallel_sec

speedup <- aggregate(speedup ~ size, data=df, FUN=median)

p2 <- ggplot(speedup, aes(x=size, y=speedup)) +
  geom_hline(yintercept=1, linetype="dashed") +
  geom_line() +
  geom_point(size=2.5) +
  scale_x_log10() +
  labs(
    title="Parallel Quicksort Speedup",
    x="Array size (number of elements)",
    y="Median speedup (sequential / parallel)"
  ) +
  theme_minimal()

ggsave(file.path(outdir, "speedup.png"), p2,
       width=8, height=5, dpi=150)

cat("Analysis complete. Results saved in:", outdir, "\n")