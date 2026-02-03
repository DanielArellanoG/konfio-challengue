Planteamiento
# Stack de referencia
Región principal: us-east-1.

La API de originación de crédito con la siguiente arquitectura:
Amazon API Gateway o ALB exponiendo la API.
Backend en Amazon ECS (Fargate).
Base de datos Amazon Aurora PostgreSQL.
Dependencias:
Proveedor externo de scoring.
Servicio interno de autenticación.

Logs en Amazon CloudWatch Logs.
Métricas en Amazon CloudWatch.
Opcional: AWS X-Ray y/o APM externo.

Infraestructura gestionada con Terraform en cuentas separadas por entorno.



# 1. Confiabilidad de un servicio crítico
🎯 Contexto
Trabajás como SRE en una fintech. Uno de los servicios más críticos es la API de
originación de créditos:
Capa de entrada: Amazon API Gateway o Application Load Balancer .
Cómputo: Backend en Amazon ECS (Fargate)
Datos: Amazon Aurora PostgreSQL .
Dependencias:
Proveedor externo de scoring.
Servicio interno de autenticación.
Observabilidad: Logs y métricas básicas.
Esta API es crítica: cualquier degradación afecta directamente la originación de
créditos.
Actualmente no hay estrategia formal de confiabilidad ni observabilidad
estructurada.

1. Estrategia de Confiabilidad
Diseñá una estrategia integral de confiabilidad para este servicio:
Métricas de confiabilidad: ¿Qué indicadores definirías para medir la salud del
servicio? ¿Cómo los calcularías?
Objetivos de servicio: ¿Qué compromisos de calidad establecerías con el
negocio? ¿Cómo los justificarías?
Fuentes de datos: ¿Qué servicios AWS y herramientas usarías para obtener
estas métricas?
2. Arquitectura de Observabilidad
Describí cómo implementarías observabilidad completa:
Métricas: ¿Qué métricas capturarías y dónde las almacenarías?
Logs: ¿Cómo estructurarías el logging? ¿Qué información incluirías?
Trazas: ¿Cómo implementarías tracing distribuido?
Dashboards: ¿Qué visualizaciones crearías y para qué audiencias?
3. Sistema de Alertas
Diseñá un sistema de alertas efectivo:
Detección temprana: ¿Qué señales usarías para detectar degradación antes
de que impacte usuarios?
Incidentes críticos: ¿Qué condiciones activarían alertas de alta prioridad?
Gestión de ruido: ¿Cómo evitarías fatiga de alertas?
Escalamiento: ¿Cómo estructurarías las notificaciones por severidad?
4. Gestión Operativa
Explicá cómo gestionarías la confiabilidad en producción:
Monitoreo continuo: ¿Cómo harías seguimiento del cumplimiento de
objetivos?
Revisiones periódicas: ¿Qué procesos establecerías para evaluar y ajustar la
estrategia?
Comunicación con negocio: ¿Cómo reportarías el estado de confiabilidad a
stakeholders no técnicos?

# 2. Análisis de Incidente & Postmortem
🎯 Contexto
Incidente reportado:
"Los clientes están tardando mucho en completar solicitudes de crédito y
algunos no logran terminar el proceso".
Línea de tiempo:
09:00 – Negocio reporta caída del 40% en finalización de flujos de crédito.
09:10 – Dashboard de producto muestra reducción en créditos procesados.
09:15 – Observabilidad muestra:
Aumento significativo de latencia en /loan/apply .
Errores intermitentes hacia proveedor externo de scoring.
09:25 – Logs muestran:
Timeouts hacia proveedor externo.
Errores de conexión hacia Aurora.
09:40 – Se identifica que durante la noche se desplegó nueva versión del
servicio de scoring con cambios en política de reintentos.
10:00 – Mitigación:
Rollback del servicio de scoring.
Ajuste de configuración de reintentos.
Normalización del servicio.

1. Respuesta a Incidentes
Describí tu aproximación durante los primeros 60 minutos:
Investigación inicial: ¿Qué datos revisarías primero y en qué orden?
Formulación de hipótesis: ¿Qué posibles causas considerarías?
Estrategia de mitigación: ¿Qué acciones priorizarías para reducir impacto?
Comunicación: ¿Cómo mantendrías informados a los stakeholders?
1. Análisis de Causa Raíz
Desarrollá un análisis profundo:
Causa raíz principal: Identifica y explica la causa fundamental.
Factores contribuyentes: ¿Qué elementos del sistema permitieron que este
problema ocurriera?
Puntos de falla: ¿Dónde fallaron las defensas del sistema?
3. Postmortem
Redactá un postmortem completo que incluya:
Resumen ejecutivo orientado a negocio.
Impacto detallado (usuarios, duración, alcance).
Cronología completa de eventos.
Análisis técnico de la causa raíz.
Acciones correctivas inmediatas.
Plan de mejoras a mediano y largo plazo.
4. Prevención y Mejoras
Proponé mejoras sistémicas:
Observabilidad: ¿Qué gaps de visibilidad identificaste?
Arquitectura: ¿Qué cambios arquitectónicos prevendrían recurrencias?
Procesos: ¿Qué mejoras en procesos de desarrollo y despliegue
implementarías?
Cultura: ¿Cómo fortalecerías la cultura de confiabilidad en el equipo?


# 3. IaC
1. Opción A – Módulo Terraform de Observabilidad
Diseñá un módulo Terraform reutilizable para estandarizar observabilidad de APIs
en AWS.
Requisitos:
Parametrizable para diferentes tipos de APIs (ALB/API Gateway).
Creación automática de métricas, alarmas y dashboards.
Configuración flexible de umbrales y notificaciones.
Documentación de uso y ejemplos.
Entregable:
Código Terraform con estructura modular.
Documentación de variables y outputs.
Ejemplo de uso del módulo.
2. Opción B – Herramienta de Análisis de Logs
Desarrollá una herramienta para análisis automatizado de logs de CloudWatch.
Requisitos:
Procesamiento de logs exportados de CloudWatch.
Cálculo de métricas de confiabilidad.
Detección automática de anomalías.
Reportes estructurados con recomendaciones.
Entregable:
Script en Python/Go con funcionalidad completa.
Documentación de uso y configuración.
Ejemplos de análisis y outputs.


