# apps/skill_assessment/logic/save_assessment.R

save_assessment_parquet <- function(responses, user_id = "anonymous", user_name = NULL, user_position = NULL, version = "v1") {
  library(arrow)
  library(dplyr)
  library(uuid)
  
  cycle_id <- UUIDgenerate()
  timestamp <- Sys.time()
  
  df <- bind_rows(responses) %>%
    mutate(
      user_id = user_id,
      user_name = user_name,
      user_position = user_position,
      version = version,
      cycle_id = cycle_id,
      timestamp = timestamp
    )
  
  dir.create("data/assessments", recursive = TRUE, showWarnings = FALSE)
  file_name <- paste0("data/assessments/", user_id, "_", format(timestamp, "%Y%m%d_%H%M%S"), ".parquet")
  write_parquet(df, file_name)
  
  return(invisible(df))
}
