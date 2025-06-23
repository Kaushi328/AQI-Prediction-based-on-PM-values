# global.R

# Load necessary libraries (only once at app startup)
library(shiny)
library(randomForest)
library(ggplot2)
library(plotly)
library(shinyjs)

# Load your pre-trained Random Forest model
# Make sure 'aqi_prediction_model_tuned.rds' is in the same directory as your app files
final_rf_model <- readRDS("aqi_prediction_model_tuned.rds")

# Define AQI categories and their properties
# --- FIX IS HERE: lower_bound and upper_bound vectors now have 7 elements each ---
aqi_categories <- data.frame(
  category = c("Good", "Moderate", "Slightly Unhealthy", "Unhealthy", "Very Unhealthy", "Hazardous", "Beyond AQI"),
  lower_bound = c(0, 51, 101, 151, 201, 301, 501), # Corrected: 7 elements
  upper_bound = c(50, 100, 150, 200, 300, 500, Inf), # Corrected: 7 elements
  color = c(
    "#4CAF50", "#FFC107", "#FF9800", "#F44336", "#9C27B0", "#673AB7", "#212121"
  )
)

# Define training data ranges (for input guidance)
# IMPORTANT: Replace these with the actual min/max values from your training data!
pm25_min_train <- 0
pm25_max_train <- 90  # Example max
pm10_min_train <- 0
pm10_max_train <- 150 # Example max

# Calculate Feature Importance (assuming your model has importance data)
# This will be used for the new Feature Importance plot
# Ensure your randomForest model was trained with 'importance = TRUE'
if (!is.null(final_rf_model$importance)) {
  feature_importance_data <- data.frame(
    Feature = rownames(importance(final_rf_model)),
    Importance = importance(final_rf_model)[, "IncNodePurity"] # Or '%IncMSE' depending on what you prefer
  )
  # Sort by importance
  feature_importance_data <- feature_importance_data[order(-feature_importance_data$Importance), ]
  # Factor for plotting order
  feature_importance_data$Feature <- factor(feature_importance_data$Feature,
                                            levels = feature_importance_data$Feature)
} else {
  feature_importance_data <- NULL
  warning("Feature importance not available in the model. Ensure model was trained with importance=TRUE.")
}