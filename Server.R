# server.R

# Libraries and data are now loaded via global.R
# No need to load libraries or model/aqi_categories here again
# library(shiny)
# library(randomForest)
# library(ggplot2)
# library(plotly)
# library(shinyjs)
# final_rf_model <- readRDS("aqi_prediction_model_tuned.rds")
# aqi_categories <- data.frame(...) # Removed
# pm25_max_train <- 90 # Removed
# pm10_max_train <- 150 # Removed


server <- function(input, output) {

  # --- NEW: Reset Button Logic ---
  observeEvent(input$reset_button, {
    shinyjs::reset("pm25_input") # Resets numeric input to its default value
    shinyjs::reset("pm10_input")

    # Hide all output areas
    shinyjs::hide(id = "prediction_result_area")
    shinyjs::hide(id = "aqi_scale_plot_area")
    shinyjs::hide(id = "aqi_comparison_plot_area")
    shinyjs::hide(id = "importance_plot_area") # Hide feature importance plot too

    # Clear previous output text
    output$prediction_output <- renderUI(HTML(""))
    # Clear plots by setting them to NULL or an empty plot if needed,
    # but hiding the div is often sufficient.
    output$aqi_scale_plot <- renderPlotly(NULL)
    output$aqi_comparison_plot <- renderPlotly(NULL)
    output$importance_plot <- renderPlotly(NULL)
  })


  observeEvent(input$predict_button, {
    # Hide all output areas and show loading spinner immediately
    shinyjs::hide(id = "prediction_result_area")
    shinyjs::hide(id = "aqi_scale_plot_area")
    shinyjs::hide(id = "aqi_comparison_plot_area")
    shinyjs::hide(id = "importance_plot_area") # Hide importance plot at start
    shinyjs::show(id = "loading_spinner") # Show spinner

    # Ensure to capture values *after* potential reset if it happens very fast
    pm25_value <- input$pm25_input
    pm10_value <- input$pm10_input

    display_text <- ""
    aqi_plot_render <- NULL
    aqi_comparison_plot_render <- NULL
    importance_plot_render <- NULL # NEW: For feature importance plot

    # Input validation (remains the same)
    if (pm25_value < 0 || pm10_value < 0) {
      display_text <- "<p style='color:orange; font-weight:bold;'>Error: Please enter non-negative PM2.5 and PM10 values.</p>"
    } else {
      new_data <- data.frame(PM2.5 = as.numeric(pm25_value), PM10 = as.numeric(pm10_value))
      predicted_aqi <- predict(final_rf_model, newdata = new_data)
      predicted_aqi <- round(predicted_aqi, 2)

      aqi_category <- "Unknown"
      aqi_color_for_plot <- "gray"
      styled_aqi_category_text <- ""

      for (i in 1:nrow(aqi_categories)) {
        if (predicted_aqi >= aqi_categories$lower_bound[i] && predicted_aqi <= aqi_categories$upper_bound[i]) {
          aqi_category <- as.character(aqi_categories$category[i])
          aqi_color_for_plot <- as.character(aqi_categories$color[i])
          styled_aqi_category_text <- paste0(
            "<span style='color:", aqi_color_for_plot, "; font-weight:bold; font-size: 1.1em;'>",
            aqi_category,
            "</span>"
          )
          break
        }
      }

      display_text <- paste0(
        "Predicted AQI: <b>", predicted_aqi, "</b><br>",
        "Air Quality: ", styled_aqi_category_text
      )

      if (pm25_value > pm25_max_train || pm10_value > pm10_max_train) {
        warning_message <- paste(
          "<p class='warning-message' style='margin-top: 10px;'>Warning: Input values (PM2.5 >", pm25_max_train,
          "or PM10 >", pm10_max_train, ") are higher than the range the model was trained on.",
          "The prediction may be less reliable.</p>"
        )
        display_text <- paste0(display_text, warning_message)
      }

      # --- Generate the existing AQI Scale Plot ---
      plot_data_marker <- data.frame(AQI = predicted_aqi)
      max_y_limit_scale_plot <- max(500, predicted_aqi * 1.1)

      p_scale_plot <- ggplot() +
        geom_segment(data = aqi_categories,
                     aes(x = 0, xend = 1, y = lower_bound + (upper_bound - lower_bound) / 2,
                         yend = lower_bound + (upper_bound - lower_bound) / 2,
                         color = category,
                         text = paste("Category: ", category, "<br>Range: ", lower_bound, "-", upper_bound)),
                     linewidth = 10, lineend = "round") +
        geom_point(data = plot_data_marker, aes(x = 0.5, y = AQI,
                                                text = paste("Predicted AQI:", predicted_aqi, "<br>Category:", aqi_category)),
                   size = 8, shape = 21, fill = aqi_color_for_plot, color = "black", stroke = 1.5) +
        geom_text(data = plot_data_marker, aes(x = 0.5, y = AQI, label = round(AQI, 0)),
                  vjust = -1.5, size = 4, fontface = "bold", family = "Arial") +
        scale_color_manual(values = setNames(aqi_categories$color, aqi_categories$category),
                           name = "AQI Category", breaks = aqi_categories$category) +
        xlim(0, 1) +
        ylim(0, max_y_limit_scale_plot) +
        labs(title = "Predicted AQI Level on Scale") +
        theme_minimal() +
        theme(
          axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          axis.title.y = element_blank(), axis.text.y = element_text(size = 9, family = "Verdana"),
          axis.ticks.y = element_line(), legend.position = "bottom", legend.title = element_blank(),
          legend.text = element_text(family = "Times New Roman", size = 10),
          panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank(), panel.grid.minor.y = element_blank(),
          plot.title = element_text(hjust = 0.5, size = 14, face = "bold", family = "Georgia", color = "#333333"),
          text = element_text(family = "sans-serif")
        )

      aqi_plot_render <- ggplotly(p_scale_plot, tooltip = "text") %>%
        layout(yaxis = list(zeroline = FALSE), xaxis = list(showgrid = FALSE))

      # --- Generate the Comparison Bar Chart ---
      predicted_category_info <- aqi_categories[aqi_categories$category == aqi_category, ]
      current_category_min_aqi <- predicted_category_info$lower_bound
      current_category_max_aqi <- predicted_category_info$upper_bound

      comparison_data <- data.frame(
        Type = factor(c("Predicted AQI", "Category Min", "Category Max"),
                      levels = c("Predicted AQI", "Category Min", "Category Max")),
        Value = c(predicted_aqi, current_category_min_aqi, current_category_max_aqi),
        BarColor = c(aqi_color_for_plot, "darkgrey", "lightgrey")
      )

      if (is.infinite(current_category_max_aqi)) {
          comparison_data$Value[comparison_data$Type == "Category Max"] <- max(500, predicted_aqi * 1.1)
          comparison_data$Label_Text[comparison_data$Type == "Category Max"] <- paste0("Max: >500")
      } else {
          comparison_data$Label_Text = c(paste0("Predicted: ", round(predicted_aqi, 0)),
                                         paste0("Min: ", round(current_category_min_aqi, 0)),
                                         paste0("Max: ", round(current_category_max_aqi, 0)))
      }

      p_comparison <- ggplot(comparison_data, aes(x = Type, y = Value, fill = BarColor, text = Label_Text)) +
        geom_col(width = 0.6) +
        scale_fill_identity() +
        geom_text(aes(label = round(Value, 0)), vjust = -0.5, size = 4, fontface = "bold", family = "Arial") +
        labs(title = "AQI Comparison: Predicted vs. Category Bounds",
             y = "AQI Value") +
        theme_minimal() +
        theme(
          legend.position = "none",
          axis.title.x = element_blank(),
          axis.text.x = element_text(size = 10, face = "bold", family = "Verdana", color = "#555555"),
          axis.title.y = element_text(size = 10, face = "bold", family = "Verdana", color = "#555555"),
          plot.title = element_text(hjust = 0.5, size = 14, face = "bold", family = "Georgia", color = "#333333"),
          text = element_text(family = "sans-serif")
        )

      aqi_comparison_plot_render <- ggplotly(p_comparison, tooltip = "text") %>%
        layout(yaxis = list(zeroline = FALSE), xaxis = list(showgrid = FALSE))

      # --- NEW: Generate Feature Importance Plot ---
      # This relies on feature_importance_data being available from global.R
      if (!is.null(feature_importance_data) && nrow(feature_importance_data) > 0) {
        p_importance <- ggplot(feature_importance_data, aes(x = Feature, y = Importance, fill = Feature,
                                                          text = paste0("Feature: ", Feature, "<br>Importance: ", round(Importance, 2)))) +
          geom_col() +
          labs(title = "Feature Importance in Random Forest Model",
               y = "Importance (IncNodePurity)") +
          theme_minimal() +
          theme(
            legend.position = "none",
            axis.title.x = element_blank(),
            axis.text.x = element_text(size = 10, face = "bold", family = "Verdana"),
            axis.title.y = element_text(size = 10, face = "bold", family = "Verdana"),
            plot.title = element_text(hjust = 0.5, size = 14, face = "bold", family = "Georgia", color = "#333333"),
            text = element_text(family = "sans-serif")
          )
        importance_plot_render <- ggplotly(p_importance, tooltip = "text")
      }
    } # End of else (valid input) block

    # --- Render all outputs ---
    output$prediction_output <- renderUI({
      HTML(display_text)
    })

    output$aqi_scale_plot <- renderPlotly({
      aqi_plot_render
    })

    output$aqi_comparison_plot <- renderPlotly({
      aqi_comparison_plot_render
    })

    output$importance_plot <- renderPlotly({ # NEW: Render importance plot
      importance_plot_render
    })

    # --- Hide loading spinner and show results with fade animation ---
    shinyjs::hide(id = "loading_spinner") # Hide spinner
    shinyjs::show(id = "prediction_result_area", anim = TRUE, animType = "fade", time = 1)
    shinyjs::show(id = "aqi_scale_plot_area", anim = TRUE, animType = "fade", time = 1)
    shinyjs::show(id = "aqi_comparison_plot_area", anim = TRUE, animType = "fade", time = 1)
    # Only show importance plot if data is available
    if (!is.null(feature_importance_data) && nrow(feature_importance_data) > 0) {
        shinyjs::show(id = "importance_plot_area", anim = TRUE, animType = "fade", time = 1)
    }

  }) # End of observeEvent
} # End of server function