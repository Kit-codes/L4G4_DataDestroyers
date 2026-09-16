print("hello world!")
"hello world!!"
# if you want to add comment, shortcut is: ctrl + shift + c
# if you wish to set a value to a variable, use <-, shortcut is: alt + -

a <- 10

# a variable name should start with number, but it can contain number, and also alphabet and _ and . for example: q1_2.3 is acceptable, but 2q is not.

# 3 kinds of basic data type: numeric, character, logical

name <- "Tom"
name <- Tom
# "Tom" is character, and Tom is a variable.

pi

years <- c(2021, 2022, 2023, 2024, 2025, 2026)
names <- c("Ada", "Bob", "Cathy", "Dan")
TorF <- c(TRUE, FALSE, T, F, 1==1, 1<1)
# vector is a set of data with same type.  c means combine.


1:10  # this is a kind of vector
10:1

seq(from = 100, to = 120, by = 5)

rep(8, times = 8)

length(years)

class(names)

str(TorF)

years[1]
# vector starts from 1, not 0 like other coding language.

years[c(1,3,5)]

years[2:4]

years[length(years)]

years[-1]  # it means show everyone else except 1st one.


years + 5

years * 2

years_dulp <- years + 10

years + years_dulp  # only numeric type can do this.




# Statistic Method
sum(years)
mean(years)   # average
median(years)
min(years)
max(years)
range(years)
sd(years)
summary(years)    # important

years > 2023
years[years > 2023]

# Edit vector ------------------------------------------------
years[1] <- 2020   # modify the first element in vector "years"
years

years[c(1,2)] <- c(2000,2010)    #modify the first and second elements in vector
years

years[2:4] <- 2000:2002   
years

years <- c(years,2027)   # add a element to vector in the tail
years

years <- years[-1]  # delete the first element of vector
years


# Sort and Order -------------------------------------------------
years <- c(2005,2019,2014,2025,2006,2009,2030,2026)
years
sort(years, decreasing = TRUE)    # it wont change the years
order(years, decreasing = TRUE)   # shows the order position of each element in vector


# NULL -----------
is.na(years)




student_names <- c("Anna", "Ben", "Chen", "Diana", "Eric", "Fatima")
exam_scores <- c(72, 89, 95, 63, NA, 81)

length(student_names)
student_names[3]
exam_scores[3]
mean(exam_scores, na.rm = TRUE)
student_names[!is.na(exam_scores) & exam_scores>=80]
student_names[order(exam_scores, decreasing = TRUE)[1]]
exam_scores[order(exam_scores, decreasing = TRUE)[1]]
sum(is.na(exam_scores))
exam_scores[student_names == "Diana"] <- 70
exam_scores
exam_scores <- pmin(exam_scores + 3, 100)
exam_scores

