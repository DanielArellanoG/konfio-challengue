# A. Módulo Terraform de Observabilidad
Se definen los entornos de SDLC como módulos raíz independientes entre sí.
Se definen la demo stack y la o11y stack como sub-módulos y se diseñan agnósticos al entorno en el que se usen.
De esta forma, cada módulo raíz define los parámetros particulares para sus entornos y los sub-módulos reciben estos parámetros sin necesidad de saber el entorno donde se ejecuten.
