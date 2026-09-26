# BODYCAM â€” Historial de versiones

## 1.0.0 — Primera version publica

El usuario aprobo la experiencia y el disparo de 0.15.0 para publicacion.
Antes de publicar, el usuario autorizo reemplazar el ZIP 1.0.0 e integrar
la correccion del aviso inicial INERTIA/Wrist. Se retira el paquete 1.0.1.
La confirmacion normal del control muestra solamente BODYCAM | ON/OFF.

- BODYCAM Mode: unico control, F8 inicial reasignable, estado ON/OFF persistente.
- Primera instalacion: vista Bodycam, inercia Wrist y FreeAim activos.
- OFF restaura postura, inercia y disparo nativos y reinicia FreeAim; ON recupera
  la configuracion aprobada. Cancela el seguimiento pendiente al alternar.
- Scripts agrupados en lua/, tuning en config/, textos publicos en ingles.
- ZIP publico con lista explicita de archivos: sin pruebas, documentos de
  desarrollo, configuracion personal ni respaldos. Licencia de Brouken sin
  permiso de modificacion o redistribucion; README de instalacion y uso.
- Cinco pruebas LuaJIT correctas, incluidas persistencia, reasignacion y ciclos
  ON/OFF desde hip y ADS lateral. Verificacion en juego del control final pendiente.
- Estado previo aprobado conservado en BODYCAM-0.15.0-approved-development.zip.

## 0.15.0 â€” Experimental: direccion del disparo

- `firing.lua` lee el eje mundial del caÃ±on al ejecutar cada disparo normal
  del jugador local en vista Bodycam. Sin copiar calculos de FreeAim/inercia.
- Conserva origen nativo, dispersion, asistencia nativa, daÃ±o, municion y retorno.
  Direccion paralela al caÃ±on: no significa salida fisica desde su boca ni
  coincidencia exacta con la mira a todas las distancias.
- Vanilla, VR, otros jugadores, estados especiales, gadgets activos y recorridos
  de disparo no verificados conservan direccion nativa. Primera prueba: pistola
  y fusil hitscan. Akimbo consulta la postura propia al emitir cada disparo.
- Movimiento 0.14.1 intacto; ZIP estable preservado. Interaccion con paredes,
  origen fisico y retroceso nuevo quedan para experimentos separados.
- Prueba automatizada `tests/firing_step4.lua`; validacion en juego pendiente.

## 0.14.1 â€” Estable

Cierre aprobado por el usuario tras validar miras de hierro, opticas y laterales.

- Alineacion ADS: posicion y orientacion giran juntas sobre el origen de camara.
- Ejes ADS de camara para evitar cruce horizontal/vertical con armas inclinadas.
- Miras laterales incluidas en ADS; transiciones entre miras sin offsets de hip.
- Lectura spin/pitch nativa en la mira lateral, excluyendo seguimiento automatico.
  Evita deriva lateral al subir/bajar; hip y mira principal conservan su lectura.
- Restauracion exacta de la postura limpia, sin deriva numerica acumulada.
- Sensibilidad, inercia y parametros de seguimiento conservados. El usuario
  confirma que el retraso percibido proviene de inercia y desea mantenerlo.
- Tres regresiones automatizadas correctas. ZIP congelado con SHA-256.
  Referencias anteriores preservadas. El cierre no cambia movimiento.

## 0.14.0 â€” Estable (2026-09-24)

Aprobada por el usuario tras prueba de juego. Presets Default/Wrist, vistas
Bodycam/Vanilla, apoyo del arma y seguimiento horizontal/ADS proporcional.
HUD INERCIA/VISTA. Limitacion conocida: alineacion ADS inconsistente en armas
largas; se investigara por separado. ZIP congelado con SHA-256; versiones
0.13.1 y 0.13.0 preservadas. Este cierre no cambia el movimiento.

### Historial de experimentos incorporados

- HUD de presets: BODYCAM | INERCIA | Default/Wrist. Vistas conservan
  BODYCAM | VISTA | Bodycam/Vanilla. Detalles de recarga en consola.
  Sin cambios de movimiento; prueba final aprobada por el usuario.

