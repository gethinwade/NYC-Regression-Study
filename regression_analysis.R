library(gt)
library(dplyr)
library(tidyr)
library(corrplot)
library(car)
library(MASS)
library(lmtest)
library(ggplot2)

file_path <- 'project_data.csv'
df <- read.csv(file_path, header=TRUE)
head(df)
str(df)

df <- df %>%
  rename(pop = population, garage = has_garage, dropoff = has_dropoff,
     baskets = litter_basket_count, park_acres = total_park_acres
)

# ----- Summary Statistics of Continuous Variables ----- #
df %>%
  summarise(across(c(inspections, pop, baskets, park_acres),
     list(Median = median, Mean = mean, SD = sd, Min = min, Max = max))) %>%
  pivot_longer(everything(), names_to = c("Variable", "Statistic"),
     names_pattern = "(.+)_(\\w+)$", values_to = "Value") %>%
  pivot_wider(names_from = Statistic, values_from = Value) %>%
  gt() %>%
  tab_header(title = "Fig. 1: Descriptive Statistics") %>%
  fmt_number(columns = c(Median, Mean, SD, Min, Max), decimals = 2)

# ----- Exploratory Data Analysis ----- #
hist(df$inspections, main = "Fig. 2: Rat Inspections by Zip", 
     xlab = "Rat Inspections", ylab = "Frequency", breaks = 20) 

hist(df$pop, main = "Fig. 3: Population by Zip", 
     xlab = "Population", ylab = "Frequency", breaks = 20) 

plot(df$pop, df$inspections, xlab='Population', ylab='Rat Inspections', 
     main='Fig. 4: Population vs. Inspections by Zip')

plot(df$baskets, df$inspections, xlab='Litter Baskets', ylab='Rat Inspections', 
     main='Fig. 5: Litter Baskets vs. Inspections by Zip')

plot(df$park_acres, df$inspections, xlab='Park Acres', ylab='Rat Inspections', 
     main='Fig. 6: Park Acres vs. Inspections by Zip')

df$has_garage_label <- factor(df$garage, levels = c(0, 1),
     labels = c("No Garage", "Has Garage"))

stripchart(inspections ~ has_garage_label, vertical=TRUE, method='jitter', pch=16,
     data = df, main = "Fig. 7: Inspections by Garage Presence", 
     xlab = "Garage Status", ylab = "Number of Inspections")

df$has_dropoff_label <- factor(df$dropoff, levels = c(0, 1),
     labels = c("No Dropoff", "Has Dropoff"))

stripchart(inspections ~ has_dropoff_label, vertical=TRUE, method='jitter', pch=16,
     data = df, main = "Fig. 8: Inspections by Dropoff Presence", 
     xlab = "Dropoff Status", ylab = "Number of Inspections")

# ----- Initial Regression Model ----- #
model <- lm(inspections ~ pop + garage + dropoff + baskets + park_acres, data=df)
summary(model)

# ----- Correlation Matrix ----- #
X <- model.matrix(model)[, -1]
cor_matrix <- cor(X)
corrplot(cor_matrix, method = "color", type = "upper", 
   addCoef.col = "black", tl.col = "black", tl.cex = 0.8, tl.srt = 45,
   title = "Fig. 9: Correlation Matrix of Predictor Variables", mar = c(0, 0, 2, 0))

# ----- Residual Analysis of Initial Model ----- #
stud_res <- rstudent(model)
y_hat <- fitted(model)

par(mfrow = c(2, 3), oma = c(0, 0, 2, 0))

qqnorm(stud_res, main = 'Quantile Plot')
qqline(stud_res, col='black')

hist(stud_res, main = 'Histogram',
     xlab = 'Studentized Deleted Residuals', breaks = 10)

plot(y_hat, stud_res, main = 'Scatter Plot',
     xlab = 'Y Values', ylab = 'Studentized Deleted Residuals')
abline(h=0, col='black', lty=2)

plot(df$pop, stud_res, main = 'Scatter Plot',
     xlab = 'Population', ylab = 'Studentized Deleted Residuals')
abline(h=0, col='black', lty=2)

plot(df$baskets, stud_res, main = 'Scatter Plot',
     xlab = 'Litter Bins', ylab = 'Studentized Deleted Residuals')
abline(h=0, col='black', lty=2)

plot(df$park_acres, stud_res, main = 'Scatter Plot',
     xlab = 'Park Acres', ylab = 'Studentized Deleted Residuals')
