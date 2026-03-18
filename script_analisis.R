# ==============================================================================
#PROYECTO - ANÁLISIS DE INVERSIÓN PUBLICA EN PERÚ
#Por: Victor Ravines Robles
# ==============================================================================

# ==============================================================================
#0. Preguntas a resolver con la data
## ¿Qué sectores concentran la mayor inversión pública en el Perú?
## ¿Qué sectores presentan mayor diferencia entre el monto viable inicial y el costo actualizado?
## ¿Cuánto tiempo transcurre entre el registro de un proyecto y la obtención de su viabilidad?
# ==============================================================================

# ==============================================================================
#1. Instalación de librerias
# ==============================================================================
# install.packages("tidyverse")
# install.packages("lubridate")
# install.packages("janitor")
# install.packages("scales")

# ==============================================================================
#2. Carga de librerías
# ==============================================================================

library(tidyverse)
library(lubridate)
library(janitor)
library(scales)

# ==============================================================================
#3. Lectura de datos
# ==============================================================================
path_csv <- "D:/Cursos/We Educación Ejecutiva/R online/PROYECTO INTEGRADOR/Data/all_projects_investment_2020_filtered.csv"

# Leemos el dataset y aplicamos limpieza de nombres de inmediato.
# Usamos 'clean_names()' para que "Monto Viable" pase a ser "monto_viable", etc.
inversiones <- read_csv(path_csv, show_col_types = FALSE) %>% 
  clean_names()

# Verificamos la estructura del dataset cargado
# 'glimpse' nos muestra una vista rápida de las columnas y sus tipos de datos
glimpse(inversiones)


# ==============================================================================
#4. Transformación y limpieza de datos
# ==============================================================================
## Se realiza una limpieza previa al formateo de las fechas según la información obtenida de glimpse(inversiones)
inversiones_limpio <- inversiones %>%
  mutate(
    fecha_de_viabilidad = dmy(fecha_de_viabilidad),
    #Verificación de datos a números
    monto_viable = as.numeric(monto_viable),
    costo_actualizado = as.numeric(costo_actualizado),
    #Calculo de diferencia de costos
    variacion_costo = costo_actualizado - monto_viable,
    #Calculo de días para viabilidad
    dias_para_viabilidad = as.numeric(fecha_de_viabilidad - fecha_de_registro)
  )
#Test
glimpse(inversiones_limpio)


# ==============================================================================
#5. Pregunta 1: ¿Qué sectores concentran la mayor inversión pública en el Perú?
# ==============================================================================

## El objetivo aquí es identificar qué sectores están recibiendo la mayor cantidad de recursos. 
## Para que el análisis sea profesional, no solo sumaremos los montos, sino que también contaremos cuántos proyectos tiene cada sector.
ranking_sectores <- inversiones_limpio %>%
  group_by(sector) %>%
  summarise(
    total_monto = sum(monto_viable, na.rm = TRUE),
    conteo_proyectos = n()
  ) %>%
  arrange(desc(total_monto)) %>%
  slice_max(total_monto, n=5) #Top 5

