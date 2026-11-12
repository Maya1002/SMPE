#!/usr/bin/env Rscript
library(ggplot2)

#!/usr/bin/env Rscript
library(ggplot2)

# 95% confidence interval for the mean
mean_ci <- function(x) {
  n <- length(x)
  mean_x <- mean(x)
  sd_x <- sd(x)
  error <- 1.96 * sd_x / sqrt(n)
  c(low = mean_x - error, high = mean_x + error)
}

# Input CSV
args <- commandArgs(trailingOnly = TRUE)
input <- args[1]

outdir <- "data/analysis"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

df <- read.csv(input)

# Unique sizes and thread levels
sizes <- sort(unique(df$size))
thread_levels <- sort(unique(df$thread_level))

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

#Parallel execution time by THREAD_LEVEL
p_parallel <- ggplot(stats, aes(x = size, y = parallel_sec, color = factor(thread_level), group = thread_level)) +
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

#Speedup
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

# Speedup graph
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

cat("Analyse terminée.\n")