abline(h=0, col='black', lty=2)

mtext("Fig. 10: Residual Plots", outer = TRUE)

par(mfrow = c(1, 1))

# ----- Test for Homogeneity of Variance ----- #
bptest(model, studentize = TRUE)

# ----- Test for Normality ----- #
shapiro.test(rstudent(model))

# ----- Box Cox Transformation ----- #
result <- boxCox(model, main = "Fig. 11: Box-Cox Transformation")
lambda <- result$x[which.max(result$y)]
lambda

# ----- Taking the Log of Inspections ----- #
any(df$inspections <= 0)
df$log_inspections <- log(df$inspections)

log_model <- lm(log_inspections ~ pop + garage + dropoff + baskets + park_acres, data=df)
summary(log_model)

# ----- Examining Interaction Effects ----- # 
ggplot(df, aes(x = pop, y = inspections, color = factor(dropoff))) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(color = "Has Drop-off",
    title = "Fig. 12: Population vs. Inspections by Drop-off Presence",) + 
  theme_bw() + theme(plot.title = element_text(hjust = 0.5)) +
  scale_color_manual(values = c("red", "blue"))

ggplot(df, aes(x = pop, y = inspections, color = factor(garage))) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    color = "Has Garage",
    title = "Fig. 13: Population vs. Inspections by DSNY Garage Presence") + 
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_color_manual(values = c("red", "blue"))

df$binned_baskets = cut(df$baskets,
  breaks = quantile(df$baskets, probs = c(0, .33, .66, 1)),
  include.lowest = TRUE
)
ggplot(df, aes(x = pop, y = inspections, color = binned_baskets)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) + 
  labs(
    title = "Fig. 14: Population vs. Inspections by Baskets") + theme_bw() +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_color_manual(values = c("red", "blue", "black"))

# ----- Centered Model with Interactions ----- # 
df$pop_c <- scale(df$pop, scale = FALSE)
df$baskets_c <- scale(df$baskets, scale = FALSE)

centered_log_int_model <- lm(log_inspections ~ pop_c*baskets_c + pop_c*garage + pop_c*dropoff, data = df)
summary(centered_log_int_model)

vif_values <- vif(centered_log_int_model)
mean(vif_values)

# ----- ANOVA ----- #
anova(log_model, centered_log_int_model)

# ----- Residual Analysis for Final Model ----- #
final_stud_res <- rstudent(centered_log_int_model)
final_y_hat <- fitted(centered_log_int_model)

par(mfrow = c(2, 3), oma = c(0, 0, 2, 0))

qqnorm(final_stud_res, main = 'Quantile Plot')
qqline(final_stud_res, col='black')

hist(final_stud_res, main = 'Histogram',
     xlab = 'Studentized Deleted Residuals', breaks = 10)

plot(final_stud_res, type = 'l', main = 'Line Plot',
    ylab = 'Studentized Deleted Residuals', col='red')
points(final_stud_res, col = 'black')
abline(h=0, col='black', lty=2)

plot(final_y_hat, stud_res, main = 'Scatter Plot',
     xlab = 'Y Values', ylab = 'Studentized Deleted Residuals')
abline(h=0, col='black', lty=2)

plot(df$pop, final_stud_res, main = 'Scatter Plot',
     xlab = 'Population', ylab = 'Studentized Deleted Residuals')
abline(h=0, col='black', lty=2)

plot(df$baskets, final_stud_res, main = 'Scatter Plot',
     xlab = 'Litter Bins', ylab = 'Studentized Deleted Residuals')
abline(h=0, col='black', lty=2)

mtext("Fig. 15: Residual Plots", outer = TRUE)

par(mfrow = c(1, 1))

# ----- Test for Homogeneity of Variance ----- #
bptest(centered_log_int_model, studentize = TRUE)

# ----- Test for Normality ----- #
shapiro.test(rstudent(centered_log_int_model))

# ----- Identifying Influential Cases ----- #
cooks_d <- cooks.distance(centered_log_int_model)

n <- nrow(df)
threshold <- 4 / n
influential <- which(cooks_d > threshold)

plot(cooks_d, type = "h", main = "Fig. 16: Cook's Distance",
     ylab = "Cook's Distance", xlab = "Observation Index")
abline(h = 4/n, col = "red", lty = 2)

print(paste("Number of influential observations:", length(influential)))
print(paste("Threshold:", round(threshold, 4)))
print(paste("Max Cook's Distance:", round(max(cooks_d), 4)))
