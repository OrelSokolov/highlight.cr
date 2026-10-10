# Анализ данных
library(dplyr)
library(ggplot2)

users <- data.frame(
  name = c("Олег", "Anna", "Petr"),
  age = c(30L, 25L, NA),
  score = c(4.5, 3.9, Inf)
)

.Filter <- function(df, min_age = 18) {
  df |>
    filter(!is.na(age), age >= min_age) |>
    mutate(group = if_else(score > 4, "high", "low")) |>
    arrange(desc(score))
}

result <- users %>%
  group_by(name) %>%
  summarize(mean_score = mean(score, na.rm = TRUE), n = n()) %>%
  ungroup()

sprintf("итого: %d строк (%.2f%%)", nrow(result), 42.5)
sapply(users$age, function(x) x^2)
l <- list(a = 1:3, b = "text", c = TRUE, d = NULL)
m <- matrix(1:6, nrow = 2)
f <- function(x, y = 2, ...) x * y + ...
class(result); attr(l, "meta") <- "инфо"
if (any(result$n > 1) && !is.null(l$d)) print("да") else print("нет")
for (i in seq_along(l)) cat(i, "\n")
repeat { break }
