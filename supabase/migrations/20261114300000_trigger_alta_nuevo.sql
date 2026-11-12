-- =====================================================================
-- Reescribir el trigger de alta para que escriba en las tablas NUEVAS
-- (usuarios + estudiantes / empresas_nueva) en lugar de `perfiles`.
-- =====================================================================

create or replace function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
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
  v_tipo_empresa := nullif(trim(coalesce(v_meta->>'empresa_tipo', v_meta->>'empresa_tipo', '')), '');

  -- Fecha de nacimiento: viene como 'AAAA-MM-DD' o como milisegundos.
  begin
    v_fecha_nacimiento := (v_meta->>'fecha_nacimiento')::date;
  exception when others then
    v_fecha_nacimiento := null;
  end;

  -- Fila de usuario (clase superior).
  insert into public.usuarios (id, correo, telefono, tipo_cuenta)
  values (new.id, new.email, v_telefono,
          case when v_empresa then 'empresa' else 'estudiante' end)
  on conflict (id) do update
  set correo = new.email,
      telefono = coalesce(public.usuarios.telefono, excluded.telefono);

  if v_empresa then
    v_nombre := nullif(trim(coalesce(v_meta->>'empresa_nombre', '')), '');
    if v_nombre is null or length(v_nombre) < 2 then
      raise exception 'EMPRESA_NOMBRE_INVALIDO';
    end if;

    insert into public.empresas_nueva (id, tipo_cuenta, nombre, tipo_empresa)
    values (new.id, 'empresa', v_nombre, v_tipo_empresa)
    on conflict (id) do update
    set nombre = coalesce(public.empresas_nueva.nombre, excluded.nombre),
        tipo_empresa = coalesce(public.empresas_nueva.tipo_empresa, excluded.tipo_empresa);
  else
    v_nombre := nullif(trim(coalesce(v_meta->>'nombre', '')), '');
    v_apellido := nullif(trim(coalesce(v_meta->>'apellido', '')), '');

    insert into public.estudiantes
      (id, tipo_cuenta, nombres, apellidos, fecha_nacimiento)
    values (new.id, 'estudiante', v_nombre, v_apellido, v_fecha_nacimiento)
    on conflict (id) do update
    set nombres = coalesce(public.estudiantes.nombres, excluded.nombres),
        apellidos = coalesce(public.estudiantes.apellidos, excluded.apellidos),
        fecha_nacimiento =
          coalesce(public.estudiantes.fecha_nacimiento, excluded.fecha_nacimiento);
  end if;

  return new;
end;
$function$;
