#
# Install app:
#  ssh ken@oceanlife.dtuaqua.dk
#  update the git
#  cp to /srv/shiny-server/Plankton
#  If using new packages install them by running R as root
# sudo systemctl restart shiny-server
#

library(shiny)
options(shiny.sanitize.errors = FALSE)

source("modelWatercolumn.R")

# ===================================================
# Define UI for application
# ===================================================

uiWatercolumn <- fluidPage(
  # tags$head(
  #   # Add google analytics tracking:
  #   includeHTML(("googleanalytics.html")),
  #   # Make rules widers:
  #   tags$style(HTML("hr {border-top: 1px solid #000000;}"))
  # )
  #,
  h1('Size-based water column plankton simulator'),
  p('Simulate a plankton ecosystem in a watercolumn. 
    Cell size is the only trait characterizing each plankton group.
    All groups are able to perform photoharvesting, taking up dissolve nutrients and carbon, and do phagotrophy.
    The trophic strategy is an emergent property.'),
  p('THIS IS WORK IN PROGRESS. Version 0.1. January 2020.')
  ,
  # Sidebar with a slider inputs
  sidebarLayout(
    sidebarPanel(
      sliderInput("Lsurface",
                  "Surface light (PAR; uE/m2/s)",
                  min = 0,
                  max = 300,
                  step=1,
                  value = parametersWatercolumn()$Lsurface)
      ,
      sliderInput("diff",
                  "Diffusion (m2/day)",
                  min = 0,
                  max = 100,
                  step = 1,
                  value = 1)
      ,
      sliderInput("T",
                  "Temperature",
                  min = 0,
                  max = 25,
                  step = 0.5,
                  value = 10)
      ,
      sliderInput("N0",
                  "Bottom nutrient concentration",
                  min = 0,
                  max = 200,
                  step=1,
                  value = 150)
      ,
      hr()
      ,
      sliderInput("mortHTL",
                  "Mortality by higher trophic levels on the largest sizes (1/day)",
                  min = 0,
                  max = 0.5,
                  step = 0.01,
                  value = 0.05)
      ,
      sliderInput("mort2",
                  "Quadratic mortality coef. (virulysis; 1/day/mugC)",
                  min = 0,
                  max = 0.001,
                  step = 0.00001,
                  value = 0.0002)
      ,
      sliderInput("epsilon_r",
                  "Remineralisation of virulysis and HTL losses",
                  min = 0,
                  max = 1,
                  value = 0,
                  step = 0.1)
    ),
    #
    # Show plots:
    #
    mainPanel(
      #
      # Main output panel
      #
      tabsetPanel(
        tabPanel(
          "Main output",
          plotOutput("plotWatercolumn", width="600px", height="300px"),
          plotOutput("plotFunction", width="600px")
          #plotOutput("plotSpectrum", width="600px", height="300px"),
          #plotOutput("plotRates", width="600px", height="300px"),
          #plotOutput("plotLeaks", width="600px", height="200px")
        )
        ,
        tabPanel(
          "Timeline",
          plotOutput("plotWatercolumnTime", width="600px")
        )
        #,
        #tabPanel(
        #  "Dynamics",
          # conditionalPanel(
          #   condition="input.latitude>0",
          #   plotOutput("plotSeasonalTimeline", width="600px")
          # ),
          # plotOutput("plotTime", width="600px")#,
          # #plotOutput("plotComplexRates", width="700px")
        #)
      )
    )))
#
# Define server logic
#
serverWatercolumn <- function(input, output) {
  #
  # Simulate the system when a parameter is changed:
  #
  sim <- eventReactive({
    input$Lsurface
    input$diff
    input$T
    input$N0
    input$mort2
    input$mortHTL
    input$epsilon_r
  },
  {
    # get all base parameters
    p <- parametersWatercolumn() 
    # Update parameters with user input:
    p$Lsurface = input$Lsurface
    p$diff = input$diff
    p$T = input$T
    p$N0 = input$N0
    p$mort2 = input$mort2*p$n
    p$mortHTL = input$mortHTL
    p$remin = input$epsilon_r
    
    # Simulate
    return(simulateWatercolumn(p))
  })
  #
  # Plots:
  #
  #output$plotSpectrum <- renderPlot(plotSpectrum(sim(), input$t))
  #output$plotRates <- renderPlot(plotRates(sim(), input$t))
  #output$plotLeaks = renderPlot(plotLeaks(sim(), input$t))
  #output$plotComplexRates <- renderPlot(plotComplexRates(sim(), input$t))
  output$plotWatercolumn <- renderPlot(plotWatercolumn(sim()))
  output$plotWatercolumnTime <- renderPlot(plotWatercolumnTime(sim()))
  #output$plotSeasonalTimeline <- renderPlot(plotSeasonalTimeline(sim()))
  output$plotFunction <- renderPlot(plotFunctionsWatercolumn(sim()))
  #output$plotSeasonal <- renderPlot(plotSeasonal(p, input$t))
}

# Compile C code:
#if (system2("g++", "-O3 -shared ../Cpp/model.cpp -o ../Cpp/model.so")==0)  {
#  bUseC = TRUE
#  cat("Using C engine\n")
#}
# Run the application 
shinyApp(ui = uiWatercolumn, server = serverWatercolumn)
