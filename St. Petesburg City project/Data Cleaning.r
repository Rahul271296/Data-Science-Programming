rm(list=ls())
library(rio)
library(dplyr)
#Load the data
main.df2015 =  import("Combined Tax ID Data.xlsx", sheet='2015')
main.df2023 = import("Combined Tax ID Data.xlsx", sheet = '2023')
str(main.df2015)
str(main.df2023)

#Dealing with duplicates for 2015
duplicates1 <- duplicated(main.df2015$`CONTROL #`) #True or false for each row if its duplicated by control #

duplicate_rows1 <- main.df2015[duplicates1, ] 

df2015_distinct <- distinct(main.df2015 ,`CONTROL #`, .keep_all = TRUE)

#26692 and 286. Elvis towing service has 2 control numbers.


#Dealing with duplicates for 2023
duplicates2 <- duplicated(main.df2023$`CONTROL #`) #True or false for each row if its duplicated by control #

duplicate_rows2 <- main.df2023[duplicates2, ] 

df2023_distinct <- distinct(main.df2023 ,`CONTROL #`, .keep_all = TRUE)


#Creating a new column "corridor" by combing the corridor values
df2015_distinct$Corridor <- apply(df2015_distinct[, 10:17], 1, function(x) {
  paste0(na.omit(x), collapse = " AND ")
})

df2023_distinct$Corridor <- apply(df2023_distinct[, 10:17], 1, function(x) {
  paste0(na.omit(x), collapse = " AND ")
})

#checking the unique values for corridor for each year
unique(df2015_distinct$Corridor)
unique(df2023_distinct$Corridor)

# Replace values in the corridor column of 2023
df2023_distinct$`16th St Corridor` <- gsub("Within 16thSt Corridor", "Within 16th St Corridor", df2023_distinct$`16th St Corridor`)
df2023_distinct$`22nd St S Corridor` <- gsub("Within 22nd St Corridor", "Within 22nd Street South Corridor", df2023_distinct$`22nd St S Corridor`)
df2023_distinct$`Dr MLK Jr St  Corridor` <- gsub("Within Dr MLK JR ST  Corridor", "Within DrMLK JR ST  Corridor", df2023_distinct$`Dr MLK Jr St  Corridor`)
#run the apply function again
df2015_distinct$Corridor <- apply(df2015_distinct[, 10:17], 1, function(x) {
  paste0(na.omit(x), collapse = " AND ")
})

df2023_distinct$Corridor <- apply(df2023_distinct[, 10:17], 1, function(x) {
  paste0(na.omit(x), collapse = " AND ")
})

#Blanks in corridor2015 = 1049
#Blanks in corridor2023 = 872

#Drop the individual corridor columns.
# drop columns 10 to 17 using subset()
reduced_2015 = subset(df2015_distinct, select = -c(10:17))
reduced_2023 = subset(df2023_distinct, select = -c(10:17))


#Combining and exporting
library(openxlsx)
wb <- createWorkbook()
addWorksheet(wb, "2015")
writeData(wb, "2015", df2015_distinct)
addWorksheet(wb, "2023")
writeData(wb, "2023", df2023_distinct)
saveWorkbook(wb, "reducedTaxData.xlsx", overwrite = TRUE)

#How to treat Control numbers that do not have a corridor value?


# a.How many businesses (#) that were active on each corridor in 2015 are still active on the corridor?

merged_df <- merge(reduced_2015, reduced_2023, by = c("CONTROL #", "PIN #", "ADDRESS1"), all.x = TRUE, suffixes = c(".2015", ".2023"))
#left join

#Filtering based on businesses "Active" status
active_2015 <- merged_df %>% 
  filter(`BUSINESS STATUS.2015` == "A") %>% 
  group_by(Corridor.2015) %>% 
  summarize(active_2015 = n())

active_2023 <- merged_df %>% 
  filter(`BUSINESS STATUS.2023` == "A") %>% 
  group_by(Corridor.2023) %>% 
  summarize(active_2023 = n())

active_both <- merge(active_2015, active_2023, by.x = "Corridor.2015", by.y = "Corridor.2023", all = TRUE)
active_both[is.na(active_both)] <- 0

active_both


#Final aggregation to get 8 corridors
library(tidyr)
library(dplyr)

active_both_final <- active_both %>%
  separate_rows(Corridor.2015, sep = " AND ") %>%
  group_by(Corridor.2015) %>%
  summarize(active_2015 = sum(active_2015),
            active_2023 = sum(active_2023)) %>%
  ungroup() %>%
  mutate(Corridor.2015 = gsub("^\\s+|\\s+$", "", Corridor.2015)) %>%
  group_by(Corridor = gsub("(\\w+\\s\\w+).*", "\\1", Corridor.2015)) %>%
  summarize(active_2015 = sum(active_2015),
            active_2023 = sum(active_2023))
active_both_final

# Answering percentage of business still active
active_both_final <- active_both_final %>%
  mutate(percent_active = ifelse(active_2015 == 0, 0, round(active_2023 / active_2015 * 100, 2)))

active_both_final
