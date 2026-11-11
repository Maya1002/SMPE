#!/usr/bin/env Rscript

if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is missing. Install it with: sudo apt install r-cran-ggplot2")
library(ggplot2)

# 95% confidence interval for the mean
mean_ci <- function(x) {
  n <- length(x)
  mean_x <- mean(x)
  sd_x <- sd(x)
  error <- qt(0.975, df = n - 1) * sd_x / sqrt(n)
  c(low = mean_x - error, high = mean_x + error)
}

# Input CSV
args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args) >= 1) args[1] else "data/benchmark_20261111_180819.csv"

if (!file.exists(input)) stop("CSV file not found: ", input)

outdir <- "data/analysis"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

df <- read.csv(input)

# Check required columns
required <- c("repetition", "size", "thread_level", "sequential_sec", "parallel_sec", "libc_sec")
if (!all(required %in% names(df))) stop("Missing required columns in CSV.")

# Check data validity
numeric_columns <- c("repetition", "size", "thread_level", "sequential_sec", "parallel_sec", "libc_sec")
if (any(!is.finite(as.matrix(df[numeric_columns])))) stop("Invalid values in CSV.")

time_columns <- c("sequential_sec", "parallel_sec", "libc_sec")
if (any(df[, time_columns] <= 0)) stop("Execution times must be positive.")

# Unique sizes and thread levels
sizes <- sort(unique(df$size))
thread_levels <- sort(unique(df$thread_level))

cat("Sizes:", paste(sizes, collapse = ", "), "\n")
cat("THREAD_LEVELS:", paste(thread_levels, collapse = ", "), "\n")

# 1. Execution time statistics
stats_list <- list()
k <- 1

for (s in sizes) {
  for (tl in thread_levels) {
    d <- df[df$size == s & df$thread_level == tl, ]

    seq_ci <- mean_ci(d$sequential_sec)
    par_ci <- mean_ci(d$parallel_sec)
    libc_ci <- mean_ci(d$libc_sec)

    stats_list[[k]] <- data.frame(
      size = s, thread_level = tl,
      sequential_sec = mean(d$sequential_sec), sequential_sd = sd(d$sequential_sec),
      sequential_low = seq_ci["low"], sequential_high = seq_ci["high"],
      parallel_sec = mean(d$parallel_sec), parallel_sd = sd(d$parallel_sec),
      parallel_low = par_ci["low"], parallel_high = par_ci["high"],
      libc_sec = mean(d$libc_sec), libc_sd = sd(d$libc_sec),
      libc_low = libc_ci["low"], libc_high = libc_ci["high"]
    )

    k <- k + 1
  }
}

stats <- do.call(rbind, stats_list)

write.csv(stats, file.path(outdir, "statistiques_thread_level.csv"), row.names = FALSE)

# 2. Execution time graph
# Sequential and libc do not depend on THREAD_LEVEL, so we take their values from the first level.
reference_stats <- stats[stats$thread_level == min(thread_levels), ]

long_seq_libc <- rbind(
  data.frame(size = reference_stats$size, thread_level = reference_stats$thread_level, method = "Sequential", time = reference_stats$sequential_sec, low = reference_stats$sequential_low, high = reference_stats$sequential_high),
  data.frame(size = reference_stats$size, thread_level = reference_stats$thread_level, method = "qsort (libc)", time = reference_stats$libc_sec, low = reference_stats$libc_low, high = reference_stats$libc_high)
)

long_parallel <- data.frame(
  size = stats$size, thread_level = stats$thread_level,
  method = paste("Parallel TL", stats$thread_level),
  time = stats$parallel_sec, low = stats$parallel_low, high = stats$parallel_high
)

long_execution <- rbind(long_seq_libc, long_parallel)

p1 <- ggplot(long_execution, aes(x = size, y = time, color = method)) +
  geom_line() +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.05) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Sorting Execution Times by THREAD_LEVEL",
    x = "Array size (number of elements)",
    y = "Mean execution time (seconds)",
    color = "Algorithm / THREAD_LEVEL"
  ) +
  theme_minimal()

ggsave(file.path(outdir, "execution_times_thread_levels.png"), p1, width = 10, height = 6, dpi = 150)

# 3. Parallel execution time by THREAD_LEVEL
parallel_stats <- stats

p_parallel <- ggplot(parallel_stats, aes(x = size, y = parallel_sec, color = factor(thread_level), group = thread_level)) +
  geom_line() +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = parallel_low, ymax = parallel_high), width = 0.05) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Parallel Quicksort by THREAD_LEVEL",
    x = "Array size (number of elements)",
    y = "Mean parallel execution time (seconds)",
    color = "THREAD_LEVEL"
  ) +
  theme_minimal()

ggsave(file.path(outdir, "parallel_thread_levels.png"), p_parallel, width = 9, height = 6, dpi = 150)

# 4. Speedup
df$speedup <- df$sequential_sec / df$parallel_sec

speedup_list <- list()
k <- 1

for (s in sizes) {
  for (tl in thread_levels) {
    d <- df[df$size == s & df$thread_level == tl, ]
    ci <- mean_ci(d$speedup)

    speedup_list[[k]] <- data.frame(
      size = s, thread_level = tl,
      speedup = mean(d$speedup), sd = sd(d$speedup),
      low = ci["low"], high = ci["high"]
    )

    k <- k + 1
  }
}

speedup <- do.call(rbind, speedup_list)

write.csv(speedup, file.path(outdir, "speedup_thread_levels.csv"), row.names = FALSE)

# 5. Speedup graph
p2 <- ggplot(speedup, aes(x = size, y = speedup, color = factor(thread_level), group = thread_level)) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  geom_line() +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = low, ymax = high), width = 0.05) +
  scale_x_log10() +
  labs(
    title = "Parallel Quicksort Speedup by THREAD_LEVEL",
    x = "Array size (number of elements)",
    y = "Mean speedup (sequential / parallel)",
    color = "THREAD_LEVEL"
  ) +
  theme_minimal()

ggsave(file.path(outdir, "speedup_thread_levels.png"), p2, width = 9, height = 6, dpi = 150)

# 6. Best THREAD_LEVEL for each size
best_levels <- do.call(
  rbind,
  lapply(sizes, function(s) {
    d <- speedup[speedup$size == s, ]
    best <- d[which.max(d$speedup), ]

    data.frame(
      size = s,
      best_thread_level = best$thread_level,
      speedup = best$speedup,
      ci_low = best$low,
      ci_high = best$high
    )
  })
)

write.csv(best_levels, file.path(outdir, "best_thread_level.csv"), row.names = FALSE)

# Final message
cat("\n")
cat("============================================\n")
cat("Analysis complete.\n")
cat("============================================\n")
cat("Input : ", input, "\n")
cat("Output: ", outdir, "\n")
cat("THREAD_LEVELS: ", paste(thread_levels, collapse = ", "), "\n")
cat("\n")