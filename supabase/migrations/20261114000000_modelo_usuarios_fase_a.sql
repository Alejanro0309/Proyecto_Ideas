-- =====================================================================
-- Fase A del modelo de datos: Usuario -> Estudiante / Empresa
-- (modelo_usuarios.md, seccion 3)
--
-- SEGURA: no toca `perfiles`, `empresas`, `retos`, las funciones ni los
-- triggers. Solo CREA las tablas nuevas y copia los datos existentes con
-- `on conflict do nothing` (se puede repetir sin duplicar).
-- =====================================================================

-- =====================================================================
-- 1. USUARIOS (clase superior)
-- =====================================================================
create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  correo text not null unique,
  telefono text
    check (telefono is null or telefono ~ '^\+?[0-9 ()-]{7,20}$'),
  tipo_cuenta text not null
    check (tipo_cuenta in ('estudiante', 'empresa', 'admin')),
  creado_en timestamptz not null default now(),
  unique (id, tipo_cuenta)      -- permite la clave compuesta de las hijas
);

-- =====================================================================
-- 2. ESTUDIANTES (hija de usuarios)
-- =====================================================================
create table if not exists public.estudiantes (
  id uuid primary key,
  tipo_cuenta text not null default 'estudiante'
    check (tipo_cuenta = 'estudiante'),
  nombres text,
  apellidos text,
  cedula text unique
    check (cedula is null or cedula ~ '^[0-9]{6,9}$'),
  carnet text unique,
  fecha_nacimiento date
    check (fecha_nacimiento is null or fecha_nacimiento >= date '1900-01-01'),
  trimestre smallint
    check (trimestre is null or trimestre between 1 and 20),
  carrera text,
  verificado boolean not null default false,
  foreign key (id, tipo_cuenta)
    references public.usuarios (id, tipo_cuenta) on delete cascade
);

-- Habilidades del estudiante (usa el catalogo que ya existe)
create table if not exists public.estudiante_habilidades (
  estudiante_id uuid not null
    references public.estudiantes(id) on delete cascade,
  habilidad_id integer not null
    references public.habilidades(id) on delete cascade,
  primary key (estudiante_id, habilidad_id)
);

create index if not exists estudiante_habilidades_hab_idx
  on public.estudiante_habilidades (habilidad_id);

-- Edad calculada (nunca se guarda)
create or replace view public.estudiantes_con_edad
with (security_invoker = true) as
select
  e.*,
  case
    when e.fecha_nacimiento is null then null
    else date_part('year', age(current_date, e.fecha_nacimiento))::integer
  end as edad
from public.estudiantes e;

-- =====================================================================
-- 3. SEGURIDAD (RLS y permisos)
-- =====================================================================
alter table public.usuarios enable row level security;
alter table public.estudiantes enable row level security;
alter table public.estudiante_habilidades enable row level security;

-- Nadie anonimo toca estas tablas; los usuarios no insertan ni borran directamente.
revoke all on public.usuarios, public.estudiantes,
              public.estudiante_habilidades from anon;
revoke insert, delete on public.usuarios, public.estudiantes from authenticated;
revoke update on public.usuarios, public.estudiantes from authenticated;

-- Cada persona edita solo ciertas columnas de su propia fila.
-- cedula, carnet y verificado NO se editan directamente: solo con funciones.
grant update (telefono) on public.usuarios to authenticated;
grant update (nombres, apellidos, fecha_nacimiento, trimestre, carrera)
  on public.estudiantes to authenticated;
grant select on public.estudiantes_con_edad to authenticated;

drop policy if exists "usuarios_ver" on public.usuarios;
create policy "usuarios_ver" on public.usuarios
  for select to authenticated
  using (id = (select auth.uid()) or public.es_admin());

drop policy if exists "usuarios_editar" on public.usuarios;
create policy "usuarios_editar" on public.usuarios
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

drop policy if exists "estudiantes_ver" on public.estudiantes;
create policy "estudiantes_ver" on public.estudiantes
  for select to authenticated
  using (id = (select auth.uid()) or public.es_admin());

drop policy if exists "estudiantes_editar" on public.estudiantes;
create policy "estudiantes_editar" on public.estudiantes
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

drop policy if exists "est_hab_ver" on public.estudiante_habilidades;
create policy "est_hab_ver" on public.estudiante_habilidades
  for select to authenticated
  using (estudiante_id = (select auth.uid()) or public.es_admin());

drop policy if exists "est_hab_insertar" on public.estudiante_habilidades;
create policy "est_hab_insertar" on public.estudiante_habilidades
  for insert to authenticated
  with check (estudiante_id = (select auth.uid()));

drop policy if exists "est_hab_borrar" on public.estudiante_habilidades;
create policy "est_hab_borrar" on public.estudiante_habilidades
  for delete to authenticated
  using (estudiante_id = (select auth.uid()));

-- =====================================================================
-- 4. COPIAR LO QUE YA EXISTE (sin duplicar)
-- =====================================================================
insert into public.usuarios (id, correo, telefono, tipo_cuenta, creado_en)
select p.id, p.correo, p.telefono, coalesce(p.tipo_cuenta, p.rol), p.creado_en
from public.perfiles p
on conflict (id) do nothing;

insert into public.estudiantes
  (id, nombres, apellidos, cedula, carnet, fecha_nacimiento, verificado)
select p.id, p.nombre, p.apellido, p.cedula, p.carnet_codigo,
       p.fecha_nacimiento::date, coalesce(p.verificado, false)
from public.perfiles p
join public.usuarios u on u.id = p.id and u.tipo_cuenta = 'estudiante'
on conflict (id) do nothing;

-- Las empresas NO se copian: la tabla `empresas` se reemplaza en la Fase B.
