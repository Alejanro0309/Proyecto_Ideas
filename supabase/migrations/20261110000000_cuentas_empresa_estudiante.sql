-- =====================================================================
-- RUMBO: cuentas de empresa y datos del estudiante.
--
-- 1. `perfiles.rol` ya se añadió en la migración de explorar retos; aquí se
--    asegura y se añaden `apellido`, `fecha_nacimiento` y `tipo_cuenta`.
-- 2. El trigger de registro guarda nombre, apellido y fecha de nacimiento.
-- 3. Se quita el bloqueo de correos que no sean @correo.unimet.edu.ve,
--    para que las empresas puedan registrarse (el rol las distingue).
-- =====================================================================

-- 1. Columnas nuevas en `perfiles` (si no existen).
alter table public.perfiles
  add column if not exists rol text not null default 'estudiante',
  add column if not exists apellido text,
  add column if not exists fecha_nacimiento date,
  add column if not exists tipo_cuenta text
    check (tipo_cuenta in ('estudiante', 'empresa')),
  add column if not exists tipo_empresa text,
  add column if not exists telefono text;

-- El constraint viejo solo permitía 'estudiante' y 'admin'. Se reemplaza
-- para admitir también 'empresa'. Sin esto, registrar una empresa falla.
alter table public.perfiles
  drop constraint if exists perfiles_rol_check;

alter table public.perfiles
  add constraint perfiles_rol_check
  check (rol in ('estudiante', 'empresa', 'admin'));

-- Índice para filtrar por rol.
create index if not exists perfiles_rol_idx on public.perfiles(rol);

-- 2. Trigger de registro: guarda nombre, apellido, fecha de nacimiento y rol.
create or replace function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_nombre text;
  v_apellido text;
  v_fecha_nacimiento date;
  v_tipo text;
  v_tipo_empresa text;
  v_telefono text;
  v_full_name text;
begin
  v_nombre := new.raw_user_meta_data->>'nombre';
  v_apellido := new.raw_user_meta_data->>'apellido';
  v_tipo := new.raw_user_meta_data->>'tipo_cuenta';
  v_tipo_empresa := new.raw_user_meta_data->>'tipo_empresa';
  v_telefono := new.raw_user_meta_data->>'telefono';

  -- Fecha de nacimiento: viene como 'AAAA-MM-DD' o como milisegundos.
  begin
    v_fecha_nacimiento :=
      (new.raw_user_meta_data->>'fecha_nacimiento')::date;
  exception when others then
    v_fecha_nacimiento := null;
  end;

  -- Si no llegó nombre, se separa del full_name.
  v_full_name := new.raw_user_meta_data->>'full_name';
  if v_nombre is null and v_full_name is not null then
    v_nombre := split_part(v_full_name, ' ', 1);
    v_apellido := nullif(substr(v_full_name, length(v_nombre) + 2), '');
  end if;

  insert into public.perfiles
    (id, correo, nombre, apellido, fecha_nacimiento, rol, tipo_cuenta,
     tipo_empresa, telefono)
  values
    (new.id, new.email,
     v_nombre,
     coalesce(v_apellido, public.perfiles.apellido),
     v_fecha_nacimiento,
     case when v_tipo = 'empresa' then 'empresa' else 'estudiante' end,
     v_tipo,
     v_tipo_empresa,
     v_telefono)
  on conflict (id) do update
  set
    correo = excluded.correo,
    nombre = coalesce(public.perfiles.nombre, excluded.nombre),
    apellido = coalesce(public.perfiles.apellido, excluded.apellido),
    fecha_nacimiento =
      coalesce(public.perfiles.fecha_nacimiento, excluded.fecha_nacimiento),
    rol = case when excluded.tipo_cuenta = 'empresa'
               then 'empresa'
               else public.perfiles.rol end,
    tipo_cuenta = coalesce(public.perfiles.tipo_cuenta, excluded.tipo_cuenta),
    tipo_empresa =
      coalesce(public.perfiles.tipo_empresa, excluded.tipo_empresa),
    telefono = coalesce(public.perfiles.telefono, excluded.telefono);

  return new;
end;
$$;

-- 3. El estudiante sí puede guardar su fecha de nacimiento.
revoke update on public.perfiles from authenticated;
grant update (nombre, apellido, fecha_nacimiento)
  on public.perfiles to authenticated;

-- 4. Quitar el bloqueo del dominio @correo.unimet.edu.ve.
--    Ahora estudiantes y empresas entran; el rol los distingue.
drop trigger if exists validar_dominio_antes_de_registro on auth.users;
drop function if exists public.validar_dominio_unimet();

-- 5. Función para guardar el perfil completo del estudiante (RLS-safe).
create or replace function public.actualizar_perfil(
  p_nombre text default null,
  p_apellido text default null,
  p_fecha_nacimiento date default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('success', false, 'error', 'unauthorized');
  end if;

  update public.perfiles
  set
    nombre = coalesce(p_nombre, nombre),
    apellido = coalesce(p_apellido, apellido),
    fecha_nacimiento = coalesce(p_fecha_nacimiento, fecha_nacimiento)
  where id = v_user_id;

  return jsonb_build_object('success', true, 'message', 'Perfil actualizado.');
end;
$$;

grant execute on function public.actualizar_perfil(text, text, date)
  to authenticated;

-- 6. Datos de ejemplo: una empresa para probar el rol.
-- Solo funciona si existe un usuario de autenticación con ese correo. Como
-- `perfiles.id` referencia `auth.users(id)`, no se puede inventar el id; el
-- trigger `crear_empresa_nuevo_perfil` crea la empresa real al registrarse.
