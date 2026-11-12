-- =====================================================================
-- Retos de prueba adicionales (20) para probar el panel y explorar retos.
-- Cada uno con descripción, entregables y contacto ficticio (.example / 555).
-- Se puede repetir sin duplicar (on conflict por título).
-- =====================================================================

insert into public.retos
  (titulo, descripcion, entregables, empresa_nombre, area_id, duracion_dias,
   presupuesto_usd, fecha_limite, estado)
select v.titulo, v.descripcion, v.entregables, v.empresa,
       a.id, v.duracion, v.presupuesto, v.fecha::date, 'publicado'
from (values
  ('Auditoría de redes sociales', 'Revisa las cuentas de Instagram y TikTok de una marca durante 30 días y entrega un diagnóstico con recomendaciones concretas.', array['Diagnóstico en PDF con hallazgos', '5 recomendaciones accionables', 'Calendario de prueba de 2 semanas'], 'Marca Juvenil (demo)', 'marketing', 7, 120, '2027-02-15'),
  ('Diseño de catálogo de productos', 'Diseña un catálogo digital de 12 páginas para una tienda de artesanías, con fichas de producto y precios.', array['Catálogo en PDF de 12 páginas', 'Fichas de producto editables', 'Guía de uso para el equipo'], 'Artesanías del Valle (demo)', 'diseno', 7, 200, '2027-03-01'),
  ('Análisis de competencia en precios', 'Compara los precios de 5 competidores directos y prepara una tabla comparativa con conclusiones.', array['Tabla comparativa en hoja de cálculo', 'Informe de 3 páginas con conclusiones', 'Recomendación de precios'], 'Comercio Local (demo)', 'finanzas', 7, 90, '2027-01-20'),
  ('Creación de manual de marca', 'Escribe un manual de marca de 10 páginas: voz, tono, colores, tipografías y ejemplos de uso.', array['Manual de marca en PDF', 'Paleta de colores con códigos', '3 ejemplos de aplicación'], 'Consultora Creativa (demo)', 'contenido', 7, 180, '2027-02-28'),
  ('App de lista de compras en Flutter', 'Desarrolla una app simple de lista de compras con Flutter: agregar, marcar y eliminar productos.', array['Código fuente en un repositorio', 'APK de prueba', 'README con instrucciones de uso'], 'StartUp Andina (demo)', 'desarrollo', 7, 350, '2027-04-10'),
  ('Dashboard de inventario en Excel', 'Construye un tablero de inventario con control de entradas, salidas y alertas de stock bajo.', array['Archivo de Excel con el tablero', 'Instrucciones de actualización', 'Gráfico de rotación de productos'], 'Distribuidora Oriental (demo)', 'datos', 7, 150, '2027-03-15'),
  ('Guion para 3 videos cortos', 'Escribe el guion de 3 videos de 60 segundos para promocionar un producto en redes sociales.', array['3 guiones con desglose de escenas', 'Sugerencias de música y locaciones', 'Textos para los pies de video'], 'Agencia Creativa Sur (demo)', 'contenido', 7, 110, '2027-02-20'),
  ('Encuesta de satisfacción de clientes', 'Diseña y aplica una encuesta de satisfacción a 40 clientes y resume los resultados.', array['Encuesta publicada', 'Base de datos con respuestas', 'Presentación con conclusiones'], 'Servicios Integrales (demo)', 'investigacion', 7, 130, '2027-03-20'),
  ('Modelo de proyección de ventas', 'Crea un modelo en Excel que proyecte las ventas a 12 meses con tres escenarios.', array['Archivo de Excel con los escenarios', 'Gráfico de tendencia', 'Hoja de supuestos explicada'], 'Finanzas Claras (demo)', 'finanzas', 7, 170, '2027-04-05'),
  ('Diseño de empaque sostenible', 'Propone un diseño de empaque reciclable para un producto alimenticio, con materiales y costos estimados.', array['Propuesta de diseño en PDF', 'Lista de materiales y costos', '2 alternativas de empaque'], 'Alimentos Naturales (demo)', 'diseno', 7, 260, '2027-05-01'),
  ('Automatización de reporte con Python', 'Escribe un script que lea un CSV y genere un reporte en PDF con gráficos automáticamente.', array['Script en Python comentado', 'Ejemplo de reporte generado', 'Instrucciones de ejecución'], 'Logística del Este (demo)', 'desarrollo', 7, 240, '2027-04-20'),
  ('Plan de contenidos para LinkedIn', 'Prepara un plan de 4 semanas de publicaciones en LinkedIn para una empresa de servicios profesionales.', array['Calendario de 4 semanas', '12 textos de publicación', '5 ideas de carrusel'], 'Consultora Profesional (demo)', 'marketing', 7, 140, '2027-03-25'),
  ('Análisis de datos de encuestas', 'Procesa una base de datos de encuestas y entrega un informe con los hallazgos principales.', array['Informe de hallazgos', 'Gráficos de las preguntas clave', 'Recomendaciones basadas en datos'], 'Instituto de Estudios (demo)', 'datos', 7, 160, '2027-04-15'),
  ('Redacción de comunicado de prensa', 'Redacta un comunicado de prensa de 400 palabras para el lanzamiento de un nuevo servicio.', array['Comunicado en documento de texto', 'Versión de 200 palabras', 'Lista de medios sugeridos'], 'Fundación Proyecto (demo)', 'contenido', 5, 80, '2027-02-10'),
  ('Diseño de folleto institucional', 'Diseña un folleto a dos caras para una fundación sin fines de lucro.', array['Folleto en PDF listo para imprimir', 'Versión digital', 'Paleta y tipografías usadas'], 'Fundación Manos (demo)', 'diseno', 7, 100, '2027-03-10'),
  ('Prototipo de app de reservas', 'Crea un prototipo navegable de una app para reservar citas médicas.', array['Prototipo en Figma o similar', 'Flujo de pantallas documentado', 'Notas de usabilidad'], 'Salud Digital (demo)', 'desarrollo', 7, 280, '2027-05-15'),
  ('Estudio de tiempos de atención', 'Mide los tiempos de atención en una sucursal durante una semana y propone mejoras.', array['Informe con mediciones', 'Gráfico de tiempos por día', '3 propuestas de mejora'], 'Retail del Centro (demo)', 'investigacion', 7, 120, '2027-03-30'),
  ('Diseño de factura y papelería', 'Diseña factura, nota de entrega y tarjeta de presentación para una empresa de servicios.', array['3 piezas en PDF listas para imprimir', 'Versión editable', 'Paleta de colores corporativa'], 'Servicios Técnicos (demo)', 'diseno', 7, 130, '2027-04-01')
) as v(titulo, descripcion, entregables, empresa, area, duracion, presupuesto, fecha)
join public.areas a on a.slug = v.area
where not exists (
  select 1 from public.retos r where r.titulo = v.titulo
);

