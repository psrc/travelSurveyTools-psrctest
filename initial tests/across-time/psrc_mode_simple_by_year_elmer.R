library(data.table)
library(stringr)
library(travelSurveyTools)
library(tidyr)
library(psrcelmer)

### Load in Data --------
trips_23_17  <- get_table(schema= 'HHSurvey', tbl_name='v_trips_labels')

setDT(trips_23_17)

# load in new codebook from PSRC
variable_list = readxl::read_xlsx(str_glue('J:/Projects/Surveys/HHTravel/Survey2023/Data/codebook/PSRC_Combined_Codebook_2023_groupings.xlsx'),
                                  sheet = 'variable_list_2023')
value_labels = readxl::read_xlsx(str_glue('J:/Projects/Surveys/HHTravel/Survey2023/Data/codebook/PSRC_Combined_Codebook_2023_groupings.xlsx'),
                                 sheet = 'value_labels_2023')
setDT(variable_list)
setDT(value_labels)

### Data Updates -------

# make hts_data a list of just the combined trip table
hts_data = list(trip = trips_23_17)

# codebook updates
variable_list[, shared_name := ifelse(
  grepl('--', description_2023),
  sub('_[^_]*$', '', variable), variable)
]
variable_list[, is_checkbox := ifelse(grepl('--', description_2023), 1, 0)]
setnames(variable_list, 'trip_final', 'trip')
setnames(variable_list, 'data_type_2023', 'data_type')
variable_list[variable == 'survey_year', data_type := 'character']
setnames(variable_list, 'description_2023', 'description')

# make mode_simple in the trip table
mode_simple_labels = value_labels[group_1_title == 'mode_simple', c('final_label', 'group_1_value')]
trips_23_17 = merge(trips_23_17, mode_simple_labels, by.x = 'mode_1', by.y = 'final_label')
setnames(trips_23_17, 'group_1_value', 'mode_simple')
#setnames(trips_23_17, 'tripid', 'trip_id')

# make hts_data a list of just the combined trip table
hts_data = list(trip = trips_23_17)

### Use package for summary -----
prepped_dt = hts_prep_variable(summarize_var = 'mode_simple',
                               summarize_by = 'survey_year',
                               data = hts_data,
                               id_cols = 'trip_id',
                               wt_cols = 'trip_weight',
                               weighted = FALSE,
                               missing_values = '')

mode_summary<-hts_summary(prepped_dt = prepped_dt$cat,
            summarize_var = 'mode_simple',
            summarize_by = 'survey_year',
            id_cols = 'trip_id',
            weighted = FALSE)

# end
