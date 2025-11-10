

file_path <- '/Users/gethinwade/Documents/Columbia/5205 - Linear Regression/Project/project_data.csv'
df <- read.csv(file_path, header=TRUE)
head(df)
# str(df)

df$has_garage_label <- factor(df$has_garage, 
                               levels = c(0, 1),
                               labels = c("No Garage", "Has Garage"))

stripchart(inspections ~ has_garage_label, vertical=TRUE, method='jitter', pch=16,
           data = df,
           main = "Rat Inspections by Garage Presence",
           xlab = "Garage Status",
           ylab = "Number of Inspections")

df$has_dropoff_label <- factor(df$has_dropoff, 
                               levels = c(0, 1),
                               labels = c("No Dropoff", "Has Dropoff"))

stripchart(inspections ~ has_dropoff_label, vertical=TRUE, method='jitter', pch=16,
           data = df,
           main = "Rat Inspections by Dropoff Presence",
           xlab = "Dropoff Status",
           ylab = "Number of Inspections")

# Simple Linear Regression
model <- lm(inspections ~ population, data=df)
summary(model)

plot(df$population, df$inspections, xlab='Population', ylab='Rat Inspections', 
     main='Population vs. Rat Inspections by Zip Code')
abline(model, col='red')

# Full regression model
full_model <- lm(inspections ~ population + has_garage + has_dropoff, data=df)
summary(full_model)