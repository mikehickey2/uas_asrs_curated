# Tests for Wilson confidence interval calculations
# Tests: CI bounds are valid (0-1 range, lower < upper, etc.)

library(binom)

# =============================================================================
# Wilson CI bounds tests
# =============================================================================

test_that("Wilson CI returns values in [0, 1] range", {
  test_cases <- list(
    list(x = 23, n = 50),
    list(x = 0, n = 50),
    list(x = 50, n = 50),
    list(x = 1, n = 100),
    list(x = 5, n = 10)
  )

  for (tc in test_cases) {
    ci <- binom.confint(tc$x, tc$n, methods = "wilson")
    expect_true(ci$lower >= 0 - 1e-10, label = paste("lower for x =", tc$x))
    expect_true(ci$upper <= 1 + 1e-10, label = paste("upper for x =", tc$x))
  }
})

test_that("Wilson CI lower bound <= point estimate <= upper bound", {
  test_cases <- list(
    list(x = 23, n = 50),
    list(x = 10, n = 100),
    list(x = 3, n = 15)
  )

  for (tc in test_cases) {
    ci <- binom.confint(tc$x, tc$n, methods = "wilson")
    expect_lte(ci$lower, ci$mean, label = paste("lower for x =", tc$x))
    expect_lte(ci$mean, ci$upper, label = paste("upper for x =", tc$x))
  }
})

test_that("Wilson CI for x=0 has lower bound of 0", {
  ci <- binom.confint(0, 50, methods = "wilson")
  expect_equal(ci$lower, 0)
  expect_gt(ci$upper, 0)
})

test_that("Wilson CI for x=n has upper bound of 1", {
  ci <- binom.confint(50, 50, methods = "wilson")
  expect_equal(ci$upper, 1)
  expect_lt(ci$lower, 1)
})

test_that("Wilson CI width decreases with larger sample size", {
  ci_small <- binom.confint(5, 10, methods = "wilson")
  ci_large <- binom.confint(50, 100, methods = "wilson")

  width_small <- ci_small$upper - ci_small$lower
  width_large <- ci_large$upper - ci_large$lower

  expect_lt(width_large, width_small)
})

test_that("Wilson CI point estimate equals x/n", {
  ci <- binom.confint(23, 50, methods = "wilson")
  expect_equal(ci$mean, 23 / 50)
})
