
load_user_history <- function(user_id) {
  files <- list.files("/ai/aesfahani/projects/InsightHub/apps/skill_assessment/data/assessments", full.names = TRUE, pattern = "\\.parquet$")
  df_all <- purrr::map_dfr(files, function(f) {
    tryCatch(read_parquet(f), error = function(e) NULL)
  })
  df_user <- dplyr::filter(df_all, user_id == !!user_id)
  return(df_user)
}

baseline_vector <- c(
  "Strategic Framing" = 4,
  "Ethics & Fairness" = 4,
  "Governance" = 4,
  "Team Collaboration" = 4,
  "Documentation" = 3,
  "Tools & Infra" = 3,
  "Learning & Growth" = 5
)

generate_gap_plan <- function(user_id, user_name, user_position) {
  df <- load_user_history(user_id)
  
  if (nrow(df) == 0) return("No assessment data found for this user.")
  
  baseline_scores <- c(
    "Programming" = 4,
    "Data Management" = 4,
    "SQL & Querying" = 4,
    "Version Control" = 4,
    "Modeling - Predictive" = 4,
    "Modeling - Advanced" = 3,
    "Model Ops" = 3,
    "Model Monitoring" = 3,
    "Visualization" = 3,
    "Dashboards" = 3,
    "Storytelling" = 4,
    "Strategic Framing" = 4,
    "Ethics & Fairness" = 4,
    "Governance" = 4,
    "Team Collaboration" = 4,
    "Documentation" = 3,
    "Tools & Infra" = 3,
    "Learning & Growth" = 5
  )
  
  summary_df <- df %>%
    dplyr::group_by(area) %>%
    dplyr::summarise(
      avg_score = round(mean(score), 2),
      questions = paste0("  - ", paste(unique(text), collapse = "\n  - ")),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      expected_score = baseline_scores[area],
      gap = round(expected_score - avg_score, 2)
    ) %>%
    dplyr::arrange(desc(gap))
  
  assessment_summary <- paste0(
    "User: ", user_name, " ", user_position, "\n\n",
    paste(apply(summary_df, 1, function(row) {
      paste0(
        "### Area: ", row["area"], "\n",
        "- Average Score: ", row["avg_score"], "\n",
        "- Expected Score: ", row["expected_score"], "\n",
        "- Gap: ", row["gap"], "\n",
        "- Questions:\n", row["questions"], "\n"
      )
    }), collapse = "\n\n")
  )
  
  prompt <- paste(
    "You are a senior AI mentor and career development strategist.",
    "Based on this user's skill self-assessment, do the following:",
    "1. Rank the areas by priority for learning based on gap size and expected level.",
    "2. For each area, suggest specific resources: books, articles, projects, or mentoring approaches.",
    "3. Output a structured learning plan in Markdown with sections per skill area.",
    "4. Include a top 3 priorities section at the end with rationale.",
    "\n\n",
    assessment_summary
  )
  
  message("🧠 Prompt to LLM:\n", substr(prompt, 1, 500), "...")
  
  result <- tryCatch({
    llm_custom(
      data.frame(dummy = "placeholder"),  # dummy .tbl as required
      "dummy",                            # input_col name
      prompt = prompt                     # feed the full prompt here
    )
  }, error = function(e) {
    message("❌ LLM error: ", e$message)
    return(list(.pred = "⚠️ LLM generation failed."))
  })
  
  return(result$.pred[1])
}