## Visualización de datos
plot1 <-ggplot(ranking_sectores, aes(x = reorder(sector, total_monto), y = total_monto, fill = sector)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = label_number(prefix = "S/ ", scale = 1e-9, suffix = " mil Mill.")) +
  labs(
    title = "Top 5 Sectores con Mayor Inversión Pública",
    subtitle = "Monto Viable acumulado en Soles",
    x = "Sector",
    y = "Monto Total",
    caption = "Fuente: Dataset de Inversión Pública 2020"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# ==============================================================================
# 6. Pregunta 2: ¿Qué sectores presentan mayor diferencia entre el monto viable inicial y el costo actualizado?
# ==============================================================================

# Procesamiento de datos: Calculamos el % de incremento sobre el monto inicial
desviacion_pct <- inversiones_limpio %>%
  group_by(sector) %>%
  summarise(
    total_viable = sum(monto_viable, na.rm = TRUE),
    total_actualizado = sum(costo_actualizado, na.rm = TRUE)
  ) %>%
  mutate(pct_variacion = (total_actualizado - total_viable) / total_viable) %>%
  filter(total_viable > 0) %>% # Filtramos para evitar errores matemáticos
  arrange(desc(pct_variacion)) %>%
  slice_max(pct_variacion, n = 10)

# Visualización: Ranking de desviación porcentual
plot2 <-ggplot(desviacion_pct, aes(x = reorder(sector, pct_variacion), y = pct_variacion, fill = sector)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = label_percent()) + # Formato 0% - 100%
  labs(
    title = "Sectores con mayor incremento porcentual de presupuesto",
    subtitle = "Diferencia relativa entre Monto Viable y Costo Actualizado",
    x = "Sector",
    y = "Variación Porcentual (%)",
    caption = "Fuente: Dataset de Inversión Pública 2020"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# ==============================================================================
# 7. Pregunta 3: ¿Cuánto tiempo transcurre entre el registro de un proyecto y la obtención de su viabilidad?
# ==============================================================================

# Procesamiento de datos: Calculamos el promedio de días de espera
tiempo_viabilidad <- inversiones_limpio %>%
  group_by(sector) %>%
  summarise(
    promedio_dias = mean(dias_para_viabilidad, na.rm = TRUE),
    mediana_dias = median(dias_para_viabilidad, na.rm = TRUE)
  ) %>%
  filter(promedio_dias > 0) %>% # Filtramos inconsistencias (fechas invertidas)
  arrange(desc(promedio_dias)) %>%
  slice_max(promedio_dias, n = 10)

# Visualización: Ranking de tiempo de espera por sector
plot3<-ggplot(tiempo_viabilidad, aes(x = reorder(sector, promedio_dias), y = promedio_dias, fill = sector)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Sectores con Mayor Tiempo de Espera para Viabilidad",
    subtitle = "Promedio de días transcurridos desde el Registro hasta la Viabilidad",
    x = "Sector",
    y = "Días Promedio",
    caption = "Fuente: Dataset de Inversión Pública 2020"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# ==============================================================================
# 8. ANÁLISIS DE ESTACIONALIDAD: ¿En qué meses se registran más proyectos?
# ==============================================================================

# Extraemos el mes y año de la fecha de registro para ver el flujo temporal
proyectos_por_mes <- inversiones_limpio %>%
  mutate(mes_registro = month(fecha_de_registro, label = TRUE, abbr = FALSE)) %>%
  group_by(mes_registro) %>%
  summarise(conteo = n()) %>%
  filter(!is.na(mes_registro))

# Visualización de la estacionalidad
plot4<-ggplot(proyectos_por_mes, aes(x = mes_registro, y = conteo, group = 1)) +
  geom_line(color = "#2ecc71", size = 1) +
  geom_point(color = "#27ae60", size = 3) +
  labs(
    title = "Estacionalidad de los Proyectos de Inversión Pública",
    subtitle = "Número de proyectos registrados por mes (Año 2020)",
    x = "Mes de Registro",
    y = "Cantidad de Proyectos",
    caption = "Fuente: Dataset de Inversión Pública"
  ) +
  theme_minimal()

# ==============================================================================
# 9. ANÁLISIS DE CORRELACIÓN: ¿A más inversión, más demora la viabilidad?
# ==============================================================================

# Filtramos datos para el sector top (Transportes) y eliminamos valores atípicos
# para que el gráfico sea interpretable (proyectos de < 1000 días)
data_corr <- inversiones_limpio %>%
  filter(sector == "TRANSPORTES Y COMUNICACIONES", 
         monto_viable > 0, 
         dias_para_viabilidad > 0, 
         dias_para_viabilidad < 1000)

# Visualización de Dispersión con Línea de Tendencia
plot5<-ggplot(data_corr, aes(x = monto_viable, y = dias_para_viabilidad)) +
  geom_point(alpha = 0.2, color = "#3498db") + 
  geom_smooth(method = "lm", color = "red", se = FALSE) + 
  scale_x_log10(labels = label_number(prefix = "S/ ", scale = 1e-6, suffix = "M")) +
  labs(
    title = "Relación entre Monto y Tiempo de Viabilidad",
    subtitle = "Sector: Transportes y Comunicaciones (Escala Logarítmica)",
    x = "Monto Viable (Millones de Soles)",
    y = "Días de espera",
    caption = "Fuente: Análisis de Correlación de Pearson"
  ) +
  theme_minimal()

# ==============================================================================
# 10. EXPORTACIÓN DE RESULTADOS
# ==============================================================================

output_dir <- "resultados_graficos"
if (!dir.exists(output_dir)) dir.create(output_dir)

# Ahora especificamos el argumento 'plot' para cada archivo
ggsave(file.path(output_dir, "01_ranking_inversion.png"), plot = plot1, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "02_variacion_presupuestal.png"), plot = plot2, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "03_tiempos_viabilidad.png"), plot = plot3, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "04_estacionalidad_mensual.png"), plot = plot4, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "05_correlacion_monto_tiempo.png"), plot = plot5, width = 10, height = 6, dpi = 300)

cat("Exportación completada en la carpeta:", output_dir)
#usar getwd() en la consola para ver la ruta donde se guardaron los gráficos.
