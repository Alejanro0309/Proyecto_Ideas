-- =====================================================================
-- registro_empresas.md (sección 3)
-- 1. PERFILES: columnas de empresa y rol 'empresa'
-- =====================================================================
alter table public.perfiles
  add column if not exists telefono text,
  add column if not exists empresa_tipo text,
  add column if not exists tipo_empresa text,
  add column if not exists fecha_nacimiento date,
  add column if not exists tipo_cuenta text;

alter table public.perfiles drop constraint if exists perfiles_rol_check;
alter table public.perfiles
  add constraint perfiles_rol_check
  check (rol in ('estudiante', 'empresa', 'admin'));

alter table public.perfiles drop constraint if exists perfiles_telefono_formato;
alter table public.perfiles
  add constraint perfiles_telefono_formato
  check (telefono is null or telefono ~ '^\+?[0-9 ()-]{7,20}$');

-- =====================================================================
-- 2. REGISTRO: las empresas pueden usar cualquier correo;
--    los estudiantes, solo @correo.unimet.edu.ve
-- =====================================================================
create or replace function public.validar_dominio_unimet()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tipo text := coalesce(new.raw_user_meta_data->>'tipo_cuenta', 'estudiante');
begin
  if v_tipo = 'empresa' then
    return new;
  end if;

  if lower(coalesce(new.email, '')) not like '%@correo.unimet.edu.ve' then
    raise exception 'Solo se permiten correos @correo.unimet.edu.ve para estudiantes';
  end if;

  return new;
end;
$$;

-- El trigger de validación va ANTES de insertar (BEFORE INSERT).
drop trigger if exists validar_dominio_antes_de_registro on auth.users;
create trigger validar_dominio_antes_de_registro
  before insert on auth.users
  for each row execute function public.validar_dominio_unimet();

-- =====================================================================
-- 3. PERFIL AUTOMÁTICO AL REGISTRARSE (estudiante o empresa)
--    El rol sale SOLO de aquí: nunca puede llegar 'admin' desde la app.
--    Empresa: lee `empresa_nombre` (como lo envía la app) y
--    `empresa_tipo`. Estudiante: `nombre` y `apellido`.
-- =====================================================================
create or replace function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_empresa boolean := coalesce((v_meta->>'tipo_cuenta') = 'empresa', false);
  v_nombre text;
  v_apellido text;
  v_fecha_nacimiento date;
  v_tipo_empresa text;
  v_telefono text;
begin
  v_telefono := nullif(trim(coalesce(v_meta->>'telefono', '')), '');
  v_tipo_empresa := nullif(trim(coalesce(v_meta->>'empresa_tipo', '')), '');

  -- Fecha de nacimiento: viene como 'AAAA-MM-DD' o como milisegundos.
  begin
    v_fecha_nacimiento :=
      (v_meta->>'fecha_nacimiento')::date;
  exception when others then
    v_fecha_nacimiento := null;
  end;

  if v_empresa then
    v_nombre := nullif(trim(coalesce(v_meta->>'empresa_nombre', '')), '');
    if v_nombre is null or length(v_nombre) < 2 then
      raise exception 'EMPRESA_NOMBRE_INVALIDO';
    end if;

    insert into public.perfiles
      (id, correo, nombre, rol, tipo_cuenta, tipo_empresa, telefono)
    values
      (new.id, new.email, v_nombre, 'empresa', 'empresa',
       v_tipo_empresa, v_telefono)
    on conflict (id) do update
    set
      nombre = coalesce(public.perfiles.nombre, excluded.nombre),
      rol = 'empresa',
      tipo_cuenta = 'empresa',
      tipo_empresa =
        coalesce(public.perfiles.tipo_empresa, excluded.tipo_empresa),
      telefono = coalesce(public.perfiles.telefono, excluded.telefono);
  else
    v_nombre := nullif(trim(coalesce(v_meta->>'nombre', '')), '');
    v_apellido := nullif(trim(coalesce(v_meta->>'apellido', '')), '');

    insert into public.perfiles
      (id, correo, nombre, apellido, fecha_nacimiento, rol, tipo_cuenta)
    values
      (new.id, new.email, v_nombre, v_apellido, v_fecha_nacimiento,
       'estudiante', 'estudiante')
    on conflict (id) do update
    set
      nombre = coalesce(public.perfiles.nombre, excluded.nombre),
      apellido = coalesce(public.perfiles.apellido, excluded.apellido),
      fecha_nacimiento =
        coalesce(public.perfiles.fecha_nacimiento, excluded.fecha_nacimiento);
  end if;

  return new;
end;
$$;

-- =====================================================================
-- 4. LAS EMPRESAS NO PUEDEN ACEPTAR RETOS (solo estudiantes)
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
    where r.id = p_reto_id
      and r.estado = 'publicado'
      and r.fecha_limite >= current_date
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

-- =====================================================================
-- 5. COMPROBACIÓN: los dos triggers deben existir
-- =====================================================================
-- select tgname from pg_trigger
--   where tgrelid = 'auth.users'::regclass and not tgisinternal;
-- debe listar: validar_dominio_antes_de_registro y
--              crear_perfil_despues_de_registro