- Sensacion Wrist + Seguimiento ADS aprobada por el usuario. Selector reducido
  a Bodycam (antes Seguimiento ADS, vista inicial) y Vanilla. Presets Default
  y Wrist; HYBRID retirado. Sin cambios a parametros ni matematicas de movimiento.
  Alineacion de miras en armas largas pendiente de investigacion separada.
  Los ZIP estables permanecen intactos.

- Ajuste ADS: conserva centrado suave al soltar el mouse. Factor base 0.5
  mas un extra proporcional al giro (hasta 1.5 total), suavizado en 0.06 s.
  Mantiene margen de 1 grado y frenado al acercarse. Sustituye el apagado
  completo de la prueba anterior; seguimiento sin apuntar intacto.
  Pendiente validacion de sensacion en juego.

- Prueba anterior, reemplazada: ADS proporcional al giro horizontal: factor suavizado segun velocidad de
  entrada, con limite de 1.5 veces la respuesta nominal. Al detener el mouse,
  se desvanece y se apaga en 0.18 s, sin exigir centrado perfecto. Excluye el
  giro automatico al medir velocidad. Sin cambios al seguimiento sin apuntar.
  Pruebas simuladas 30/60/144 FPS correctas; sensacion en juego pendiente.

- Seguimiento ADS acelerado por pedido del usuario: tasa 4.8/s y limite
  24 grados/s (antes 1.2/s y 6 grados/s). Conserva frenado exponencial,
  margen de 1 grado y comportamiento sin apuntar. Pendiente prueba de juego.

- Seguimiento horizontal aprobado en sensacion por el usuario. Se conserva
  para comparar con la nueva vista Seguimiento ADS, que agrega seguimiento
  horizontal al terminar de entrar en la mira: margen 1 grado, tasa 1.2/s,
  limite 6 grados/s. Sin cambios al movimiento sin apuntar ni al eje vertical.
  No aplica durante transiciones/reversiones. ads_follow_rate=0 lo desactiva.
  Pruebas simuladas correctas; alineacion y disparos en juego pendientes.

- Nueva vista Seguimiento, conservando MuÃ±eca al iniciar y Vanilla. Prueba
  horizontal: transfiere giro FreeAim a la camara nativa fuera de un margen
  libre de 3 grados, a tasa 1.8/s con limite de 10 grados/s. No aplica en ADS
  ni transiciones. Excluye su contribucion del seguimiento de entrada para
  evitar realimentacion. Pruebas simuladas de ambos lados y 30/60/144 FPS
  correctas; sensacion, punteria y compatibilidad real pendientes.

- Prueba rechazada por sensacion: retorno automatico. Se desactiva en todos
  los perfiles (hip_recenter_speed = 0), recuperando FreeAim persistente.
  Se conserva el ajuste opcional para comparaciones explicitas.
- La prueba de retorno del arma al centro tras 0.25 s sin entrada de mirada,
  con suavizado exponencial (hip_recenter_speed = 3; 0 desactiva el retorno).
  Se interrumpe al mover el mouse; no actua en ADS, transiciones, entrada
  bloqueada ni VR. No gira la camara. El usuario prefiere MuÃ±eca sin este retorno.

- Antes de Seguimiento, el selector quedo en MuÃ±eca <-> Vanilla. Se retiraron
  Actual, Experimental y MuÃ±eca + cÃ¡mara por pedido del usuario. Se elimina
  el seguimiento de cÃ¡mara rechazado; el ZIP estable permanece intacto.
- Ajuste de encuadre aprobado por el usuario: hip_center_x pasa de -5 a -5.5
  en los tres perfiles para centrar ligeramente el cuerpo del arma. Altura,
  profundidad, inclinacion y comportamiento de MuÃ±eca se conservan.
- MuÃ±eca usa la perspectiva de Experimental y toma como apoyo del giro de
  FreeAim el punto animado de sujecion del arma. Sustituye el apoyo aproximado
  de la primera prueba; `hip_freeaim_pivot_y = 20` queda como respaldo si el
  modelo no ofrece ese punto (0 sigue desactivando la correccion).
  Compensa la traslacion para girar alrededor de ese punto, buscando menos
  recorrido del agarre y mas protagonismo del canon. No anima huesos.
- El apoyo vuelve progresivamente al origen anterior durante ADS; al apuntar
  por completo conserva 0.13.1. FreeAim OFF tampoco aplica la compensacion.
  Sensibilidad, limites, inercia, recarga y retroceso no cambian.
