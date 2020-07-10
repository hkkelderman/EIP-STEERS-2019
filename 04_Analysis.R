library(tidyverse)
library(readxl)
library(stringr)
library(xlsx)

data <- read_excel("00_2019 STEERS Dataset_analysis.xlsx")

data$start_date_time <- as.Date(data$start_date_time)
data$end_date_time <- as.Date(data$end_date_time)

fold <- "S:/Pollution Data and Permits/Emissions Inventories, By State/Texas/Emission Event Data/EE_2019/Analysis Files and Code/Site Files/"

### EMISSIONS BY COUNTY/CONTAMINANT FOR EACH REGION ####
state_total_county <- data %>%
  group_by(county) %>%
  filter(uom == "POUNDS") %>%
  summarise('Number of Events' = n_distinct(incid_id),
            'Tons Emitted' = round(sum(amount_released)/2000, digits = 2)) %>%
  mutate('Type' = 'All') %>%
  rename(County = county) %>%
  select(1,4,2,3)

state_contam_county <- data %>%
  filter(uom == "POUNDS") %>%
  select(county, incid_id, 54:62, amount_released) %>%
  rename(County = county, HAP = hap, TOX = tox, VOC = voc, PM = pm, NOX = nox, GHG = ghg,
         Other = other, SO2 = so2, SOX = sox) %>%
  gather(key = "Type", value = "type_2", 3:11) %>%
  filter(type_2 != 0) %>%
  group_by(County, Type) %>%
  summarise('Number of Events' = n_distinct(incid_id),
            'Tons Emitted' = round(sum(amount_released)/2000, digits = 2))

state_emissions <- bind_rows(list(state_total_county, state_contam_county)) %>%
  mutate("Region" = "Texas")

permian_total_county <- data %>%
  group_by(county) %>%
  filter(uom == "POUNDS", permian == 1) %>%
  summarise('Number of Events' = n_distinct(incid_id),
            'Tons Emitted' = round(sum(amount_released)/2000, digits = 2)) %>%
  mutate('Type' = 'All') %>%
  rename(County = county) %>%
  select(1,4,2,3)

permian_contam_county <- data %>%
  filter(uom == "POUNDS", permian == 1) %>%
  select(county, incid_id, 54:62, amount_released) %>%
  rename(County = county, HAP = hap, TOX = tox, VOC = voc, PM = pm, NOX = nox, GHG = ghg,
         Other = other, SO2 = so2, SOX = sox) %>%
  gather(key = "Type", value = "type_2", 3:11) %>%
  filter(type_2 != 0) %>%
  group_by(County, Type) %>%
  summarise('Number of Events' = n_distinct(incid_id),
            'Tons Emitted' = round(sum(amount_released)/2000, digits = 2))

permian_emissions <- bind_rows(list(permian_total_county, permian_contam_county)) %>%
  mutate("Region" = "Permian Basin")

coastal_total_county <- data %>%
  group_by(county) %>%
  filter(uom == "POUNDS", region %in% c("REGION 12 - HOUSTON", "REGION 10 - BEAUMONT")) %>%
  summarise('Number of Events' = n_distinct(incid_id),
            'Tons Emitted' = round(sum(amount_released)/2000, digits = 2)) %>%
  mutate('Type' = 'All') %>%
  rename(County = county) %>%
  select(1,4,2,3)

coastal_contam_county <- data %>%
  filter(uom == "POUNDS", region %in% c("REGION 12 - HOUSTON", "REGION 10 - BEAUMONT")) %>%
  select(county, incid_id, 54:62, amount_released) %>%
  rename(County = county, HAP = hap, TOX = tox, VOC = voc, PM = pm, NOX = nox, GHG = ghg,
         Other = other, SO2 = so2, SOX = sox) %>%
  gather(key = "Type", value = "type_2", 3:11) %>%
  filter(type_2 != 0) %>%
  group_by(County, Type) %>%
  summarise('Number of Events' = n_distinct(incid_id),
            'Tons Emitted' = round(sum(amount_released)/2000, digits = 2))

