# ui.R

# Libraries are now loaded in global.R, but for development you might keep them
# library(shiny)
# library(plotly)
# library(shinyjs)

# Define max training ranges here for use in UI (these are also in global.R)
# You should define these in global.R and they will be available here
# For now, put them here for immediate testing.
# IMPORTANT: These must match global.R values.
pm25_max_train <- 90
pm10_max_train <- 150


navbarPage("AQI Prediction App", # Changed from fluidPage to navbarPage for tabs
  theme = "styles.css", # CSS theme applied here

  # --- Prediction Tab ---
  tabPanel("Prediction",
    useShinyjs(), # Initialize shinyjs

    sidebarLayout(
      sidebarPanel(
        h4("Enter Pollutant Values:"),
        numericInput("pm25_input", "PM2.5 Value (µg/m³):", value = 20),
        # Input Range Guidance
        span(paste0(" (Training range: ", pm25_min_train, " - ", pm25_max_train, " µg/m³)"),
             style = "font-size: 0.85em; color: #666; display: block; margin-top: -10px; margin-bottom: 5px;"),

        numericInput("pm10_input", "PM10 Value (µg/m³):", value = 40),
        # Input Range Guidance
        span(paste0(" (Training range: ", pm10_min_train, " - ", pm10_max_train, " µg/m³)"),
             style = "font-size: 0.85em; color: #666; display: block; margin-top: -10px; margin-bottom: 5px;"),

        actionButton("predict_button", "Predict AQI", class = "btn-primary"),
        actionButton("reset_button", "Clear All", class = "btn-secondary", style = "margin-top: 10px;") # Reset Button
      ),

      mainPanel(
        h3("Prediction Result:"),

        # --- Loading Spinner ---
        shinyjs::hidden(
          div(id = "loading_spinner",
              # Ensure 'loading.gif' is in your 'www' folder
              tags$img(src = "loading.gif", width = "50px", height = "50px", style = "display: block; margin: auto;"),
              p("Predicting AQI...", style = "text-align: center; color: #555; font-style: italic; margin-top: 5px;")
          )
        ),

        shinyjs::hidden(
          div(id = "prediction_result_area",
              uiOutput("prediction_output")
          )
        ),
        br(),
        shinyjs::hidden(
          div(id = "aqi_scale_plot_area",
              plotlyOutput("aqi_scale_plot", height = "150px")
          )
        ),
        br(),
        shinyjs::hidden(
          div(id = "aqi_comparison_plot_area",
              h4("AQI Comparison: Predicted vs. Category Bounds"),
              plotlyOutput("aqi_comparison_plot", height = "250px")
          )
        ),
        br(),
        # --- NEW: Feature Importance Plot Area ---
        shinyjs::hidden(
          div(id = "importance_plot_area",
              h4("Feature Importance (PM2.5 vs PM10)"),
              plotlyOutput("importance_plot", height = "250px")
          )
        )
      )
    )
  ), # End of Prediction Tab

  # --- About Tab ---
  tabPanel("About",
    fluidRow(
      column(10, offset = 1, # Center content slightly
        h3("About This Air Quality Index (AQI) Prediction App"),
        p("This application leverages a Machine Learning model to provide a real-time prediction of the Air Quality Index (AQI) based on user-inputted PM2.5 and PM10 concentrations.The most significant advantage of this is the elimination of manual calculation, which is often time-consuming and prone to human error. The app instantly processes PM2.5 and PM10 data using established AQI formulas, providing rapid and accurate predictions. This frees up valuable agency resources."),
        hr(), # Horizontal rule for separation

        h4("The Predictive Model"),
        p("The core of this application is a ", strong("Random Forest regression model"), ". This model was meticulously trained on a dataset of historical air quality measurements, specifically focusing on PM2.5 and PM10 concentrations and their corresponding AQI values, collected from National Building Research Organization for the time period between the years 2020 and 2024. The Random Forest algorithm is chosen for its robustness, ability to handle complex, non-linear relationships, and its strong predictive performance."),

        h4("AQI Categorization"),
        p("The predicted AQI value is categorized according to standard air quality classifications. These categories provide an intuitive understanding of the air quality level:"),
        tags$ul( # Unordered list
          tags$li(strong("Good (0-50):"), " Air quality is satisfactory, and air pollution poses little or no risk."),
          tags$li(strong("Moderate (51-100):"), " Air quality is acceptable; however, for some pollutants, there may be a moderate health concern for a very small number of people who are unusually sensitive to air pollution."),
          tags$li(strong("Slightly Unhealthy (101-150):"), " Members of sensitive groups may experience health effects. The general public is less likely to be affected."),
          tags$li(strong("Unhealthy (151-200):"), " Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects."),
          tags$li(strong("Very Unhealthy (201-300):"), " Health warnings of emergency conditions. The entire population is more likely to be affected."),
          tags$li(strong("Hazardous (301-500):"), " Health alert: everyone may experience more serious health effects."),
          tags$li(strong("Beyond AQI (>500):"), " Represents air quality conditions far exceeding hazardous levels, indicating extreme pollution.")
        ),

        h4("Data & Limitations"),
        p("The model's predictions are based on the patterns it learned from the 2020-2024 training data for the range of PM2.5 of 0 - 90 µg/m³ and  0 - 150 µg/m³ range of PM10 concentration. While effective within this context, predictions made with input values outside the training range (as indicated in the prediction tab) should be interpreted with caution, as the model has not encountered such conditions during its training phase."),
        p("The training data for this model was sourced from National Building Reasearch Organization - SriLanka."),
        p("This application serves as an illustrative tool for predictive modeling in air quality and should not be used for critical decision-making without expert validation."),
      )
    )
  ) # End of About Tab
) # End of navbarPage
