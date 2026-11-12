-- =====================================================================
-- EXPLORAR RETOS — script de entrega (según explorar_retos_fullstack.md)
-- Ejecutar COMPLETO y UNA sola vez en el SQL Editor de Supabase.
-- Incluye limpieza de la tabla `retos` creada con un esquema anterior
-- incompatible, y recrea `postulaciones` / `logros` adaptados.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. LIMPIEZA (solo por el esquema anterior incompatible)
--    `retos` se elimina en cascada y se recrea con el esquema nuevo.
--    `postulaciones` y `logros` dependen de `retos` y se recrean abajo.
-- ---------------------------------------------------------------------
drop table if exists public.reto_habilidades cascade;
drop table if exists public.postulaciones cascade;
drop table if exists public.logros cascade;
drop table if exists public.retos cascade;

-- `es_admin()` del documento necesita `perfiles.rol`.
-- Se añade si no existe; NO modifica los datos actuales.
alter table public.perfiles
  add column if not exists rol text not null default 'estudiante';

-- =====================================================================
-- 1. CATÁLOGOS
-- =====================================================================
create table if not exists public.areas (
  id smallint generated always as identity primary key,
  slug text not null unique,
  nombre text not null unique,
  orden smallint not null default 0
);

create table if not exists public.habilidades (
  id integer generated always as identity primary key,
  slug text not null unique,
  nombre text not null unique
);

-- =====================================================================
-- 2. RETOS
-- =====================================================================
create table if not exists public.retos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid references auth.users(id) on delete set null,
  empresa_nombre text not null,
  titulo text not null check (length(trim(titulo)) between 5 and 120),
  descripcion text not null default '',
  entregables text[] not null default '{}',
  area_id smallint not null references public.areas(id),
  duracion_dias smallint not null check (duracion_dias between 1 and 7),
  presupuesto_usd integer not null check (presupuesto_usd > 0),
  fecha_limite date not null,
  estado text not null default 'borrador'
    check (estado in ('borrador', 'publicado', 'cerrado', 'completado')),
  creado_en timestamptz not null default now()
);

create table if not exists public.reto_habilidades (
  reto_id uuid not null references public.retos(id) on delete cascade,
  habilidad_id integer not null references public.habilidades(id) on delete cascade,
  primary key (reto_id, habilidad_id)
);

create index if not exists retos_estado_fecha_idx on public.retos (estado, fecha_limite);
create index if not exists retos_area_idx on public.retos (area_id);
create index if not exists retos_presupuesto_idx on public.retos (presupuesto_usd);
create index if not exists retos_duracion_idx on public.retos (duracion_dias);
create index if not exists reto_habilidades_hab_idx on public.reto_habilidades (habilidad_id);

-- =====================================================================
-- 3. SEGURIDAD (RLS)
-- =====================================================================
alter table public.areas enable row level security;
alter table public.habilidades enable row level security;
alter table public.retos enable row level security;
alter table public.reto_habilidades enable row level security;

-- Función auxiliar: ¿el usuario actual es admin?
create or replace function public.es_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.perfiles p
    where p.id = (select auth.uid()) and p.rol = 'admin'
  );
$$;

revoke all on function public.es_admin() from public, anon;
grant execute on function public.es_admin() to authenticated;

-- Lectura: los retos publicados y vigentes son información pública.
drop policy if exists "areas_lectura" on public.areas;
create policy "areas_lectura" on public.areas
  for select to anon, authenticated using (true);

drop policy if exists "habilidades_lectura" on public.habilidades;
create policy "habilidades_lectura" on public.habilidades
  for select to anon, authenticated using (true);

drop policy if exists "retos_publicados_lectura" on public.retos;
create policy "retos_publicados_lectura" on public.retos
  for select to anon, authenticated
  using (estado = 'publicado' and fecha_limite >= current_date);

drop policy if exists "reto_habilidades_lectura" on public.reto_habilidades;
create policy "reto_habilidades_lectura" on public.reto_habilidades
  for select to anon, authenticated
  using (exists (
    select 1 from public.retos r
    where r.id = reto_id and r.estado = 'publicado' and r.fecha_limite >= current_date
  ));

-- Escritura: por ahora solo administradores (las empresas se definen después).
drop policy if exists "areas_admin" on public.areas;
create policy "areas_admin" on public.areas
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists "habilidades_admin" on public.habilidades;
create policy "habilidades_admin" on public.habilidades
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists "retos_admin" on public.retos;
create policy "retos_admin" on public.retos
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists "reto_habilidades_admin" on public.reto_habilidades;
create policy "reto_habilidades_admin" on public.reto_habilidades
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- =====================================================================
-- 4. DATOS INICIALES DE CATÁLOGO
-- =====================================================================
insert into public.areas (slug, nombre, orden) values
  ('datos', 'Datos', 1),
  ('desarrollo', 'Desarrollo', 2),
  ('diseno', 'Diseño', 3),
  ('marketing', 'Marketing', 4),
  ('contenido', 'Redacción y contenido', 5),
  ('finanzas', 'Finanzas y administración', 6),
  ('investigacion', 'Investigación', 7),
  ('otro', 'Otro', 99)