coastal_emissions <- bind_rows(list(coastal_total_county, coastal_contam_county)) %>%
  mutate("Region" = "Gulf Coast")

regions_emissions <- rbind(state_emissions, permian_emissions, coastal_emissions)
regions_emissions <- as.data.frame(regions_emissions)
write.xlsx(regions_emissions, str_c(fold, "003_Emissions.xlsx"), row.names = FALSE)

### TOP 10 FACILITIES BY REGION ####
state_top_ten_facilities <- data %>%
  filter(uom == "POUNDS") %>%
  group_by(rn_number, rn_name) %>%
  summarise(event_count = n_distinct(incid_id),
            tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Texas")
state_top_ten_facilities <- state_top_ten_facilities[1:10,]

permian_top_ten_facilities <- data %>%
  filter(uom == "POUNDS", permian == 1) %>%
  group_by(rn_number, rn_name) %>%
  summarise(event_count = n_distinct(incid_id),
            tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Permian Basin")
permian_top_ten_facilities <- permian_top_ten_facilities[1:10,]

coastal_top_ten_facilities <- data %>%
  filter(uom == "POUNDS", region %in% c("REGION 12 - HOUSTON", "REGION 10 - BEAUMONT")) %>%
  group_by(rn_number, rn_name) %>%
  summarise(event_count = n_distinct(incid_id),
            tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Gulf Coast")
coastal_top_ten_facilities <- coastal_top_ten_facilities[1:10,]

regions_top_facilities <- rbind(state_top_ten_facilities, permian_top_ten_facilities, 
                                coastal_top_ten_facilities)

top_fac_rns <- unique(regions_top_facilities$rn_number)

fac_contams <- data %>%
  filter(rn_number %in% top_fac_rns) %>%
  group_by(rn_number, corrected_contam) %>% 
  summarise(emissions = sum(amount_released)) %>%
  arrange(desc(emissions))

fc <- by(fac_contams, fac_contams["rn_number"], head, n=5)
fc <- bind_rows(fc)

fac_contams <- fc %>%
  group_by(rn_number) %>%
  summarise(contams = str_c(unique(corrected_contam),
                            sep = "", collapse = ", "))

regions_top_facilities <- as.data.frame(regions_top_facilities) %>%
  left_join(fac_contams, by = "rn_number")
write.xlsx(regions_top_facilities, str_c(fold, "004_Top Facilities.xlsx"), row.names = FALSE)

### TOP 10 EVENTS BY REGION ####
state_top_ten_events <- data %>%
  filter(uom == "POUNDS") %>%
  select(rn_number, rn_name, incid_id, amount_released) %>%
  group_by(incid_id, rn_number, rn_name) %>%
  summarise(tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Texas")
state_top_ten_events <- state_top_ten_events[1:10,]

permian_top_ten_events <- data %>%
  filter(uom == "POUNDS", permian == 1) %>%
  select(rn_number, rn_name, incid_id, amount_released) %>%
  group_by(incid_id, rn_number, rn_name) %>%
  summarise(tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Permian")
permian_top_ten_events <- permian_top_ten_events[1:10,]

coastal_top_ten_events <- data %>%
  filter(uom == "POUNDS", region %in% c("REGION 12 - HOUSTON", "REGION 10 - BEAUMONT")) %>%
  select(rn_number, rn_name, incid_id, amount_released) %>%
  group_by(incid_id, rn_number, rn_name) %>%
  summarise(tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Gulf Coast")
coastal_top_ten_events <- coastal_top_ten_events[1:10,]

regions_top_events <- rbind(state_top_ten_events, permian_top_ten_events, 
                                coastal_top_ten_events)

top_ev_rns <- unique(regions_top_events$incid_id)

event_contams <- data %>%
  filter(incid_id %in% top_ev_rns) %>%
  group_by(incid_id, corrected_contam) %>% 
  summarise(emissions = sum(amount_released)) %>%
  arrange(desc(emissions))

ec <- by(event_contams, event_contams["incid_id"], head, n=5)
ec <- bind_rows(ec)

event_contams <- ec %>%
  group_by(incid_id) %>%
  summarise(contams = str_c(unique(corrected_contam),
                            sep = "", collapse = ", "))

regions_top_events <- as.data.frame(regions_top_events) %>%
  left_join(event_contams, by = "incid_id")
write.xlsx(regions_top_events, str_c(fold, "005_Top Events.xlsx"), row.names = FALSE)

### TOP CHEMICALS EMITTED BY REGION ####
state_chemicals <- data %>%
  filter(uom == "POUNDS") %>%
  group_by(corrected_contam) %>%
  summarise(event_count = n_distinct(incid_id),
            tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Texas")
state_chemicals <- state_chemicals[1:10,]

permian_chemicals <- data %>%
  filter(uom == "POUNDS", permian == 1) %>%
  group_by(corrected_contam) %>%
  summarise(event_count = n_distinct(incid_id),
            tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Permian Basin")
permian_chemicals <- permian_chemicals[1:10,]

coastal_chemicals <- data %>%
  filter(uom == "POUNDS", region %in% c("REGION 12 - HOUSTON", "REGION 10 - BEAUMONT")) %>%
  group_by(corrected_contam) %>%
  summarise(event_count = n_distinct(incid_id),
            tons_emitted = round(sum(amount_released)/2000, digits = 0)) %>%
  arrange(desc(tons_emitted)) %>%
  mutate("Region" = "Gulf Coast")
coastal_chemicals <- coastal_chemicals[1:10,]

regions_top_chem <- rbind(state_chemicals, permian_chemicals, coastal_chemicals) %>%
  rename('Contaminant' = corrected_contam, 'Number of Events' = event_count,
         'Tons Emitted' = tons_emitted)
regions_top_chem <- as.data.frame(regions_top_chem)
write.xlsx(regions_top_chem, str_c(fold, "001_Chemicals.xlsx"), row.names = FALSE)

### CONTAMINANT TYPE EMISSIONS BY REGION ####
state_contam <- data %>%
  filter(uom == "POUNDS") %>%
  select(hap, tox, voc, so2, pm, nox, amount_released) %>%
  rename(HAP = hap, TOX = tox, VOC = voc, SO2 = so2, PM = pm, NOX = nox) %>%
  gather(key = "Contaminant Type", value = "type_2", 1:6) %>%
  filter(type_2 != 0) %>%
  group_by(`Contaminant Type`) %>%
  summarise('Tons Emitted' = round(sum(amount_released)/2000, digits = 0)) %>%
  mutate(Region = "Texas")

permian_contam <- data %>%
  filter(uom == "POUNDS", permian == 1) %>%
  select(hap, tox, voc, so2, pm, nox, amount_released) %>%
  rename(HAP = hap, TOX = tox, VOC = voc, SO2 = so2, PM = pm, NOX = nox) %>%
  gather(key = "Contaminant Type", value = "type_2", 1:6) %>%
  filter(type_2 != 0) %>%
  group_by(`Contaminant Type`) %>%
  summarise('Tons Emitted' = round(sum(amount_released)/2000, digits = 0)) %>%
  mutate(Region = "Permian Basin")

coastal_contam <- data %>%
  filter(uom == "POUNDS", region %in% c("REGION 12 - HOUSTON", "REGION 10 - BEAUMONT")) %>%
  select(hap, tox, voc, so2, pm, nox, amount_released) %>%
  rename(HAP = hap, TOX = tox, VOC = voc, SO2 = so2, PM = pm, NOX = nox) %>%
  gather(key = "Contaminant Type", value = "type_2", 1:6) %>%
  filter(type_2 != 0) %>%
  group_by(`Contaminant Type`) %>%
  summarise('Tons Emitted' = round(sum(amount_released)/2000, digits = 0)) %>%
  mutate(Region = "Gulf Coast")

regions_contam <- rbind(state_contam, permian_contam, coastal_contam)
regions_contam <- as.data.frame(regions_contam)
write.xlsx(regions_contam, str_c(fold, "002_Contaminants.xlsx"), row.names = FALSE)
