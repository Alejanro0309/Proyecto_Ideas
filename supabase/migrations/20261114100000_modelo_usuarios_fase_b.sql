-- =====================================================================
-- Fase B (parcial): conectar los campos a las tablas nuevas
-- =====================================================================

-- 1. EMPRESAS NUEVA (hija de usuarios)
create table if not exists public.empresas_nueva (
  id uuid primary key,
  tipo_cuenta text not null default 'empresa'
    check (tipo_cuenta = 'empresa'),
  tipo_empresa text,
  nombre text,
  logo text,
  foreign key (id, tipo_cuenta)
    references public.usuarios (id, tipo_cuenta) on delete cascade
);

-- 2. RENOMBRAR LAS TABLAS VIEJAS (idempotente)
do $$
begin
  if exists (select 1 from information_schema.tables
             where table_schema='public' and table_name='empresas')
     and not exists (select 1 from information_schema.tables
             where table_schema='public' and table_name='empresas_antigua') then
    alter table public.empresas rename to empresas_antigua;
  end if;

  if exists (select 1 from information_schema.tables
             where table_schema='public' and table_name='perfiles')
     and not exists (select 1 from information_schema.tables
             where table_schema='public' and table_name='perfiles_antigua') then
    alter table public.perfiles rename to perfiles_antigua;
  end if;
end $$;

-- 3. VISTA `perfiles` DE SOLO LECTURA (compatibilidad)
create or replace view public.perfiles as
select
  u.id,
  u.correo,
  coalesce(e.nombres, em.nombre) as nombre,
  e.apellidos,
  e.carnet as carnet_codigo,
  coalesce(e.verificado, false) as verificado,
  u.creado_en,
  u.tipo_cuenta as rol,
  e.cedula,
  e.fecha_nacimiento,
  u.tipo_cuenta,
  em.tipo_empresa,
  u.telefono,
  em.tipo_empresa as empresa_tipo
from public.usuarios u
left join public.estudiantes e on e.id = u.id
left join public.empresas_nueva em on em.id = u.id;

-- 4. REESCRIBIR FUNCIONES DE ESCRITURA (mismas firmas)

-- 4.1 actualizar_perfil(text, text, date) returns jsonb
create or replace function public.actualizar_perfil(
  p_nombre text default null,
  p_apellido text default null,
  p_fecha_nacimiento date default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('success', false, 'error', 'unauthorized');
  end if;

  update public.estudiantes
  set nombre = coalesce(p_nombre, nombres),
      apellidos = coalesce(p_apellido, apellidos),
      fecha_nacimiento = coalesce(p_fecha_nacimiento, fecha_nacimiento)
  where id = v_user_id;

  return jsonb_build_object('success', true, 'message', 'Perfil actualizado.');
end $$;

-- 4.2 guardar_datos_carnet(text, text, text) returns void
create or replace function public.guardar_datos_carnet(
  p_cedula text,
  p_nombre text,
  p_carnet text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_cedula text := regexp_replace(coalesce(p_cedula, ''), '\D', '', 'g');
  v_carnet text := nullif(regexp_replace(coalesce(p_carnet, ''), '\D', '', 'g'), '');
  v_constraint text;
begin
  if auth.uid() is null then raise exception 'NO_AUTENTICADO'; end if;
  if v_cedula !~ '^[0-9]{6,9}$' then raise exception 'CEDULA_INVALIDA'; end if;
  if length(trim(coalesce(p_nombre, ''))) < 3 then raise exception 'NOMBRE_INVALIDO'; end if;

  update public.estudiantes
  set cedula = v_cedula,
      nombres = trim(p_nombre),
      carnet = v_carnet
  where id = auth.uid();

exception when unique_violation then
  get stacked diagnostics v_constraint = constraint_name;
  if v_constraint = 'estudiantes_cedula_key' then
    raise exception 'CEDULA_DUPLICADA';
  else
    raise exception 'CARNET_DUPLICADO';
  end if;
end $$;

-- 4.3 actualizar_perfil_empresa(text, text, text) returns void
create or replace function public.actualizar_perfil_empresa(
  p_nombre text,
  p_tipo text,
  p_telefono text
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  update public.usuarios
    set telefono = coalesce(p_telefono, telefono)
    where id = v_uid;

  update public.empresas_nueva
    set nombre = coalesce(p_nombre, nombre),
        tipo_empresa = coalesce(p_tipo, tipo_empresa)
    where id = v_uid;

  insert into public.empresas_nueva (id, tipo_cuenta, nombre, tipo_empresa)
  select v_uid, 'empresa', p_nombre, p_tipo
  where not exists (select 1 from public.empresas_nueva where id = v_uid)
    and p_nombre is not null;
end $$;

-- 5. COPIAR LAS EMPRESAS REALES DE `perfiles_antigua` A LAS TABLAS NUEVAS
insert into public.empresas_nueva (id, tipo_cuenta, nombre, tipo_empresa, logo)
select p.id, 'empresa', p.nombre, coalesce(p.tipo_empresa, p.empresa_tipo), null
from public.perfiles_antigua p
where p.rol = 'empresa' or p.tipo_cuenta = 'empresa'
on conflict (id) do nothing;
