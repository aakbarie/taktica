
library(arrow)
library(tibble)
library(dplyr)
library(purrr)
library(jsonlite)


questions <- list(
  list(
    id = "q1",
    area = "Programming",
    text = "In the past 6 months, how often have you written production-level Python code?",
    cognitive_objective = "Apply",
    leadership_tag = "Autonomy",
    leverage = "Foundational",
    llm_tags = c("python", "production", "code_quality")
  ),
  list(
    id = "q2",
    area = "Programming",
    text = "How confident are you writing efficient and maintainable R code for analysis or modeling?",
    cognitive_objective = "Synthesize",
    leadership_tag = "Craftsmanship",
    leverage = "Gateway",
    llm_tags = c("r", "readability", "best_practices")
  ),
  list(
    id = "q3",
    area = "Data Management",
    text = "How often have you cleaned and transformed large datasets (100k+ rows)?",
    cognitive_objective = "Apply",
    leadership_tag = "Rigor",
    leverage = "Foundational",
    llm_tags = c("data_wrangling", "etl", "large_scale")
  ),
  list(
    id = "q4",
    area = "Data Management",
    text = "How familiar are you with working with Parquet, DuckDB, or Arrow for data storage and retrieval?",
    cognitive_objective = "Understand",
    leadership_tag = "Systems Thinking",
    leverage = "Compound",
    llm_tags = c("arrow", "duckdb", "parquet", "efficiency")
  ),
  list(
    id = "q5",
    area = "SQL & Querying",
    text = "How confident are you writing complex SQL queries with joins, subqueries, and window functions?",
    cognitive_objective = "Apply",
    leadership_tag = "Precision",
    leverage = "Gateway",
    llm_tags = c("sql", "data_access", "relational_thinking")
  ),
  list(
    id = "q6",
    area = "Version Control",
    text = "How often do you use Git or a similar tool to manage code and collaborate with others?",
    cognitive_objective = "Apply",
    leadership_tag = "Team Readiness",
    leverage = "Foundational",
    llm_tags = c("git", "collaboration", "workflow")
  ),
  list(
    id = "q7",
    area = "Modeling - Predictive",
    text = "How often have you developed supervised ML models using packages like scikit-learn, tidymodels, or caret?",
    cognitive_objective = "Create",
    leadership_tag = "Innovation",
    leverage = "Compound",
    llm_tags = c("supervised_learning", "model_building", "tidymodels")
  ),
  list(
    id = "q8",
    area = "Modeling - Advanced",
    text = "How comfortable are you applying causal inference or quasi-experimental methods like DiD or PSM?",
    cognitive_objective = "Evaluate",
    leadership_tag = "Analytical Depth",
    leverage = "Strategic",
    llm_tags = c("causal_inference", "psm", "did", "policy")
  ),
  list(
    id = "q9",
    area = "Model Ops",
    text = "Have you deployed any ML models as APIs or with tools like vetiver, Flask, or FastAPI?",
    cognitive_objective = "Apply",
    leadership_tag = "Delivery",
    leverage = "Gateway",
    llm_tags = c("deployment", "vetiver", "fastapi", "ops")
  ),
  list(
    id = "q10",
    area = "Model Monitoring",
    text = "Have you implemented monitoring or alerting for model performance, drift, or data quality?",
    cognitive_objective = "Evaluate",
    leadership_tag = "Stewardship",
    leverage = "Compound",
    llm_tags = c("monitoring", "drift", "alerting", "data_quality")
  ),
  list(
    id = "q11",
    area = "Visualization",
    text = "How skilled are you in creating compelling data visualizations using ggplot, matplotlib, or Plotly?",
    cognitive_objective = "Create",
    leadership_tag = "Communication",
    leverage = "Foundational",
    llm_tags = c("data_viz", "plotly", "ggplot", "storytelling")
  ),
  list(
    id = "q12",
    area = "Dashboards",
    text = "How frequently have you built interactive dashboards using Shiny or Streamlit?",
    cognitive_objective = "Apply",
    leadership_tag = "User Empathy",
    leverage = "Gateway",
    llm_tags = c("shiny", "streamlit", "dashboard", "ux")
  ),
  list(
    id = "q13",
    area = "Storytelling",
    text = "How confident are you in communicating data insights to non-technical stakeholders?",
    cognitive_objective = "Communicate",
    leadership_tag = "Translation",
    leverage = "Strategic",
    llm_tags = c("data_communication", "business_translation", "insight_delivery")
  ),
  list(
    id = "q14",
    area = "Strategic Framing",
    text = "How often do you participate in defining business problems before modeling begins?",
    cognitive_objective = "Synthesize",
    leadership_tag = "Strategic Alignment",
    leverage = "Compound",
    llm_tags = c("problem_scoping", "alignment", "pre_modeling")
  ),
  list(
    id = "q15",
    area = "Ethics & Fairness",
    text = "How familiar are you with AI fairness, bias detection, or explainability tools?",
    cognitive_objective = "Understand",
    leadership_tag = "Ethics",
    leverage = "Strategic",
    llm_tags = c("fairness", "xai", "bias", "trust")
  ),
  list(
    id = "q16",
    area = "Governance",
    text = "Have you worked on any models or workflows that follow AI governance or compliance frameworks?",
    cognitive_objective = "Apply",
    leadership_tag = "Responsibility",
    leverage = "Strategic",
    llm_tags = c("governance", "compliance", "responsible_ai")
  ),
  list(
    id = "q17",
    area = "Team Collaboration",
    text = "How frequently do you collaborate with cross-functional teams (e.g., product, compliance, IT)?",
    cognitive_objective = "Collaborate",
    leadership_tag = "Relational Intelligence",
    leverage = "Foundational",
    llm_tags = c("collaboration", "communication", "teamwork")
  ),
  list(
    id = "q18",
    area = "Documentation",
    text = "How often do you produce clean documentation for models, analyses, or code?",
    cognitive_objective = "Organize",
    leadership_tag = "Discipline",
    leverage = "Gateway",
    llm_tags = c("documentation", "reproducibility", "handoff")
  ),
  list(
    id = "q19",
    area = "Tools & Infra",
    text = "How comfortable are you using tools like Docker, conda environments, or Posit Workbench?",
    cognitive_objective = "Apply",
    leadership_tag = "Operational Readiness",
    leverage = "Compound",
    llm_tags = c("docker", "environment", "infra", "workflow")
  ),
  list(
    id = "q20",
    area = "Learning & Growth",
    text = "In the last 6 months, how actively have you pursued learning new data science topics or tools?",
    cognitive_objective = "Reflect",
    leadership_tag = "Growth Mindset",
    leverage = "Catalyst",
    llm_tags = c("learning", "upskilling", "mindset", "evolution")
  )
)

# Convert your list of questions to a data frame with JSON-safe strings
questions_df <- map_dfr(questions, function(q) {
  tibble(
    id = q$id,
    area = q$area,
    text = q$text,
    cognitive_objective = q$cognitive_objective,
    leadership_tag = q$leadership_tag,
    leverage = q$leverage,
    llm_tags = paste(q$llm_tags, collapse = ",")  # Save as a comma-separated string
  )
})

# Create folder if it doesn't exist
dir.create("data/reference", recursive = TRUE, showWarnings = FALSE)

# Save as Parquet
write_parquet(questions_df, "data/reference/skill_assessment_questions.parquet")
