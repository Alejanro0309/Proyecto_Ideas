-- Actualización del trigger para guardar nombre y apellido desde auth.users
create or replace function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_nombre text;
  v_apellido text;
  v_full_name text;
begin
  -- Extraer del raw_user_meta_data si existe
  v_nombre := new.raw_user_meta_data->>'nombre';
  v_apellido := new.raw_user_meta_data->>'apellido';
  v_full_name := new.raw_user_meta_data->>'full_name';

  if v_nombre is null and v_full_name is not null then
    v_nombre := split_part(v_full_name, ' ', 1);
    v_apellido := nullif(substr(v_full_name, length(v_nombre) + 2), '');
  end if;

  insert into public.perfiles (id, correo, nombre, apellido)
  values (new.id, new.email, v_nombre, v_apellido)
  on conflict (id) do update
  set
    correo = excluded.correo,
    nombre = coalesce(public.perfiles.nombre, excluded.nombre),
    apellido = coalesce(public.perfiles.apellido, excluded.apellido);

  return new;
end;
$$;

