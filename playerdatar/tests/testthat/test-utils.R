test_that("parseQueryString returns empty list for null or empty input", {
  expect_equal(playerdatar:::parseQueryString(NULL), list())
  expect_equal(playerdatar:::parseQueryString(""), list())
})

test_that("parseQueryString decodes a simple query string", {
  result <- playerdatar:::parseQueryString("code=abc&state=xyz")
  expect_equal(result$code, "abc")
  expect_equal(result$state, "xyz")
})

test_that("parseQueryString URL-decodes values", {
  result <- playerdatar:::parseQueryString("redirect=https%3A%2F%2Fexample.com%2Fcb")
  expect_equal(result$redirect, "https://example.com/cb")
})