-- Contactos ficticios para los retos nuevos
insert into public.reto_contactos (reto_id, correo, telefono)
select r.id, v.correo, v.telefono
from (values
  ('Auditoría de redes sociales', 'contacto@marca-juvenil.example', '+58 212 555 0201'),
  ('Diseño de catálogo de productos', 'info@artesanias-valle.example', '+58 212 555 0202'),
  ('Análisis de competencia en precios', 'ventas@comercio-local.example', '+58 212 555 0203'),
  ('Creación de manual de marca', 'hola@consultora-creativa.example', '+58 212 555 0204'),
  ('App de lista de compras en Flutter', 'dev@startup-andina.example', '+58 212 555 0205'),
  ('Dashboard de inventario en Excel', 'operaciones@distribuidora-oriental.example', '+58 212 555 0206'),
  ('Guion para 3 videos cortos', 'produccion@agencia-sur.example', '+58 212 555 0207'),
  ('Encuesta de satisfacción de clientes', 'experiencia@servicios-integrales.example', '+58 212 555 0208'),
  ('Modelo de proyección de ventas', 'planeacion@finanzas-claras.example', '+58 212 555 0209'),
  ('Diseño de empaque sostenible', 'proyectos@alimentos-naturales.example', '+58 212 555 0210'),
  ('Automatización de reporte con Python', 'sistemas@logistica-este.example', '+58 212 555 0211'),
  ('Plan de contenidos para LinkedIn', 'marketing@consultora-profesional.example', '+58 212 555 0212'),
  ('Análisis de datos de encuestas', 'estudios@instituto.example', '+58 212 555 0213'),
  ('Redacción de comunicado de prensa', 'prensa@fundacion-proyecto.example', '+58 212 555 0214'),
  ('Diseño de folleto institucional', 'comunicacion@fundacion-manos.example', '+58 212 555 0215'),
  ('Prototipo de app de reservas', 'producto@salud-digital.example', '+58 212 555 0216'),
  ('Estudio de tiempos de atención', 'calidad@retail-centro.example', '+58 212 555 0217'),
  ('Diseño de factura y papelería', 'administracion@servicios-tecnicos.example', '+58 212 555 0218')
) as v(titulo, correo, telefono)
join public.retos r on r.titulo = v.titulo
on conflict (reto_id) do update
  set correo = excluded.correo, telefono = excluded.telefono;

select count(*) as total_retos from public.retos;
select count(*) as total_contactos from public.reto_contactos;
