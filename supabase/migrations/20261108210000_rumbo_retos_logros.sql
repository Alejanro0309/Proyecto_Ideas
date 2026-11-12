-- ============================================================================
-- RUMBO: backend de retos, logros y visibilidad del currículum.
--
-- Se crean solo las tablas que faltan para que las pestañas Panel, Retos,
-- Currículum y Perfil funcionen. `public.perfiles` ya existe y no se toca.
-- ============================================================================

-- 0. Empresas que publican retos --------------------------------------------
create table public.empresas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  correo text not null unique,
  creada_en timestamptz not null default now()
);

alter table public.empresas enable row level security;

-- Las empresas son un catálogo público: cualquier autenticado puede verlas.
create policy "Ver empresas"
  on public.empresas for select to authenticated
  using (true);

-- Solo el servidor (service role / funciones security definer) las modifica.
revoke insert, update, delete on public.empresas from authenticated;

-- 1. Retos publicados por las empresas --------------------------------------
create table public.retos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  titulo text not null,
  descripcion text,
  categoria text not null default 'Otro',
  habilidades text[] not null default '{}',
  duracion_dias integer not null default 3
    check (duracion_dias between 1 and 7),
  presupuesto_usd integer not null default 0
    check (presupuesto_usd >= 0),
  fecha_limite timestamptz not null,
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);

create index retos_categoria_idx on public.retos(categoria);
create index retos_fecha_limite_idx on public.retos(fecha_limite);

alter table public.retos enable row level security;

-- Cualquiera autenticado puede ver los retos activos (catálogo de la app).
create policy "Ver retos activos"
  on public.retos for select to authenticated
  using (activo = true);

-- Solo el servidor crea, modifica o retira retos (la app del estudiante no).
revoke insert, update, delete on public.retos from authenticated;

-- 2. Postulaciones del estudiante a un reto ----------------------------------
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

-- 3. Logros verificados (nacen cuando una postulación se completa) ----------
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

-- 4. Visibilidad del currículum público -------------------------------------
-- Una fila por estudiante; se crea sola con el perfil.
create table public.curriculum_visibilidad (
  estudiante_id uuid primary key default auth.uid()
    references public.perfiles(id) on delete cascade,
  perfil_publico boolean not null default false,
  mostrar_universidad boolean not null default true,
  mostrar_ciudad boolean not null default true,
  mostrar_portafolio boolean not null default true,
  token uuid not null default gen_random_uuid(),
  actualizado_en timestamptz not null default now()
);

alter table public.curriculum_visibilidad enable row level security;

-- El dueño controla su fila; cualquiera autenticado puede leer el token
-- (la página pública /cv/<token> no exige sesión).
create policy "Ver mi configuración"
  on public.curriculum_visibilidad for select to authenticated
  using (estudiante_id = (select auth.uid()));

create policy "Gestionar mi configuración"
  on public.curriculum_visibilidad for all to authenticated
  using (estudiante_id = (select auth.uid()))
  with check (estudiante_id = (select auth.uid()));

-- 5. La fila de visibilidad se crea con el perfil ---------------------------
create or replace function public.crear_visibilidad_nuevo_perfil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.curriculum_visibilidad (estudiante_id)
  values (new.id)
  on conflict (estudiante_id) do nothing;
  return new;
end;
$$;

create trigger crear_visibilidad_despues_de_perfil
  after insert on public.perfiles
  for each row execute function public.crear_visibilidad_nuevo_perfil();

-- 6. Generar logro al completar una postulación -----------------------------
create or replace function public.marcar_postulacion_completada(p_postulacion uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_reto public.retos%rowtype;
  v_empresa public.empresas%rowtype;
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
  select * into v_empresa from public.empresas where id = v_reto.empresa_id;

  update public.postulaciones
  set estado = 'completado', avance = 1, fecha_entrega = now()
  where id = v_post.id;

  insert into public.logros
    (estudiante_id, reto_id, titulo, empresa, habilidades)
  values
    (v_user_id, v_reto.id, v_reto.titulo,
     coalesce(v_empresa.nombre, 'Empresa'), v_reto.habilidades)
  on conflict (estudiante_id, reto_id) do nothing;

  return jsonb_build_object(
    'success', true,
    'message', '¡Reto completado! Logro añadido a tu currículum.');
end;
$$;

grant execute on function public.marcar_postulacion_completada(uuid) to authenticated;

-- 7. Semilla: empresas y retos de ejemplo con fechas relativas --------------
insert into public.empresas (nombre, correo) values
  ('Comercial Andina', 'contacto@comercialandina.test'),
  ('StartUp Lab', 'hola@startuplab.test'),
  ('Marca Viva', 'info@marcaviva.test'),
  ('Agencia Norte', 'hola@agencianorte.test'),
  ('Revista Épsilon', 'editorial@revistaepsilon.test')
on conflict (correo) do nothing;

-- Vincula los retos de muestra a las empresas recién creadas.
insert into public.retos
  (empresa_id, titulo, descripcion, categoria, habilidades, duracion_dias,
   presupuesto_usd, fecha_limite)
select e.id, v.titulo, v.descripcion, v.categoria, v.habilidades,
       v.duracion_dias, v.presupuesto_usd, v.fecha_limite
from (values
  ('Comercial Andina', 'Limpieza y análisis de ventas en Excel',
   'Organiza y analiza una hoja de ventas con tablas dinámicas.',
   'Datos', array['Excel','Tablas dinámicas']::text[], 2, 45, now() + interval '9 days'),
  ('StartUp Lab', 'Landing page de producto',
   'Diseña y maqueta una landing page con HTML y CSS.',
   'Desarrollo', array['HTML','CSS']::text[], 7, 150, now() + interval '12 days'),
  ('Marca Viva', 'Identidad visual con Canva',
   'Crea una identidad visual básica para una marca.',
   'Diseño', array['Canva','Branding']::text[], 3, 60, now() + interval '6 days'),
  ('Agencia Norte', 'Campaña de Instagram para lanzamiento',
   'Planifica y redacta una campaña de Instagram.',
   'Marketing', array['Instagram','Copywriting']::text[], 5, 90, now() + interval '8 days'),
  ('Revista Épsilon', 'Ensayo de 5 páginas sobre economía digital',
   'Redacta un ensayo breve sobre economía digital.',
   'Otro', array['Redacción','Investigación']::text[], 4, 40, now() + interval '5 days'),
  ('Comercial Andina', 'Dashboard de indicadores en Excel',
   'Construye un dashboard de indicadores con gráficos.',
   'Datos', array['Excel','Gráficos']::text[], 6, 120, now() + interval '4 days')
) as v(empresa, titulo, descripcion, categoria, habilidades, duracion_dias,
       presupuesto_usd, fecha_limite)
join public.empresas e on e.nombre = v.empresa
where not exists (
  select 1 from public.retos r where r.titulo = v.titulo
);