- El usuario prefiere el apoyo de MuÃ±eca. Pendiente evaluar el nuevo centrado
  con Wrist y comprobar la alternancia con Vanilla. Valor 0 permite desactivar
  el apoyo. ZIP estable 0.13.1 intacto.
- Pruebas verifican apoyo fijo, recorrido del canon, ausencia de acumulacion,
  transiciones/reversiones ADS y restauracion; simulador de rotacion corregido
  para representar pitch sobre X y roll sobre Y con avance en Y.

## 0.13.1 â€” Estable

Baseline aprobado por el usuario con las tres vistas: Actual, Experimental
y Vanilla. Se conserva Actual al iniciar, el boton de comparacion, todos
los presets y los parametros de movimiento sin cambios.

- Archivo congelado: `releases/BODYCAM-0.13.1-stable.zip`, con SHA-256.
- Se elimina por solicitud expresa el respaldo intermedio
  `BODYCAM-0.13.1-before-view-comparison.zip` y su checksum, despues de
  verificar la nueva copia estable. Se conservan las versiones 0.13.0.
- Las tres pruebas automatizadas pasan. La validacion en juego no implica
  ausencia garantizada de errores. El siguiente experimento de apoyo del
  arma/recorrido del canon queda fuera de esta version.

### Historial de las pruebas que condujeron a esta version

Las menciones siguientes a pruebas pendientes describen su estado durante
la iteracion; el conjunto de tres vistas fue aprobado al cerrar 0.13.1.

- El usuario considera muy buena la postura con offsets (-5, -3, -3).
  Guardada antes del siguiente experimento en
  `releases/BODYCAM-0.13.1-before-view-comparison.zip`, con checksum.
- Nueva tecla asignable `BODYCAM - Comparar vista`: Actual -> Experimental
  -> Vanilla -> Actual, con HUD corto y reinicio de FreeAim para comparar.
  Actual es el inicio por defecto y conserva la postura anterior.
  Experimental agrega solo `experimental_hip_pitch = -3` en reposo, retirado
  gradualmente en ADS. Vanilla suspende los offsets/FreeAim de BODYCAM y
  restaura inercia nativa; conserva preset y preferencia ON/OFF.
  No afecta otros mods. La orientacion experimental queda pendiente de prueba.
- Cuarta prueba: tras la mejora de sensacion reportada con la altura -3,
  se agrega `hip_center_y = -3` para acercar arma/manos a la camara sin
  apuntar. Lateral -5 y altura -3 se conservan; misma retirada en ADS.
  Profundidad pendiente de prueba. Poner `hip_center_y = 0` vuelve a la
  tercera prueba, sin perder su centrado ni altura.
- Tercera prueba: se conserva el lateral -5, preferido por el usuario, y se
  agrega `hip_center_z = -3` en todos los perfiles para bajar el arma sin
  apuntar. Usa la misma retirada gradual en ADS, con FreeAim ON u OFF.
  Profundidad, orientacion e inercia sin cambios. Altura pendiente de prueba.
  Para volver a la segunda prueba basta poner `hip_center_z = 0`.
- Segunda prueba: `hip_center_x` pasa de -3 a -5 en los tres perfiles a
  pedido del usuario, buscando un centrado mas visible. Solo cambia el
  desplazamiento lateral; altura y orientacion quedan para evaluar despues.
- Primera prueba de perspectiva: `hip_center_x = -3` en los tres perfiles,
  independiente de FreeAim, sin cambiar altura, profundidad ni inercia.
  Se desvanece con el progreso de la postura nativa al apuntar; en ADS es cero.
  Poner `hip_center_x = 0` restaura la posicion previa a esta prueba.

- Inercia independiente del interruptor de FreeAim: DEFAULT usa los valores
  nativos de la postura/arma; HYBRID y Wrist aplican sus valores con FreeAim
  tanto activado como desactivado.
- `use_vanilla_inertia` selecciona el comportamiento por perfil y se valida
  como booleano. Si se omite, se conserva la inercia personalizada.
- La tecla ON/OFF controla solo FreeAim. Parametros de HYBRID/Wrist y calculo
  de FreeAim sin cambios en la separacion inicial de inercia.
