# apps/skill_assessment/modules/question_module.R

question_module_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("question_text")),
    
    selectInput(
      ns("score"),
      label = "Select your self-assessed skill level:",
      choices = c(
        "1 - Never used / no experience" = 1,
        "2 - Rarely (once or twice)" = 2,
        "3 - Occasionally (3–5 times)" = 3,
        "4 - Frequently (monthly or more)" = 4,
        "5 - Expert / daily use" = 5
      ),
      selected = NULL
    ),
    
    textAreaInput(
      ns("comment"),
      "Optional: Describe how you've applied this skill (if applicable)",
      "",
      rows = 3
    ),
    
    actionButton(ns("next_btn"), "Next")
  )
}

question_module_server <- function(id, question, response_store) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    output$question_text <- renderUI({
      h4(question$text)
    })
    
    observeEvent(input$next_btn, {
      if (is.null(input$score) || input$score == "") {
        showModal(modalDialog(
          title = "Please Select a Score",
          "You must select a skill level before continuing.",
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
      
      response <- list(
        id = question$id,
        area = question$area,
        text = question$text,
        score = as.integer(input$score),
        comment = input$comment,
        timestamp = Sys.time()
      )
      
      response_store$answers[[response_store$current]] <- response
      response_store$current <- response_store$current + 1
    })
  })
}
