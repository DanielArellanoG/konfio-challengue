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

# Respuesta a incidentes
Investigación inicial:
- Se considera origen de alertas como diagnóstico superficial.
- Visualización de dashboard con atención a los SLIs críticos:
  - Atención a error rate para confirmar downtime.
  - Atención a latencia como indicio probable de origen de fallas.
  - Atención a aumento de tráfico y saturación para diagnosticar falta de recursos.
- Consideración de cambios recientes: despliegues de cambios en infra y nuevas versiones de aplicación.
- [Opcional] Detección de drift para cambios manuales silenciosos.


Formulación de hipótesis, evaluadas de forma paralela y no secuencial:
- Timeouts al proveedor: se identifica una parte del flujo de la request con comportamiento anómalo. Se teoriza posible falta de recursos en el ambiente de cómputo ECS o problema en la lógica de aplicación entre ambos microservicios.
- Error de conexión a Aurora: se teoriza saturación de recursos en Aurora, pero dado el throttling espontáneo de la base de datos y la aparición de timeouts en algunos de los servicios, se refuerza la teoría un posible error en la lógica de aplicación en el flujo de solicitudes. 


Estrategia de mitigación (en orden prioritario se busca restaurar el servicio antes que realizar diagnóstico preciso):
- Rollbacks de cambios conflictivos
- Aprovisionamiento extra de infraestructura
- Despliegue de medidas de protección de red (previa automatización CI/CD) e.g. rate limits. 
- Monitoreo constante de métricas regresando a la normalidad


Estrategia de comunicación:
- 09:10 --> “Detectamos degradación en flujos de crédito. Investigamos estado de la infraestructura.”
- 09:20 --> "Confirmamos problema de disponibilidad, <hipótesis de alto nivel>, proveemos ETA"
- Cada 10 minutos --> "Avances en la resolución de problema, reitaremos o proveemos nuevo ETA"
- 10:00 --> “Servicio normalizado tras rollback de app. Monitoreamos hasta confirmar funcionamiento normal.”

# Análisis de Causa Raíz
Causa raíz principal: Cambio no validado en la política de reintentos del servicio de scoring, que incrementó significativamente el volumen de requests ante fallos intermitentes del proveedor externo, provocando aumento de latencia, timeouts y saturación de recursos internos (Aurora).

Factores contribuyentes:
- Dependencia externa con errores intermitentes
- Retries sin límites efectivos, ausencia de circuit breaker o lógica de backoff
- Aurora sensible a picos de conexiones
- Deploy nocturno sin validación de impacto sistémico

Puntos de falla:
- Falta de alertas proactivas por tasa de reintentos en el servicio.
- No existe observabilidad robusta para dependencias.
- Ausencia de deployment progresivo (e.g. canary).

# Postmortem
Resumen ejecutivo: "Entre las 09:00 y 10:00 AM se produjo una degradación significativa en la finalización de flujos de crédito debido a un cambio en un servicio crítico de scoring. El problema fue mitigado mediante rollback y ajustes de configuración. No hubo pérdida de datos. Se identificaron mejorar para prevenir recurrencias."


Impacto:
- Usuarios afectados: 40% de solicitudes
- Duración: 60 minutos
- Alcance: Flujos de crédito dependientes de scoring
- Impacto negocio: Reducción temporal en originación de créditos

Cronología:
- 09:00 - Negocio detecta caída en finalización
- 09:10 – Dashboard confirma impacto
- 09:15 – Observabilidad muestra latencia y errores externos
- 09:25 – Logs revelan timeouts y presión en Aurora
- 09:40 – Identificado deploy nocturno con retries agresivos
- 10:00 – Rollback + normalización

Análisis técnico de la causa raíz: Solicitudes al proveedor externo crecieron de forma anómala, lo cual generó aumento de latencia, saturación de recursos y por ende fallas en las solicitudes hechas por los usuarios.

Acciones correctivas inmediatas:
- Rollback para el ajuste de retries.
- Validación de SLIs después de la mitigación.

Plan de mejoras a mediano y largo plazo:
- Corto plazo
  - Alertas en tasa de retries.
  - Timeouts y límites explícitos, no hardcodeados o embebidos en el código.
  - One-pager runbook de dependencias externas.
- Largo plazo:
  - Despliegues tipo Canary
  - SLOs particulares por dependencia, no solamente componentes de infraestructura.
  - Pipelines de pruebas de estrés.


# Prevención y Mejoras (action items)
Observabilidad: gaps de visibilidad
- No hay medición de error budget por dependencia
- Falta de tracing para diagnósticos precisos

Arquitectura: cambios que prevendrían recurrencias
- Circuit breakers, backoff y rate limiting
- Feature flags para configuración crítica

Procesos:
- Cambios de configuración registrados
- Despliegues tipo Canary obligatorios
- Checklists antes del despliegue

Cultura:
- Blameless postmortems
- Testeo Shift-left y manejor de edge-cases.
- Confiabilidad como producto o feature
- Responsabilidad compartidad entre equipos