- El usuario confirmo que la separacion funciona. Se adopto 0.13.1 por su
  criterio de numeracion para esta iteracion; la copia estable 0.13.0 permanece
  intacta. El centrado lateral posterior aun requiere prueba en juego.

## Mantenimiento del workspace posterior a 0.13.0

- Copias intermedias, captura del bloqueo y prueba del diagnostico retirado
  agrupadas en `releases/BODYCAM-pre-0.13.0-history.zip`, con checksum SHA-256.
- Se retiraron los archivos historicos sueltos despues de verificar el ZIP.
- AGENTS.md actualizado con las ubicaciones y responsabilidades actuales.
- Esta limpieza no cambio el codigo activo, parametros ni version del mod.

## Revision de la copia estable 0.13.0

- Por solicitud expresa del usuario, se incorporo el formato de HUD
  `BODYCAM | 3/3 | Wrist` a la version estable, sin cambiar su numero ni movimiento.
- El ZIP estable incluye el codigo, la prueba de HUD y la documentacion actuales;
  se regenero su checksum SHA-256.
- La copia anterior y su checksum se conservan como
  `releases/BODYCAM-0.13.0-stable-before-hud-order.zip` y su archivo `.sha256`.

## 0.13.0 â€” Estable

Baseline aprobado por el usuario tras pruebas dentro de PAYDAY 2.
Es la referencia para continuar el desarrollo; no una version final.

### Cambios respecto de 0.12.2

- Captura y restauracion de overshot vinculadas a su instancia y actualizadas
  al cambiar de postura; se respetan las transiciones nativas al desactivar.
- Correccion del shoulder offset: se retira antes de que el juego copie o
  reemplace la postura. El bloqueo aparente al invertir movimientos rapidos
  dejo de aparecer en la prueba del usuario.
- Validacion de tuning antes de aplicarlo. Una recarga invalida conserva los
  perfiles, el estado ON/OFF y el estado de FreeAim anteriores.
- Una sola tecla recarga, valida y cambia de preset. Se retiro la tecla de
  recarga independiente.
- HUD de presets: `BODYCAM | 3/3 | Wrist`. Confirmaciones completas en consola.
- Preset `EXPERIMENTAL - WRIST` renombrado a `Wrist`.
- Diagnostico temporal retirado del mod activo; captura y material historico
  conservados en el workspace.

Los parametros de movimiento de DEFAULT, HYBRID y Wrist se conservaron.
El marcado de esta version no introduce cambios de movimiento adicionales.
Los identificadores historicos de hooks se conservan para no cambiar su identidad.

### Validacion

- Usuario: funcionamiento correcto en las pruebas de gameplay solicitadas,
  sin reaparicion del bloqueo y con buena sensacion de movimiento.
- LuaJIT 5.1 con interfaces del juego simuladas: shoulder, overshot y tuning,
  incluidos 107 casos invalidos, recarga/cambio de perfil y formato de HUD.
- Las pruebas automatizadas no sustituyen la ejecucion dentro de PAYDAY 2.

### Copia estable

`releases/BODYCAM-0.13.0-stable.zip` contiene la carpeta `BODYCAM` con los siete
archivos de ejecucion, AGENTS.md, este historial y las tres pruebas activas.
No incluye CodeGraph, capturas, diagnosticos retirados ni backups anteriores.
El archivo `.sha256` adyacente permite comprobar su integridad.

Para volver a esta base: cerrar el juego, guardar aparte el trabajo posterior
y restaurar los archivos del ZIP en `mods/BODYCAM`. Al regresar desde una version
que agregue scripts, revisar tambien sus registros en `mod.txt`.
No sobrescribir esta copia estable con experimentos posteriores.

## Criterio a partir de 0.13.0

- `0.13.1`, `0.13.2`, etc.: correcciones y ajustes menores.
- `0.14.0`, etc.: nuevas funciones o cambios relevantes de movimiento.
- `1.0.0`: primera version considerada completa por el usuario.
- Estable: version probada y aceptada expresamente por el usuario como baseline.
  Los cambios posteriores no heredan automaticamente esa aprobacion.
- Al cerrar una version, sincronizar `mod.txt`, mensajes de inicio, cabeceras e
  historial, ejecutar las pruebas pertinentes y guardar una nueva copia.
