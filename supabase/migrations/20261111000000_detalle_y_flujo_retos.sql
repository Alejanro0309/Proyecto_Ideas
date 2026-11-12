-- =====================================================================
-- detalle_reto_fullstack.md (sección 3) + flujo_retos_activos.md (sección 3)
-- Contacto de empresa por reto, aceptaciones y flujo completo.
-- Ejecutar COMPLETO en el SQL Editor de Supabase.
-- =====================================================================

-- =====================================================================
-- 1. CONTACTO DE LA EMPRESA POR RETO
-- =====================================================================
create table if not exists public.reto_contactos (
  reto_id uuid primary key references public.retos(id) on delete cascade,
  correo text not null check (correo ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  telefono text check (telefono is null or telefono ~ '^\+?[0-9 ()-]{7,20}$')
);

alter table public.reto_contactos enable row level security;

drop policy if exists "contactos_lectura" on public.reto_contactos;
create policy "contactos_lectura" on public.reto_contactos
  for select to authenticated
  using (exists (
    select 1 from public.retos r
    where r.id = reto_id and r.estado = 'publicado' and r.fecha_limite >= current_date
  ));

drop policy if exists "contactos_admin" on public.reto_contactos;
create policy "contactos_admin" on public.reto_contactos
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- =====================================================================
-- 2. ACEPTACIONES
-- =====================================================================
create table if not exists public.reto_aceptaciones (
  id uuid primary key default gen_random_uuid(),
  reto_id uuid not null references public.retos(id) on delete cascade,
  estudiante_id uuid not null references auth.users(id) on delete cascade,
  estado text not null default 'aceptado'
    check (estado in ('aceptado', 'entregado', 'completado', 'cancelado')),
  aceptado_en timestamptz not null default now(),
  unique (reto_id, estudiante_id)
);

create index if not exists reto_aceptaciones_estudiante_idx
  on public.reto_aceptaciones (estudiante_id);

alter table public.reto_aceptaciones enable row level security;

drop policy if exists "aceptaciones_propias" on public.reto_aceptaciones;
create policy "aceptaciones_propias" on public.reto_aceptaciones
  for select to authenticated
  using (estudiante_id = (select auth.uid()) or public.es_admin());

-- =====================================================================
-- 3. FUNCIONES DE ACEPTACIÓN Y DETALLE
-- =====================================================================
create or replace function public.aceptar_reto(p_reto_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_id uuid;
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;

  if exists (
    select 1 from public.perfiles p
    where p.id = v_uid and p.rol = 'empresa'
  ) then
    raise exception 'SOLO_ESTUDIANTES';
  end if;

  if not exists (
    select 1 from public.retos r
    where r.id = p_reto_id and r.estado = 'publicado' and r.fecha_limite >= current_date
  ) then
    raise exception 'RETO_NO_DISPONIBLE';
  end if;

  insert into public.reto_aceptaciones (reto_id, estudiante_id)
  values (p_reto_id, v_uid)
  returning id into v_id;

  return v_id;
exception
  when unique_violation then
    raise exception 'RETO_YA_ACEPTADO';
end;
$$;

revoke all on function public.aceptar_reto(uuid) from public, anon;
grant execute on function public.aceptar_reto(uuid) to authenticated;

create or replace function public.obtener_reto(p_reto_id uuid)
returns table (
  id uuid,
  titulo text,
  descripcion text,
  entregables text[],
  empresa_nombre text,
  area_slug text,
  area_nombre text,
  habilidades text[],
  duracion_dias smallint,
  presupuesto_usd integer,
  fecha_limite date,
  estado text,
  contacto_correo text,
  contacto_telefono text,
  ya_aceptado boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    r.id,
    r.titulo,
    r.descripcion,
    r.entregables,
    r.empresa_nombre,
    a.slug,
    a.nombre,
    coalesce(
      array(
        select h.nombre
        from public.reto_habilidades rh
        join public.habilidades h on h.id = rh.habilidad_id
        where rh.reto_id = r.id
        order by h.nombre
      ),
      '{}'::text[]
    ),
    r.duracion_dias,
    r.presupuesto_usd,
    r.fecha_limite,
    r.estado,
    c.correo,
    c.telefono,
    exists (
      select 1 from public.reto_aceptaciones x
      where x.reto_id = r.id and x.estudiante_id = (select auth.uid())
    )
  from public.retos r
  join public.areas a on a.id = r.area_id
  left join public.reto_contactos c on c.reto_id = r.id
  where r.id = p_reto_id;
$$;

revoke all on function public.obtener_reto(uuid) from public;
grant execute on function public.obtener_reto(uuid) to anon, authenticated;

-- =====================================================================
-- 4. FLUJO DE RETOS ACTIVOS (flujo_retos_activos.md)
-- =====================================================================
alter table public.reto_aceptaciones
  add column if not exists items_marcados smallint[] not null default '{}',
  add column if not exists entrega_enlace text
    check (entrega_enlace is null or entrega_enlace ~* '^https?://[^\s]{3,200}$'),
  add column if not exists entrega_nota text
    check (entrega_nota is null or length(entrega_nota) <= 1000),
  add column if not exists comentario_revision text
    check (comentario_revision is null or length(comentario_revision) <= 1000),
  add column if not exists enviado_en timestamptz,
  add column if not exists completado_en timestamptz;

create or replace function public.mis_retos()
returns table (
  aceptacion_id uuid,
  reto_id uuid,
  titulo text,
  empresa_nombre text,
  area_nombre text,
  presupuesto_usd integer,
  fecha_limite date,
  estado text,
  entregables text[],
  items_marcados smallint[],
  entrega_enlace text,
  entrega_nota text,
  comentario_revision text,
  aceptado_en timestamptz,
  enviado_en timestamptz,
  completado_en timestamptz,
  contacto_correo text,
  contacto_telefono text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    x.id, r.id, r.titulo, r.empresa_nombre, a.nombre,
    r.presupuesto_usd, r.fecha_limite, x.estado,
    r.entregables, x.items_marcados,
    x.entrega_enlace, x.entrega_nota, x.comentario_revision,
    x.aceptado_en, x.enviado_en, x.completado_en,
    c.correo, c.telefono
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  join public.areas a on a.id = r.area_id
  left join public.reto_contactos c on c.reto_id = r.id
  where x.estudiante_id = (select auth.uid())
    and x.estado <> 'cancelado'
  order by
    case x.estado when 'aceptado' then 0 when 'entregado' then 1 else 2 end,
    r.fecha_limite;
$$;

revoke all on function public.mis_retos() from public, anon;
grant execute on function public.mis_retos() to authenticated;

create or replace function public.marcar_entregable(
  p_aceptacion_id uuid,
  p_indice integer,
  p_marcado boolean
)
returns smallint[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_estado text;
  v_total integer;
  v_items smallint[];
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;

  select x.estado, coalesce(array_length(r.entregables, 1), 0)
    into v_estado, v_total
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  where x.id = p_aceptacion_id and x.estudiante_id = v_uid;

  if not found then raise exception 'ACEPTACION_NO_ENCONTRADA'; end if;
  if v_estado <> 'aceptado' then raise exception 'ESTADO_INVALIDO'; end if;
  if p_indice < 1 or p_indice > v_total then raise exception 'ITEM_INVALIDO'; end if;

  update public.reto_aceptaciones x
  set items_marcados = case
        when p_marcado then (
          select coalesce(array_agg(distinct i order by i), '{}')
          from unnest(x.items_marcados || p_indice::smallint) as i
        )
        else array_remove(x.items_marcados, p_indice::smallint)
      end
  where x.id = p_aceptacion_id
  returning x.items_marcados into v_items;

  return v_items;
end;
$$;

revoke all on function public.marcar_entregable(uuid, integer, boolean) from public, anon;
grant execute on function public.marcar_entregable(uuid, integer, boolean) to authenticated;

create or replace function public.enviar_a_revision(
  p_aceptacion_id uuid,
  p_enlace text default null,
  p_nota text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_estado text;
  v_total integer;
  v_marcados integer;
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;

  select x.estado,
         coalesce(array_length(r.entregables, 1), 0),
         coalesce(cardinality(x.items_marcados), 0)
    into v_estado, v_total, v_marcados
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  where x.id = p_aceptacion_id and x.estudiante_id = v_uid;

  if not found then raise exception 'ACEPTACION_NO_ENCONTRADA'; end if;
  if v_estado <> 'aceptado' then raise exception 'ESTADO_INVALIDO'; end if;
  if v_total > 0 and v_marcados < v_total then
    raise exception 'CHECKLIST_INCOMPLETO';
  end if;

  update public.reto_aceptaciones
  set estado = 'entregado',
      enviado_en = now(),
      entrega_enlace = nullif(trim(p_enlace), ''),
      entrega_nota = nullif(trim(p_nota), ''),
      comentario_revision = null
  where id = p_aceptacion_id;
end;
$$;

revoke all on function public.enviar_a_revision(uuid, text, text) from public, anon;
grant execute on function public.enviar_a_revision(uuid, text, text) to authenticated;

create or replace function public.aprobar_entrega(p_aceptacion_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_estado text;
  v_owner uuid;
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;

  select x.estado, r.empresa_id into v_estado, v_owner
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  where x.id = p_aceptacion_id;

  if not found then raise exception 'ACEPTACION_NO_ENCONTRADA'; end if;
  if not (public.es_admin() or coalesce(v_owner = v_uid, false)) then
    raise exception 'SIN_PERMISO';
  end if;
  if v_estado <> 'entregado' then raise exception 'ESTADO_INVALIDO'; end if;

  update public.reto_aceptaciones
  set estado = 'completado', completado_en = now()
  where id = p_aceptacion_id;
end;
$$;

revoke all on function public.aprobar_entrega(uuid) from public, anon;
grant execute on function public.aprobar_entrega(uuid) to authenticated;

create or replace function public.devolver_entrega(
  p_aceptacion_id uuid,
  p_comentario text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_estado text;
  v_owner uuid;
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;
  if length(trim(coalesce(p_comentario, ''))) < 3 then
    raise exception 'COMENTARIO_REQUERIDO';
  end if;

  select x.estado, r.empresa_id into v_estado, v_owner
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  where x.id = p_aceptacion_id;

  if not found then raise exception 'ACEPTACION_NO_ENCONTRADA'; end if;
  if not (public.es_admin() or coalesce(v_owner = v_uid, false)) then
    raise exception 'SIN_PERMISO';
  end if;
  if v_estado <> 'entregado' then raise exception 'ESTADO_INVALIDO'; end if;

  update public.reto_aceptaciones
  set estado = 'aceptado',
      enviado_en = null,
      comentario_revision = trim(p_comentario)
  where id = p_aceptacion_id;
end;
$$;

revoke all on function public.devolver_entrega(uuid, text) from public, anon;
grant execute on function public.devolver_entrega(uuid, text) to authenticated;

create or replace function public.revisiones_empresa(p_estado text default 'entregado')
returns table (
  aceptacion_id uuid,
  reto_id uuid,
  titulo text,
  empresa_nombre text,
  estudiante_nombre text,
  estudiante_apellido text,
  estado text,
  entregables text[],
  items_marcados smallint[],
  entrega_enlace text,
  entrega_nota text,
  enviado_en timestamptz,
  completado_en timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    x.id, r.id, r.titulo, r.empresa_nombre, p.nombre, p.apellido, x.estado,
    r.entregables, x.items_marcados, x.entrega_enlace, x.entrega_nota,
    x.enviado_en, x.completado_en
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  left join public.perfiles p on p.id = x.estudiante_id
  where x.estado = p_estado
    and p_estado in ('entregado', 'completado')
    and (public.es_admin() or r.empresa_id = (select auth.uid()))
  order by coalesce(x.completado_en, x.enviado_en) desc;
$$;

revoke all on function public.revisiones_empresa(text) from public, anon;
grant execute on function public.revisiones_empresa(text) to authenticated;

-- =====================================================================
-- 5. DATOS FALSOS: descripciones, entregables y contactos (sección 3.2)
-- =====================================================================
update public.retos r
set empresa_nombre = v.empresa,
    descripcion = v.descripcion,
    entregables = v.entregables
from (values
  ('Limpieza y análisis de ventas en Excel', 'Distribuidora Andina (demo)',
   E'Recibirás un archivo de ventas de tres meses con datos duplicados, fechas en formatos distintos y productos mal escritos.\n\nTu trabajo es limpiarlo, unificar los formatos y preparar un resumen con tablas dinámicas que muestre las ventas por producto y por semana.',
   array['Archivo de Excel limpio y sin duplicados', 'Hoja con tablas dinámicas por producto y por semana', 'Resumen de 5 líneas con los hallazgos principales']),
  ('Landing page de producto', 'Startup Brújula (demo)',
   E'Necesitamos una página de aterrizaje para presentar un producto nuevo. Te daremos el diseño y los textos.\n\nDebe verse bien en celular y en computador, y cargar rápido.',
   array['Página en HTML y CSS responsive', 'Código entregado en un archivo comprimido', 'Breve guía para publicarla']),
  ('Identidad visual básica en Canva', 'Café del Ávila (demo)',
   E'Un café pequeño busca una identidad visual sencilla: logo, paleta de colores y plantillas para redes sociales.\n\nBuscamos algo cálido y fácil de reproducir por el equipo.',
   array['Logo en formato PNG y SVG', 'Paleta de 4 colores con sus códigos', '3 plantillas editables en Canva']),
  ('Dashboard de ventas en Power BI', 'Retail Caracas (demo)',
   E'A partir de un Excel de ventas mensuales, construye un tablero con tres indicadores clave: ventas totales, ticket promedio y producto más vendido.\n\nEl tablero debe poder filtrarse por mes.',
   array['Archivo .pbix con el tablero', 'Captura de pantalla del resultado', 'Nota explicando cada indicador']),
  ('Calendario de contenido para Instagram', 'Boutique Sol (demo)',
   E'Plan de contenido de cuatro semanas para una tienda de ropa: ideas de publicaciones, textos cortos y diseños base.\n\nLa marca es cercana y juvenil.',
   array['Calendario de 4 semanas en hoja de cálculo', '12 ideas de publicaciones con texto', '3 diseños base en Canva']),
  ('Redacción de 5 artículos de blog', 'Agencia Norte (demo)',
   E'Cinco artículos de unos 600 palabras sobre emprendimiento, con tono claro y práctico.\n\nCada uno debe incluir título optimizado y una breve descripción para buscadores.',
   array['5 artículos en documento de texto', 'Título y descripción SEO por artículo', 'Lista de palabras clave usadas']),
  ('Script en Python para automatizar reportes', 'Logística Rápida (demo)',
   E'Hoy se arma a mano un reporte semanal a partir de un CSV. Queremos un script que lo genere automáticamente.\n\nSe valorará código ordenado y con instrucciones de uso.',
   array['Script en Python comentado', 'Archivo de ejemplo con el resultado', 'Instrucciones de uso en un README']),
  ('Encuesta y resumen de hallazgos', 'Fundación Impulso (demo)',
   E'Diseña una encuesta corta sobre hábitos de estudio, recolecta al menos 30 respuestas y resume lo que encuentres.\n\nLa presentación final debe ser clara para personas que no son expertas.',
   array['Encuesta publicada y enlace', 'Datos recolectados en una hoja de cálculo', 'Presentación de 5 diapositivas con conclusiones']),
  ('Modelo financiero básico en Excel', 'Consultora Delta (demo)',
   E'Proyección de ingresos y gastos a doce meses para un negocio pequeño, con tres escenarios: base, optimista y pesimista.\n\nTodas las fórmulas deben ser visibles y fáciles de seguir.',
   array['Archivo de Excel con los 3 escenarios', 'Gráfico de ingresos vs. gastos', 'Hoja de supuestos explicados'])
) as v(titulo, empresa, descripcion, entregables)
where r.titulo = v.titulo;

insert into public.reto_contactos (reto_id, correo, telefono)
select r.id, v.correo, v.telefono
from (values
  ('Limpieza y análisis de ventas en Excel', 'contacto@distribuidora-andina.example', '+58 212 555 0101'),
  ('Landing page de producto', 'hola@startup-brujula.example', '+58 212 555 0102'),
  ('Identidad visual básica en Canva', 'info@cafe-del-avila.example', '+58 212 555 0103'),
  ('Dashboard de ventas en Power BI', 'datos@retail-caracas.example', '+58 212 555 0104'),
  ('Calendario de contenido para Instagram', 'marca@boutique-sol.example', '+58 212 555 0105'),
  ('Redacción de 5 artículos de blog', 'editorial@agencia-norte.example', '+58 212 555 0106'),
  ('Script en Python para automatizar reportes', 'tecnologia@logistica-rapida.example', '+58 212 555 0107'),
  ('Encuesta y resumen de hallazgos', 'proyectos@fundacion-impulso.example', '+58 212 555 0108'),
  ('Modelo financiero básico en Excel', 'finanzas@consultora-delta.example', '+58 212 555 0109')
) as v(titulo, correo, telefono)
join public.retos r on r.titulo = v.titulo
on conflict (reto_id) do update
  set correo = excluded.correo, telefono = excluded.telefono;

-- =====================================================================
-- 6. DATOS FALSOS: tres aceptaciones para el admin de pruebas
--    (flujo_retos_activos.md, sección 3.1)
-- =====================================================================
insert into public.reto_aceptaciones
  (reto_id, estudiante_id, estado, items_marcados, entrega_enlace,
   entrega_nota, enviado_en, completado_en, aceptado_en)
select r.id,
       (select p.id from public.perfiles p
        where p.correo = 'admin.prueba@correo.unimet.edu.ve'),
       v.estado, v.marcados, v.enlace, v.nota, v.enviado, v.completado, v.aceptado
from (values
  ('Landing page de producto', 'aceptado', array[1]::smallint[],
   null::text, null::text, null::timestamptz, null::timestamptz,
   now() - interval '3 days'),
  ('Identidad visual básica en Canva', 'entregado', array[1,2,3]::smallint[],
   'https://www.canva.com/design/ejemplo-demo'::text,
   'Adjunto el diseño con las tres plantillas. Quedo atento a comentarios.'::text,
   now() - interval '1 day', null::timestamptz,
   now() - interval '5 days'),
  ('Calendario de contenido para Instagram', 'completado', array[1,2,3]::smallint[],
   'https://docs.google.com/spreadsheets/d/ejemplo-demo'::text,
   'Calendario de 4 semanas listo.'::text,
   now() - interval '4 days', now() - interval '2 days',
   now() - interval '8 days')
) as v(titulo, estado, marcados, enlace, nota, enviado, completado, aceptado)
join public.retos r on r.titulo = v.titulo
on conflict (reto_id, estudiante_id) do update
  set estado = excluded.estado,
      items_marcados = excluded.items_marcados,
      entrega_enlace = excluded.entrega_enlace,
      entrega_nota = excluded.entrega_nota,
      enviado_en = excluded.enviado_en,
      completado_en = excluded.completado_en,
      aceptado_en = excluded.aceptado_en;
