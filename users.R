library(tibble)
library(arrow)

users <- tribble(
  ~user_id,        ~name,             ~position,
  "aesfahani",     "Akbar Esfahani",  "Manager, Advanced Analytics",
  "shiraoka",      "Steve Hiraoka",   "Data Scientist 4"
)

dir.create("data/reference", showWarnings = FALSE, recursive = TRUE)
write_parquet(users, "data/reference/users.parquet")