on conflict (slug) do nothing;

insert into public.habilidades (slug, nombre) values
  ('excel', 'Excel'),
  ('tablas-dinamicas', 'Tablas dinámicas'),
  ('power-bi', 'Power BI'),
  ('analisis-datos', 'Análisis de datos'),
  ('sql', 'SQL'),
  ('python', 'Python'),
  ('html', 'HTML'),
  ('css', 'CSS'),
  ('javascript', 'JavaScript'),
  ('flutter', 'Flutter'),
  ('figma', 'Figma'),
  ('canva', 'Canva'),
  ('branding', 'Branding'),
  ('redes-sociales', 'Redes sociales'),
  ('seo', 'SEO'),
  ('redaccion', 'Redacción'),
  ('investigacion', 'Investigación'),
  ('presentaciones', 'Presentaciones')
on conflict (slug) do nothing;

-- =====================================================================
-- 5. FUNCIÓN DE BÚSQUEDA CON FILTROS
-- =====================================================================
create or replace function public.buscar_retos(
  p_area text default null,                  -- slug del área; null = todas
  p_habilidades text[] default null,         -- slugs; coincide con al menos una
  p_duracion_max integer default null,       -- días; null = cualquiera
  p_presupuesto_min integer default null,    -- USD; null = sin mínimo
  p_presupuesto_max integer default null,    -- USD; null = sin máximo
  p_orden text default 'recientes',          -- 'recientes' | 'presupuesto' | 'cierran_pronto'
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  id uuid,
  titulo text,
  empresa_nombre text,
  area_slug text,
  area_nombre text,
  habilidades text[],
  duracion_dias smallint,
  presupuesto_usd integer,
  fecha_limite date,
  creado_en timestamptz,
  total bigint
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    r.id,
    r.titulo,
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
    r.creado_en,
    count(*) over() as total
  from public.retos r
  join public.areas a on a.id = r.area_id
  where r.estado = 'publicado'
    and r.fecha_limite >= current_date
    and (p_area is null or a.slug = p_area)
    and (p_duracion_max is null or r.duracion_dias <= p_duracion_max)
    and (p_presupuesto_min is null or r.presupuesto_usd >= p_presupuesto_min)
    and (p_presupuesto_max is null or r.presupuesto_usd <= p_presupuesto_max)
    and (
      p_habilidades is null
      or cardinality(p_habilidades) = 0
      or exists (
        select 1
        from public.reto_habilidades rh
        join public.habilidades h on h.id = rh.habilidad_id
        where rh.reto_id = r.id and h.slug = any (p_habilidades)
      )
    )
  order by
    case when p_orden = 'presupuesto' then r.presupuesto_usd end desc,
    case when p_orden = 'cierran_pronto' then r.fecha_limite end asc,
    r.creado_en desc
  limit least(greatest(p_limit, 1), 50)
  offset greatest(p_offset, 0);
$$;

revoke all on function public.buscar_retos(text, text[], integer, integer, integer, text, integer, integer) from public;
grant execute on function public.buscar_retos(text, text[], integer, integer, integer, text, integer, integer) to anon, authenticated;

-- =====================================================================
-- 6. DATOS DE EJEMPLO (fechas relativas a hoy)
-- =====================================================================
with nuevos as (
  insert into public.retos
    (empresa_nombre, titulo, descripcion, area_id, duracion_dias,
     presupuesto_usd, fecha_limite, estado)
  select v.empresa, v.titulo, v.descripcion, a.id, v.dias, v.usd,
         current_date + v.cierra, 'publicado'
  from (values
    ('Empresa de demostración', 'Limpieza y análisis de ventas en Excel',
     'Limpiar un archivo de ventas y entregar un resumen con tablas dinámicas.',
     'datos', 2, 45, 12),
    ('Empresa de demostración', 'Landing page de producto',
     'Maquetar una página de aterrizaje responsive a partir de un diseño dado.',
     'desarrollo', 7, 150, 20),
    ('Empresa de demostración', 'Identidad visual básica en Canva',
     'Logo simple, paleta y plantillas para redes de un emprendimiento.',
     'diseno', 3, 60, 9),
    ('Empresa de demostración', 'Dashboard de ventas en Power BI',
     'Construir un tablero con 3 indicadores clave a partir de un Excel.',
     'datos', 5, 120, 15),
    ('Empresa de demostración', 'Calendario de contenido para Instagram',
     'Plan de 4 semanas con ideas de publicaciones y diseños base.',
     'marketing', 3, 40, 7),
    ('Empresa de demostración', 'Redacción de 5 artículos de blog',
     'Cinco artículos de 600 palabras optimizados para buscadores.',
     'contenido', 4, 80, 18),
    ('Empresa de demostración', 'Script en Python para automatizar reportes',
     'Automatizar la generación de un reporte semanal desde un CSV.',
     'desarrollo', 5, 180, 25),
    ('Empresa de demostración', 'Encuesta y resumen de hallazgos',
     'Diseñar una encuesta, recolectar respuestas y presentar conclusiones.',
     'investigacion', 3, 70, 10),
    ('Empresa de demostración', 'Modelo financiero básico en Excel',
     'Proyección de ingresos y gastos a 12 meses con escenarios.',
     'finanzas', 4, 210, 22)
  ) as v(empresa, titulo, descripcion, area, dias, usd, cierra)
  join public.areas a on a.slug = v.area
  returning id, titulo
)
insert into public.reto_habilidades (reto_id, habilidad_id)
select n.id, h.id
from nuevos n
join (values
  ('Limpieza y análisis de ventas en Excel', 'excel'),
  ('Limpieza y análisis de ventas en Excel', 'tablas-dinamicas'),
  ('Landing page de producto', 'html'),
  ('Landing page de producto', 'css'),
  ('Identidad visual básica en Canva', 'canva'),
  ('Identidad visual básica en Canva', 'branding'),
  ('Dashboard de ventas en Power BI', 'power-bi'),
  ('Dashboard de ventas en Power BI', 'analisis-datos'),
  ('Calendario de contenido para Instagram', 'redes-sociales'),
  ('Calendario de contenido para Instagram', 'canva'),
  ('Redacción de 5 artículos de blog', 'redaccion'),
  ('Redacción de 5 artículos de blog', 'seo'),
  ('Script en Python para automatizar reportes', 'python'),
  ('Script en Python para automatizar reportes', 'sql'),
  ('Encuesta y resumen de hallazgos', 'investigacion'),
  ('Encuesta y resumen de hallazgos', 'presentaciones'),
  ('Modelo financiero básico en Excel', 'excel')
) as m(titulo, hab) on m.titulo = n.titulo
join public.habilidades h on h.slug = m.hab;

-- =====================================================================
-- 7. RECREACIÓN de postulaciones y logros (adaptados al esquema nuevo)
--    Se recrean porque dependían de la tabla `retos` anterior.
-- =====================================================================
create table public.postulaciones (
  id uuid primary key default gen_random_uuid(),
  reto_id uuid not null references public.retos(id) on delete cascade,
  estudiante_id uuid not null default auth.uid()
    references public.perfiles(id) on delete cascade,
  estado text not null default 'en_curso'
    check (estado in ('en_curso', 'en_revision', 'completado', 'vencido')),
  avance numeric(4,3) not null default 0
    check (avance between 0 and 1),
  fecha_entrega timestamptz,
  creado_en timestamptz not null default now(),
  unique (reto_id, estudiante_id)
);

create index postulaciones_estudiante_idx
  on public.postulaciones(estudiante_id);

alter table public.postulaciones enable row level security;

create policy "Ver mis postulaciones"
  on public.postulaciones for select to authenticated
  using (estudiante_id = (select auth.uid()));

create policy "Gestionar mis postulaciones"
  on public.postulaciones for all to authenticated
  using (estudiante_id = (select auth.uid()))
  with check (estudiante_id = (select auth.uid()));

create table public.logros (
  id uuid primary key default gen_random_uuid(),
  estudiante_id uuid not null default auth.uid()
    references public.perfiles(id) on delete cascade,
  reto_id uuid not null references public.retos(id) on delete cascade,
  titulo text not null,
  empresa text not null,
  habilidades text[] not null default '{}',
  visible boolean not null default true,
  creado_en timestamptz not null default now(),
  unique (estudiante_id, reto_id)
);

create index logros_estudiante_idx on public.logros(estudiante_id);

alter table public.logros enable row level security;

create policy "Ver mis logros"
  on public.logros for select to authenticated
  using (estudiante_id = (select auth.uid()));

create policy "Gestionar mis logros"
  on public.logros for all to authenticated
  using (estudiante_id = (select auth.uid()))
  with check (estudiante_id = (select auth.uid()));

create or replace function public.marcar_postulacion_completada(p_postulacion uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_reto public.retos%rowtype;
  v_post public.postulaciones%rowtype;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('success', false, 'error', 'unauthorized');
  end if;

  select * into v_post
  from public.postulaciones
  where id = p_postulacion and estudiante_id = v_user_id;

  if not found then
    return jsonb_build_object('success', false, 'error', 'not_found');
  end if;

  select * into v_reto from public.retos where id = v_post.reto_id;

  update public.postulaciones
  set estado = 'completado', avance = 1, fecha_entrega = now()
  where id = v_post.id;

  insert into public.logros
    (estudiante_id, reto_id, titulo, empresa, habilidades)
  values
    (v_user_id, v_reto.id, v_reto.titulo,
     coalesce(v_reto.empresa_nombre, 'Empresa'), v_reto.entregables)
  on conflict (estudiante_id, reto_id) do nothing;

  return jsonb_build_object(
    'success', true,
    'message', '¡Reto completado! Logro añadido a tu currículum.');
end;
$$;

grant execute on function public.marcar_postulacion_completada(uuid) to authenticated;
