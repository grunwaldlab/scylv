library(tidyverse)
library(readxl)
library(viridis)
library(CoordinateCleaner)

metadata <- readxl::read_xlsx(file.path("data", "SCYLV metadata.xlsx"))
names(metadata) <- c("isolate", "virus", "country", "host", "date", "rna_extraction_year", "authors", "accession")
metadata <- metadata %>%
  select(strain = accession, virus, accession, date, country, authors)
# Example data set cols: strain	virus	accession	date	region	country	division	city	db	segment	authors	url	title	journal	paper_url
date_parts <- as.data.frame(str_match(metadata$date, pattern = '([0-9]{4})-?([0-9]{0,2})-?([0-9]{0,2})')[, 2:4])
date_parts[] <- lapply(date_parts, function(x) ifelse(x == "", "01", x))
metadata$date <- apply(date_parts, MARGIN = 1, paste0, collapse = "-")

metadata$country[metadata$country == "Reunion Island"] <- "Reunion" # Makes it match the lat/long data source
metadata$country[grepl(metadata$country, pattern = "^USA-")] <- "United States"

write_tsv(metadata, file = file.path("data", "metadata.tsv"))


## Config files

### Dropped strains

### Color
color_data <- tibble(scale = "country",
                     country = unique(metadata$country),
                     color = viridis(length(country)))
color_data$color <- substr(color_data$color, start = 1, stop = 7)
write_tsv(color_data, file = file.path("config", "colors.tsv"), col_names = FALSE)

### lat_longs
country_data <- as_tibble(countryref[! duplicated(countryref$name), ])
coord_data <- left_join(metadata, country_data, by = c(country = "name")) %>%
  transmute(scale = "country", 
            country = country,
            lat = centroid.lat,
            long = centroid.lon)
write_tsv(coord_data, file = file.path("config", "lat_longs.tsv"), col_names = FALSE)

### 