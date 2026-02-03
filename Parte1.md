**Pregunta 1**: Estrategia de Confiabilidad
Diseñá una estrategia integral de confiabilidad para este servicio:
Métricas de confiabilidad: ¿Qué indicadores definirías para medir la salud del
servicio? ¿Cómo los calcularías?
Objetivos de servicio: ¿Qué compromisos de calidad establecerías con el
negocio? ¿Cómo los justificarías?
Fuentes de datos: ¿Qué servicios AWS y herramientas usarías para obtener
estas métricas?

Para realizar una estrategia integral de confiabilidad del servicio de originación de créditos, se proponen los siguientes aspectos fundamentales:
El framework de observabilidad "Golden Signals" que define métricas esenciales a monitorear: Tráfico, Errores, Latencia, Saturación.
- Se asumen los errores y latencia como métricas que afectan directamente a los usuarios.
- Se asume el tráfico y la saturación como métricas que no indican la disponibilidad del servicio pero sí explican posibles degradaciones en la salud del sistema.

Se proponen SLOs medibles y accionables.
- 99.9% disponibilidad mensual para /loan/apply, cierta tolerancia a fallas permitiendo ventanas de despliegue y mantenimiento.
  - Cálculo de Disponibilidad mediante tasa de error --> (Errores 5XX / Requests Totales) * 100
  - Cálculo de Error Budget --> 99.9% SLO, 0.01% al mes: .001 * 30 * 24 * 60 = 43 minutos al mes
- Latencia p95 < 800 ms, balance entre experiencia de usuario y consideración de un umbral de latencia en llamadas a servicios internos.
  - Cálculo de Latencia --> indicadores nativos de servicios en AWS, percentiles nativos como rendering properties.

De la mano con un ambiente nativo en la nube de AWS y el modelo de los pilares de observabilidad, se propone el uso de las distintas funcionalidades de AWS:
- Métricas automáticas de CloudWatch para API Gateway, ALB, ECS, Aurora, adicionalmente métricas con costo de CloudWatch Insights.
- Logs (requerimiento de habilitarse en cada servicio): Log de aplicación en ECS (awslogs), logs de API Gateway, logs de Aurora (error / slow query), todos almacenados en CloudWatch.
- Traces mediante AWS X-Ray para API Gateway y los servicios ECS. Visualización de flujo end-to-end.
Así mismo, para visualización y alertas se utilizan las funciones nativas de Dashboards y Alarms de CloudWatch.
- Almacenamiento de métricas administrado directamente por CloudWatch sin necesidad de un servicio adicional.

Métricas de AWS CloudWatch orientadas al usuario:
- Errores
  - ALB: HTTPCode_ELB_5XX_Count, RequestCount
  - API Gateway: 5XXError, Count
- Latencia:
  - ALB: TargetResponseTime
  - API Gateway: Latency vs IntegrationLatency para distinguir entre throttling del mismo API Gateway o el servicio de originación de crédito.
  - Aurora: ReadLatency, WriteLatency
Métricas de AWS CloudWatch orientadas a la salud del sistema:
- Saturación
  - ECS: CPUUtilization, MemoryUtilization
  - Aurora: CPUUtilization
- Tráfico
  - ALB: RequestCount
  - API Gateway: Count

Trazas mediante X-Ray, habilitándolas en configuraciones nativas de ALB y API Gateway y configurando contenedor sidecar de OpenTelemetry para ECS ([el daemon de X-Ray está deprecado](https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-migration.html#xray-Daemon-migration)).

Se proponen tres visualizaciones:
- Visualización Operativa (SRE & DevOps): monitoreo de todas las métricas mencionadas con alta resolución (<=1 minuto).
- Visualización Ejecutiva: Volumen de tráfico y tendencia de error rate, resolución diaria.
- Visualización Detallada del sistema: monitoreo de métricas adicionales a la salud del sistema (e.g. IOPS y Database Connections en Aurora)

Para ECS, se necesita habilitar el [driver de awslogs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html) para obtener logs de los contenedores.
Se propone la configuración de logs en ECS con los siguientes campos:
- timestamp
- level (INFO, WARN, ERROR)
- service_name
- environment
- request_id --> App logic
- trace_id --> OTel agent
- user_id --> App logic
- application_id --> App logic
- operation --> App logic (e.g. loan.apply)
- error_code
- error_message


Para detectar degradación antes de un posible impacto para los usuarios, se proponen dos consideraciones principales:
- Umbrales amplios lejanos a los SLOs y uso de señales tempranas.
  - Burn rate del Erro Budget
  - Aumento de latencia p95
  - Aumento en saturación de recursos
- Medición de tendencias anómalas además de métricas aisladas.


Se propone la gestión de ruido mediante la asociación de alarmas con action items.
Se hace distinción entre alertas (acciones concretas) por canales de alta prioridad (teléfono, plataforma de operaciones) y eventos (información) en canales de baja prioridad (canales de mensajería como slack, correos).
Se propone la definición de severidad de notificaciones (info y conductas anómalas de bajo riesgo):
- Sev 1: breach de SLO --> pager inmediato
- Sev 2: Riesgo alto de breach de SLO --> slack + email + ack. Escalamiento si no hay ack.
- Sev 3: Anomalías --> Slack con automatización de análisis
- Info: Despliegues --> Slack general

Aunado a todas las métricas monitoreadas, se proponen tres conceptos principales para asegurar la confiabilidad de todo el sistema:
- Dashboards de SLIs vs SLOs
- Seguimiento del error budget
- Alarmas basadas en burn rate

Se sugieren procesos de operaciones continuas:
- Resilience reviews con knowledge transfer para todo el equipo, así como definición de nuevos action items.
- Design reviews exhaustivas.

Para los stakeholders no técnicos, se sugiere un lenguaje simple en términos de disponibilidad, impacto y riesgo:
- e.g. Se observa una tendencia en aumento de tráfico lo que puede comprometer la disponibilidad de los servicios.
- e.g. Aumento en latencia por aumento de tráfico representa un riesgo de impacto si no se atienden las causas.
